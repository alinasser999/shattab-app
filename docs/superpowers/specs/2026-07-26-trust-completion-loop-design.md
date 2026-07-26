# Trust & Completion Loop — Design

**Date:** 2026-07-26
**Status:** Approved (Phase 1)
**Slice:** 1 of the post-audit feature roadmap

## Problem

Two defects make the app's trust signals meaningless today.

**Reviews measure hiring, not work.** The `reviews` insert policy (migration 0006)
requires only that a quote reached `status = 'accepted'`, and `accept_quote()`
(migration 0009) sets `briefs.hired_at` at that same moment. A homeowner can post
a five-star review the second they hire, before any work happens. There is no
state representing "the job is done" — `hired_at` is where the recorded lifecycle
ends.

**`projects_completed` is never written.** It is declared `int not null default 0`
in migration 0003 and no trigger, RPC, or client code ever increments it. Every
"مشروع مكتمل" figure in the app is permanently 0 unless someone edits the row by
hand. It is the same class of defect as the `response_rate` column removed during
the audit pass: a constant presented as a measurement.

Without a completion state there is no honest review, no honest project count,
and no moment at which to ask for either.

## Goals

1. Represent job completion as real state.
2. Allow reviews only after completion.
3. Make `projects_completed` a derived, trustworthy number.
4. Prompt the homeowner to review at the moment completion is confirmed.

## Non-goals

- Push notifications. No FCM in this slice; there are no store accounts yet and
  the events must exist before anything can carry them.
- The in-app notification center. Designed as Phase 2 on top of these events.
- Payments, escrow, or disputes.
- Changing the quote lifecycle itself.

## State model

```
quote accepted ──→ briefs.hired_at            (exists, set by accept_quote)
       │
       ├─ contractor: "خلصت الشغل" ──→ briefs.completion_requested_at   (new)
       │
       └─ homeowner:  "تم التنفيذ"  ──→ briefs.completed_at             (new)
                                          ├─→ review prompt unlocks
                                          └─→ projects_completed += 1
```

**Completion requires the payer's confirmation.** The contractor can signal that
work is finished, but that signal is only a nudge: it sets
`completion_requested_at` and proves nothing. Only the homeowner sets
`completed_at`.

This choice rejects two alternatives:

- *Contractor marks complete unilaterally.* Lets the supply side self-certify the
  exact fact that unlocks its own reviews and public project count. The incentive
  is wrong.
- *Auto-complete after N days of homeowner silence.* Converts homeowner
  inattention into a completed job, which then mints a review invitation and a
  public counter increment for work nobody confirmed happened.

The accepted cost: a homeowner who never returns leaves the brief hired but never
completed, so the contractor gets no review and no count. That is the correct
failure direction — it under-counts rather than inventing completions. Phase 2's
notification center is what reduces how often it happens.

## Changes

### Migration 0019

1. `alter table briefs add column completion_requested_at timestamptz`,
   `completed_at timestamptz`.
2. `request_completion(p_brief_id uuid)` — security definer. Authorizes the caller
   as the contractor with the `accepted` quote on that brief. Requires
   `hired_at is not null`. Sets `completion_requested_at = now()`. Idempotent.
3. `confirm_completion(p_brief_id uuid)` — security definer. Authorizes the caller
   as the brief's homeowner. Requires `hired_at is not null`. Sets
   `completed_at = now()`. Idempotent: a second call does not change the timestamp
   and does not double-count.
4. Replace the `reviews_homeowner_insert` policy so it additionally requires
   `briefs.completed_at is not null`.
5. Trigger on `briefs`: when `completed_at` transitions from null to non-null,
   increment `projects_completed` on the contractor holding the accepted quote.
   Guarded on the null-to-non-null transition specifically, so an unrelated update
   cannot double-increment.

Direct `update briefs set completed_at = ...` from the client stays blocked by
existing RLS; both transitions go through the RPCs, which own the authorization
rules.

### Domain

`Brief` gains `completionRequestedAt` and `completedAt` (nullable `DateTime`),
plus a derived lifecycle stage so the UI branches on one value rather than on a
combination of three timestamps:

```
open → hired → completionRequested → completed
```

### Repository & providers

`BriefsRepository.requestCompletion(briefId)` and `.confirmCompletion(briefId)`
call the RPCs and invalidate the affected providers.

### UI

- **Contractor**, on a brief where their quote is accepted and work is not yet
  confirmed: a "خلصت الشغل" action. After it is sent, the state reads as awaiting
  the homeowner's confirmation.
- **Homeowner**, on a hired brief: a "تم التنفيذ" confirm action, emphasised when
  the contractor has already requested it.
- **On confirmation:** the existing `write_review_sheet` opens immediately. This is
  the highest-intent moment for a review, and it is the reason the prompt is worth
  building at all.
- The review entry point elsewhere in `brief_detail_screen` becomes visible only
  once `completed_at` is set, matching the new RLS. Otherwise the button exists but
  the insert fails.

## Error handling

- RPCs raise `not_authorized`, `not_hired`, `brief_not_found`. Mapped to Arabic
  copy through the existing `ErrorMapper`.
- Both RPCs are idempotent, so a double tap or a retry after a dropped connection
  cannot double-count `projects_completed` or move a timestamp.
- If the review sheet fails or the homeowner dismisses it, completion still stands.
  Completion and reviewing are independent; the review remains available from the
  brief afterwards.

## Testing

- Domain: lifecycle stage derivation across every timestamp combination, including
  the contradictory `completed_at` set without `hired_at`.
- Domain: `Brief` JSON round-trip with the new nullable fields, including rows
  written before this migration where both are absent.
- The trigger and RLS changes are exercised against the database, not in the
  Flutter test suite, which has no Postgres.

## Rollout

Migration 0019 must be applied before the client ships, because the client calls
RPCs that would not otherwise exist. Unlike migration 0018 (indexes only, safe at
any time), this one is a hard prerequisite.

Existing hired-but-not-completed briefs simply have both new columns null and
appear as "hired", which is accurate. No backfill: there is no historical record
of which past jobs were actually finished, and inventing one would recreate the
exact problem this slice fixes.
