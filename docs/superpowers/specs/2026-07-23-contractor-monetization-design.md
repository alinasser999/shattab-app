# Contractor Monetization — Design Spec

Date: 2026-07-23
Status: Approved direction, pending user review of spec
App: Shattab (شطب) — Egyptian contractor marketplace, Flutter + Supabase + Riverpod

---

## 1. Goal

Turn the contractor side into revenue via three separate, mutually reinforcing
products, without killing marketplace liquidity:

- **Verified** — trust signal (homeowner-facing), free and earned.
- **Pro** — growth subscription (contractor-facing ROI), recurring revenue.
- **Sponsored** — paid top placement, transactional add-on.

Guiding principle: **Verified ≠ Pro ≠ Sponsored.** Each pulls a different lever
(trust / volume / visibility). Bundling them dilutes all three. Verified is the
universal on-ramp: free, and required before a contractor may spend on placement.

---

## 2. What already exists (migration `0013_monetization.sql`)

- `contractor_profiles`: `plan` (free|pro), `plan_expires_at`, `sponsored_until`,
  `boost_until`, `verified` bool.
- `payments` audit table (Paymob; `purpose` in pro|sponsored|boost; status
  pending|paid|failed). RLS: contractor reads own; only service_role writes.
- `tg_block_selfupgrade` trigger — blocks any non-service_role from writing
  billing columns (`plan`, `plan_expires_at`, `sponsored_until`, `boost_until`,
  `verified`). Keep.
- **Hard lead-gate RLS** on `quotes` insert: only active-Pro may quote. **This
  changes** (see §5).
- `paywall_sheet.dart`: presentational stub, button inert → "coming soon".
- `verified` bool: **not rendered anywhere**, no earn-flow. Both to be built.

---

## 3. Locked decisions

| Decision | Choice |
|---|---|
| Free-tier model | **Freemium quota** — free contractors get 3 leads/month |
| Verified | **Free, earned** via document review |
| Pro price | **299 EGP/mo** (annual 2990/yr ≈ 2 months free) |
| Sponsored eligibility | **Any Verified contractor** (Pro not required) |
| Sponsored pricing | **Flat per week / per job** |

---

## 4. Tiers

| Capability | Free | Pro — 299 EGP/mo |
|---|---|---|
| Send quotes | 3 leads / calendar month | Unlimited |
| Direct-request inbox | Read only | Reply / quote |
| Discovery ranking | Normal | Priority |
| Portfolio slots | ~5 | Unlimited |
| "Homeowner saw your quote" | — | ✓ |
| Eligible to be Verified | ✓ | ✓ |
| Eligible to buy Sponsored | ✓ (if Verified) | ✓ (if Verified) |

Trial: first month free **or** first 3 quotes free (pick one at build; default
first-month-free) to prove ROI before charging.

---

## 5. Freemium quota — the one real RLS rewrite

Current lead-gate is binary (Pro-or-nothing). Replace with a monthly count so
free contractors can quote up to the limit; Pro bypasses it.

Approach:
- Count the contractor's `quotes` rows created in the current calendar month.
- Insert allowed if: `plan='pro' AND plan_expires_at > now()` **OR** monthly
  count `< 3`.
- Enforce in RLS `with check` (source of truth) using a `count(*)` subquery over
  `quotes` where `contractor_id = auth.uid()` and `created_at` in current month.
