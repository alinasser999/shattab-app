# Phase 2 — Trust Architecture

Completed 2026-07-27 on `feat/bottom-nav-redesign`.

The goal was not features. It was to make a homeowner confident enough to choose
a professional, by making every claim on screen either checkable or absent.

---

## 1. Audit

| # | Finding | Trust cost |
|---|---|---|
| A1 | Trust signals lived in four unrelated widgets (`_StatsRow`, `_MicroStats`, `_RatingPill`, `TierBadge`), each deciding independently what to show and when to hide it | Adding a metric meant editing four files, and the four could disagree |
| A2 | `_MicroStats` on the discover card printed **"0 مشروع"** while `_StatsRow` on the profile deliberately hid zeros | The card damaged every new professional that the profile was careful to protect |
| A3 | **Every review in the database is already verified by construction** — RLS (0006) requires an accepted quote, and 0019 moved the reviewable moment to homeowner-confirmed completion — and the UI never said so | The strongest unclaimed trust asset in the product |
| A4 | Reviews had no distribution, no sort, no filter | A 4.6 nobody can break down is a marketing number |
| A5 | `_ReviewRow` drew five hand-built stars while `_RatingPill` had already settled on one star plus the number | Two rating languages inside one flow |
| A6 | Project tiles showed title + category only; `yearCompleted`, `location`, `apartmentType` and photo count already existed on the model and were dropped | The portfolio read as a mood board, not a work record |
| A7 | `project_detail_screen` used an all-caps wide-tracked eyebrow (`toUpperCase()` on Arabic, a no-op) and skipped `sizedImageUrl` on three images | Inconsistent typography, full-resolution image egress |
| A8 | Response rate / response time / completion rate did not exist as data. `contractor_profiles.response_rate` is `int not null default 100` and has never been written to | A constant wearing a percentage sign |

---

## 2. Architecture

```
ContractorListing ──► TrustProfile ──┬─► verification : VerificationLevel
                                     ├─► tier         : ContractorTier
                                     ├─► metrics[]    : TrustSignal    (tiles)
                                     └─► highlight?   : TrustHighlight (≤ 1 badge)
```

Three rules the whole phase rests on:

1. **A signal with no measured value produces no UI.** Not a zero, not a dash,
   not a placeholder. Absence is rendered as absence.
2. **One derivation, every surface.** The discover card, the profile header and
   the profile body all read the same `TrustProfile`, so A2 cannot recur.
3. **At most one distinction badge.** Stacking "موصى به" beside "الأعلى تقييماً"
   beside a level chip teaches the eye that badges here are wallpaper.

### The seam for unmeasured metrics

`avgResponseMinutes`, `responseRate`, `completionRate` and `businessVerified`
are declared end to end — enum case, model field, tolerant `fromJson` read,
`TrustProfile` branch, tile rendering — and are null today because no column
backs them. Connecting one later is **two edits in lockstep**:

1. add the column in a migration,
2. name it in `DiscoveryRepository._joinedColumns`.

No widget changes. PostgREST 400s on a column that does not exist, which is why
the select list is the second half of the pair rather than something to add
speculatively now.

The app deliberately does **not** read `contractor_profiles.response_rate`. It
reads `measured_response_rate`, a name reserved for a column that will hold a
real measurement.

---

## 3. Components

### Created

| Component | File | Why it increases trust |
|---|---|---|
| `TrustProfile` / `TrustSignal` / `VerificationLevel` / `TrustHighlight` | `features/discovery/domain/trust_signals.dart` | One vocabulary. A signal cannot contradict itself across screens |
| `BatshTrustStrip` (+ `TrustCredentials`) | `core/widgets/trust_strip.dart` | Renders the derived signals at two densities; absorbs two divergent widgets |
| `ReviewStats` / `applyReviewView` | `features/reviews/domain/review_stats.dart` | Turns an average into a breakdown a reader can check |
| `RatingSummary` | `features/reviews/presentation/widgets/rating_summary.dart` | Distribution + the verified-review guarantee, stated once |
| `ReviewCard` | `features/reviews/presentation/widgets/review_card.dart` | Verified chip, one rating language, project and photo slots wired |
| `ProjectFact` / `ProjectMetaLine` / `ProjectMetaBlock` | `features/portfolio/presentation/widgets/project_meta.dart` | Same evidence on the tile and the detail screen, from one function |

### Deleted (folded into the above)

`_StatsRow`, `_StatCard`, `_MicroStats`, `_ReviewRow`, `_MetaItem`.

### Reused rather than rebuilt

`BatshBadge`, `BatshChip`, `BatshEmptyState`, `BatshButton`, `BatshSheet`,
`BatshPhotoViewer`, `TierBadge`, `sizedImageUrl`, `formatRelativeTime`, and the
whole token layer. No new dependency.

### Rejected

- **A composite "trust score".** An unauditable number is the opposite of the
  thing this phase exists to build.
- **A dedicated verification widget.** The existing badge row already carries it.
- **A second explainer dialog.** The verification rungs were added to the tier
  explainer instead: a reader tapping a badge asks what *these marks* mean.
- **Any response, completion or business-verification figure rendered from a
  default.** Declared, wired, and left silent until measured.

---

## 4. Files changed

**New (8):** `trust_signals.dart`, `trust_strip.dart`, `review_stats.dart`,
`rating_summary.dart`, `review_card.dart`, `project_meta.dart`,
`test/domain/trust_signals_test.dart`, `test/domain/review_stats_test.dart`.

**Modified (11):** `contractor_listing.dart`, `discovery_repository.dart`,
`review.dart`, `reviews_sheet.dart`, `contractor_showcase.dart`,
`contractor_showcase_header.dart`, `contractor_showcase_sections.dart`,
`contractor_card.dart`, `project_detail_screen.dart`, `tier_badge.dart`,
`strings.dart`.

**Migrations:** none. Nothing in this phase required a schema change, and the
metrics that would have required one were built as UI architecture instead.

---

## 5. Future recommendations

Not implemented, listed for a later decision.

1. **Measure the three declared metrics.** A nightly job over `briefs` and
   `quotes` gives median first-quote latency and quote rate; accepted-versus-
   completed gives the completion rate. The UI is already waiting for them.
2. **Review photos.** `photo_urls` on `reviews` plus an upload in
   `write_review_sheet`. `ReviewCard` and the photo filter already handle them.
3. **Project-linked reviews.** A denormalised `project_title` on `reviews`, set
   at insert. Briefs are not readable by third parties under RLS, so no join can
   resolve it after the fact.
4. **Business verification.** A `business_verified` column plus a document type
   in the existing 0015 verification flow.
5. **Before/after media.** A pair role on portfolio photos; the strongest
   renovation proof there is, and the one item in the brief with no data model
   behind it at all.
6. **Server-side review paging.** The breakdown is computed from the newest 100
   rows and says so when it is capped; above a few hundred reviews that note
   should become a real aggregate.