- Client mirrors the remaining count for UX (blurred/locked leads, "X left this
  month"), but the RLS is authoritative.

Quota number (3) is a tunable constant; document it in one place.

---

## 6. Verified — trust track (build first; no payment dependency)

**Flow**
1. Contractor taps "وثّق حسابك".
2. Uploads: national ID front + back, selfie holding ID. Optional: trade license
   / tax card / proof of past work.
3. Insert `verification_requests` row (status `pending`); files in a private
   storage bucket.
4. **Admin reviews** (Supabase dashboard or a simple internal review screen).
5. Approve → service-role sets `contractor_profiles.verified = true` (guard
   already blocks self-set). Reject → status `rejected` + reason; contractor sees
   reason and can resubmit.

**Schema (new)**
- `verification_requests(id, contractor_id fk profiles, status pending|approved|rejected,
  reason text, id_front_path, id_back_path, selfie_path, extra_paths text[],
  created_at, reviewed_at, reviewed_by)`.
- RLS: contractor reads/inserts own pending; only service_role updates status.
- Storage bucket `verification-docs` (private; contractor writes own prefix,
  service_role/admin reads).

**Display (new)**
- Render `verified` badge in `contractor_card.dart` (currently absent), on
  contractor profile, and on quote rows.
- Unverified shown "غير موثّق".
- Discovery filter "موثّق فقط".

**Want-drivers**
- Loss aversion: unverified become invisible under the filter.
- Completion nudge on contractor home ("حسابك ٦٠٪ — وثّق نفسك").
- Later, once data exists: social proof ("الموثّقون بيردّوا عليهم أكتر").

---

## 7. Pro — growth track (Paymob)

**Triggers to show paywall**
- Free quota hit; tap a locked/blurred matched lead; onboarding upsell; profile
  "Go Pro" entry.

**Flow**
1. Paywall sheet → plan select (monthly / annual).
2. Call `create-payment` edge fn → Paymob checkout URL → open in WebView.
3. Paymob webhook → `payment-webhook` edge fn (service_role) verifies signature →
   insert `payments` row `paid` (idempotent on `provider_ref`) → set
   `plan='pro'`, `plan_expires_at = now() + interval`.
4. Renewal reminder before expiry; on expiry, contractor drops to free quota
   (no destructive change — just the columns lapse).

**New**
- Edge fns: `create-payment`, `payment-webhook`.
- Plan-select UI + Paymob CheckoutWebview; replace the inert paywall button body.

**Reuse:** `payments`, guard trigger, `plan`/`plan_expires_at`.

**Want-drivers**
- Show missed money: blurred count of matched leads with EGP value ("١٢ شغل
  اتطابق معاك الأسبوع ده" + lock).
- ROI anchor: "عرض واحد ممكن يجيب ٢٠٬٠٠٠ ج، البرو ٢٩٩/شهر".
- Trial removes first-purchase risk.

---

## 8. Sponsored — placement track (any Verified)

Two products the existing columns already support:

- **Featured** (`sponsored_until`) — top of Discover contractor list for the
  homeowner's city/specialty. **Labeled "مموّل".** Multiple sponsored in one
  segment **rotate** for fair impressions; cap slots per segment (e.g. 3). Flat
  **~199 EGP/week** (tunable).
- **Quote-boost** (`boost_until`) — pins the contractor's quote to the top of a
  homeowner's received-quotes list on jobs they quote. Flat **~49 EGP/job**
  (tunable).

**Eligibility:** must be **Verified** (any plan). Prevents promoting unvetted
contractors — brand/scam protection. Not Pro-gated.

**Flow:** same Paymob path as Pro but `purpose='sponsored'|'boost'`; webhook sets
`sponsored_until` / `boost_until`.

**Honesty:** sponsored placement is always visibly labeled so organic ranking
keeps meaning. No auction at launch (YAGNI) — flat rate only.

---

## 9. Phasing (build order)

1. **Verified** — table, bucket, upload UI, admin review, badge + filter. No
   payment dependency; ships trust and generates the eligibility gate + data.
2. **Freemium quota** — RLS rewrite (§5), quota counter, paywall triggers/locked
   leads UI.
3. **Pro via Paymob** — 2 edge fns, plan-select UI, checkout WebView, webhook.
4. **Sponsored** — Featured + Quote-boost purchase + rotation/label/pin render.

Add-on tuning (auction, dynamic caps) explicitly deferred.

---

## 10. Open defaults (chosen, tunable — flagged, not blocking)

- Free quota = **3 / calendar month**.
- Pro trial = **first month free**.
- Featured = **199 EGP/wk**, cap **3 slots/segment**, rotation on impression.
- Quote-boost = **49 EGP/job**.
- Portfolio free cap = **5**.

---

## 11. Non-goals (this spec)

- In-app chat, push notifications (separate track).
- Homeowner-side paid features.
- Auction-based placement.
- Automated (non-manual) verification.
