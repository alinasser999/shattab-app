# Shattab — Design System Audit (Phase 1, Task 1)

**Date:** 2026-07-27
**Branch:** `feat/bottom-nav-redesign`
**Scope:** `lib/` — 170 Dart files, ~85 widget classes under `lib/features`, 23 files under `lib/core/widgets`.
**Method:** static scan (ripgrep counts + manual read of token files and top-20 largest screens). No code changed.

---

## 0. Headline finding

**The design system already exists and is ~80% good.** This is not a greenfield problem.

`lib/core/theme/` already ships six token files (`batsh_colors`, `batsh_typography`, `batsh_spacing`, `batsh_radius`, `batsh_shadows`, `batsh_motion`) and `lib/core/widgets/` ships 23 files of `Batsh*` atoms including empty state, error, loading, shimmer skeletons, success checkmark and a pressable wrapper.

The real problems are **adherence, coverage gaps, and duplication** — not absence:

| Problem class | Severity | Count |
|---|---|---|
| Missing token families (icon size, border width, elevation alias) | High | 3 families |
| Literal values bypassing existing tokens | High | ~264 sites |
| Duplicated ad-hoc components (badge/pill/searchbar/avatar/stat) | High | ~40 private classes |
| No `SnackBar` abstraction | High | 77 call sites |
| No dialog / bottom-sheet primitive | Medium | 25 + 8 call sites |
| God files (>500 LOC screens) | Medium | 6 files |
| Empty states inconsistent, no illustration slot | Medium | 15 screens |
| Loading spinners not yet fully skeletonised | Low | 3 real sites |

---

## 1. Duplicated components

### 1.1 Exact-name duplicates (same class name, two files)

| Class | Locations |
|---|---|
| `_CoverFallback` | `core/widgets/contractor_card.dart`, `features/discovery/presentation/widgets/contractor_showcase.dart` |
| `_PortfolioTile` | `features/discovery/.../contractor_showcase.dart`, `features/portfolio/presentation/my_portfolio_screen.dart` |
| `_SearchBar` | `features/briefs/presentation/contractor/job_opportunities_screen.dart`, `features/discovery/presentation/discover_screen.dart` |
| `_Hero` | `features/billing/presentation/pro_screen.dart`, `features/briefs/.../widgets/job_card.dart` |

### 1.2 Semantic duplicates — the badge/pill/chip family

Thirteen private classes all render "small rounded label with optional icon":

`_Badge` (job_card), `_Pill` (post_detail), `_MiniChip` (contractor_card), `_StatChip` (contractor_card), `_CountChip` (quotes_received_section), `_CategoryChip` (discover_screen), `_RatingPill` (contractor_showcase), `_RatingBadge` (contractor_card), `_ProActivePill` (profile_screen), `_CancelledChip` (inbox_screen), `_StatusBadge` (brief_card), `_VerifiedBadge` (contractor_showcase), `_ProviderKindBadge` (contractor_showcase).

`BatshChip` exists but is filter-scoped. **No `BatshBadge` primitive exists.**

### 1.3 Semantic duplicates — stat display

`_MicroStats`, `_StatChip` (contractor_card) · `_StatCard`, `_StatsRow` (contractor_showcase) · `_StatBig`, `_StatCell`, `_StatStrip` (profile_screen).
Seven classes, one concept: `value + label`.

### 1.4 Semantic duplicates — avatars

`_Avatar` (quotes_received_section), `_AvatarRing` (contractor_showcase), `_HeroAvatar` + `_AccountAvatar` + `_ProfileFallback` (profile_screen), `_LogoAvatar` (contractor_card), `AvatarWithInitials` (discovery/widgets — the only public one).

`AvatarWithInitials` is the correct home; five reimplementations exist.

### 1.5 Semantic duplicates — section headers

`BatshSectionHeader` exists in core. Yet `_SectionHeader` (discover_screen), `_SectionLabel` (profile_screen), `_SectionDivider` (homeowner_edit_profile_screen), `_Section` (my_briefs_screen) reimplement it.

### 1.6 Semantic duplicates — skeletons

`BatshShimmerBox` / `BatshListSkeleton` / `BatshProfileSkeleton` exist. Per-screen skeletons are still hand-rolled in 11 classes: `_BriefDetailSkeleton`, `_DiscoverSkeleton`, `_EditorSkeleton`, `_GallerySkeleton`, `_InboxSkeleton`, `_PortfolioSkeleton`, `_PostDetailSkeleton`, `_ProfileSkeleton`, `_RequestDetailSkeleton`, `_SkeletonCard`, `_QuoteSkeletonCard`.

Per-screen skeletons are *legitimate* (shape must match content) — but they should compose `BatshShimmerBox`, and several don't.

### 1.7 Feedback duplication — `SnackBar`

**77 `SnackBar(` construction sites across 20 files.** Each rebuilds `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...)))` with locally chosen colors and durations. Worst: `payment_flow.dart` (9), `profile_screen.dart` (8), `report_sheet.dart` (8), `brief_detail_screen.dart` (6).

No success/error/info variant exists. Single largest consistency leak in the app.

---

## 2. Inconsistent spacing

`BatshSpacing` defines 2/4/8/12/16/20/24/32/40/48/64/80 plus semantic aliases. Good.

**18 sites bypass it:**

| Value | Sites | Off-scale? |
|---|---|---|
| `EdgeInsets.all(6)` | `app.dart:87`, `my_portfolio_screen.dart:276` | yes |
| `EdgeInsets.all(7)` | `job_card.dart:291` | yes |
| `EdgeInsets.symmetric(horizontal: 7, vertical: 2)` | `app.dart:117` | yes |
| `EdgeInsets.symmetric(horizontal: 10, vertical: 4)` | `job_card.dart:326` | yes |
| `EdgeInsets.symmetric(horizontal: 14)` | `phone_entry_screen.dart:610` | yes |
| `EdgeInsets.all(3)` | `batsh_switch.dart:42` | yes |
| `EdgeInsets.all(2)` | `contractor_card.dart:264`, `create_post_screen.dart:209`, `batsh_stars.dart:59` | maps to `xxxs` |
| `EdgeInsets.all(4)` | `photo_picker.dart:178`, `phone_entry_screen.dart:804`, `contractor_showcase.dart:414` | maps to `xxs` |
| `EdgeInsets.all(8)` | `contractor_showcase.dart:336` | maps to `xs` |
| `EdgeInsets.symmetric(horizontal: 4)` | `profile_screen.dart:483` | maps to `xxs` |
| `EdgeInsets.only(bottom: 80)` | `my_briefs_screen.dart:69` | maps to `huge` |

Half are trivially token-mappable; six introduce values (3, 6, 7, 10, 14) that don't exist on the scale.

Secondary finding: the ladder (`xxxs, xxs, xs, sm, md, ml, lg, xl, xxl, xxxl, xxxxl, huge`) is 12 rungs deep and hard to reason about. `ml = 20` wedged between `md` and `lg` is a smell.

---

## 3. Inconsistent typography

`BatshTypography` exists. **20 inline `TextStyle(` constructions outside `core/theme/`** — each a style that escaped the ramp.

The idiomatic pattern `BatshTypography.bodyMd.copyWith(color: ...)` is correct and dominant. The 20 raw sites are not.

Gap: no token pairs a text role with its **color**. Every call site independently decides `onSurface` vs `onSurfaceVariant`, so the same semantic role renders in different colors on different screens.

---

## 4. Inconsistent colors

Good news: **only 2 raw hex literals in 170 files.**

| Site | Value | Note |
|---|---|---|
| `app.dart:119` | `Color(0xFF9e3d18)` | this *is* `BatshColors.primary`, hardcoded — direct violation |
| `phone_entry_screen.dart:981` | `Color(0xFF4285F4)` | Google brand blue — legitimate value, wrong home; belongs in a `BrandColors` namespace |

Also present: `Colors.white24` / `Colors.white` / `Colors.black` in overlay and scrim code. These bypass the theme and will misbehave in dark mode, which is live (`theme_mode_provider.dart`).

---

## 5. Inconsistent border radius

`BatshRadius` defines `none/xs4/sm8/md12/lg16/xl20/xxl24/full` plus semantic `defaultR=16`, `card=24`, `image=20`.

**21 `BorderRadius.circular(N)` literal sites:**

| Literal | Count | On scale? |
|---|---|---|
| `circular(20)` | 9 | yes → `brXl` / `.brImage` |
| `circular(24)` | 4 | yes → `.brCard` |
| `circular(16)` | 2 | yes → `.brDefault` |
| `circular(8)` | 1 | yes → `.brSm` |
| `circular(26)` | 1 | **no** |
| `circular(15)` | 1 | **no** |
| `circular(11)` | 1 | **no** |
| `circular(5)` | 1 | **no** |
| `circular(2)` | 1 | **no** |

16 of 21 are token-mappable today. 5 are magic numbers that break the corner rhythm.

---

## 6. Inconsistent shadows

`BatshShadows` is the healthiest token family: `none/subtle/soft/elevated/raised/floating/modal`, all warm-tinted toward terracotta `#9E3D18`. **Only 1 inline `BoxShadow(` outside the theme.**

Gap: **no elevation *level* concept.** Shadows are named by intent (`raised`, `floating`) but nothing maps a numeric elevation (0–5) to a shadow + surface-tint pair, so `Material(elevation:)` / `Card(elevation:)` usage sits outside the system entirely.

---

## 7. Inconsistent icon sizes

**Worst offender in the audit. There is no icon-size token at all.**

143 literal `size: N` sites using **23 distinct values**:

```
20 (×26)  18 (×24)  14 (×17)  22 (×12)  16 (×11)  15 (×11)
28 (×6)   48 (×4)   40 (×4)   24 (×4)   13 (×4)   12 (×4)
72 (×2)   44 (×2)   34 (×2)   17 (×2)   11 (×2)
64, 46, 38, 36, 30, 21 (×1 each)
```

23 sizes for what should be a 5-rung scale. `13/14/15/16/17/18` are six near-identical sizes no user can distinguish, but which guarantee optical misalignment when two icons sit side by side.

---

## 8. Inconsistent border widths

No token exists. Stroke-width literals: `1` (×38), `1.5` (×11), `2` (×29), `3` (×9) — ~87 sites across 4 values. (Larger `width:` hits — 4, 6, 8, 9 — are `SizedBox`/`Container` dimensions, not strokes, and are excluded.)

`1` vs `1.5` vs `2` for the same conceptual hairline is visible at 3× density.

---

## 9. Animation durations and curves

`BatshMotion` is the best-architected token file in the repo — durations, custom cubics, stagger helpers, and a reduced-motion path (`durationFor` / `curveFor`).

**But it is widely bypassed:**
- 16 raw `Duration(milliseconds: N)` sites.
- **66 raw `Curves.*` references outside `core/theme/`.**
- Even core widgets bypass it: `batsh_empty_state.dart:43,47,58,79,93` hardcodes `350.ms`, `Curves.easeOut`, `Curves.easeOutBack` instead of `BatshMotion.slow` / `BatshMotion.easeOut`.

Consequence: the reduced-motion accessibility path is honoured *manually per widget* — `MediaQuery.of(context).disableAnimations` is re-checked in each file rather than centrally.

---

## 10. Component coverage gaps

Existing atoms: `BatshButton`, `BatshCard`, `BatshChip`, `BatshTextField`, `BatshSwitch`, `BatshScaffold`, `BatshBottomNav`, `BatshSectionHeader`, `BatshEmptyState`, `BatshError`, `BatshLoading`, `BatshShimmerBox`/`BatshListSkeleton`/`BatshProfileSkeleton`, `BatshSuccessCheckmark`, `BatshPressable`, `BatshStars`/`BatshStarInput`, `BatshPhotoViewer`, `BatshFilterSheet`/`BatshFilterButton`/`BatshActiveFilterChip`, `BatshGradientFallback`, plus domain components (`ContractorCard`, `BriefCard`, `RoleBadge`, `TierBadge`, `PhotoPicker`, `ContactButtons`).

**Against the Task-2 checklist:**

| Requested | Status |
|---|---|
| Buttons | ✅ `BatshButton` — but 31 raw `ElevatedButton`/`TextButton`/`OutlinedButton` sites bypass it |
| Cards | ✅ `BatshCard` — but ~40 raw `Card(`/`Container(` card-likes bypass it |
| Inputs | ✅ `BatshTextField` — but 36 raw `TextField`/`TextFormField` sites bypass it |
| **Dialogs** | ❌ none — 25 raw `AlertDialog`/`showDialog` sites |
| **Bottom Sheets** | ⚠️ `BatshFilterSheet` only — 8 raw `showModalBottomSheet` sites each re-declaring shape/handle/padding |
| **Badges** | ❌ none — 13 ad-hoc implementations (§1.2) |
| Chips | ⚠️ `BatshChip` exists, filter-scoped only |
| **Search Bars** | ❌ none — 2 `_SearchBar` duplicates |
| **Headers** | ⚠️ `BatshSectionHeader` exists; no screen-level app-bar primitive (`_PremiumAppBar` is a one-off) |
| Empty States | ⚠️ `BatshEmptyState` exists but icon-only, no illustration slot, no CTA emphasis |
| Loading States | ✅ shimmer family present |
| Error States | ✅ `BatshError` |
| **Success States** | ⚠️ `BatshSuccessCheckmark` exists but no success screen/sheet pattern; success is delivered via 77 ad-hoc SnackBars |

---

## 11. Empty states — per screen

`BatshEmptyState` is used in 15 files. It renders `icon in a tinted circle + title + optional message + optional action`.

Gaps vs the Task-5 requirement (illustration / headline / description / primary CTA):
- **No illustration** — a 72dp `Icon` in a 20%-alpha circle, hardcoded at `batsh_empty_state.dart:28-36`; not a token size, not an illustration.
- **Description optional and frequently omitted** — several call sites pass title only.
- **CTA optional and frequently omitted.**
- `job_opportunities_screen.dart` bypasses the shared widget entirely with bespoke `_EmptyJobsState` + `_NoSearchMatchState`.
- Empty-state copy lives in `strings.dart` (85 KB, largest file in the repo) but is not grouped, so tone cannot be reviewed as a set.

---

## 12. Loading states

Better than expected. Only **3 genuine bare-spinner sites** outside primitives:

| Site | Context |
|---|---|
| `features/explore/presentation/post_detail_screen.dart:442` | inline image load → should be shimmer |
| `features/moderation/presentation/report_sheet.dart:122` | sheet submit → should be button busy state |
| `features/shell/presentation/splash_screen.dart:106` | splash — legitimate, keep |

The other three (`batsh_button.dart:46`, `batsh_loading.dart:21`, `batsh_photo_viewer.dart:80`) are correct uses inside primitives.

Remaining work is composition, not replacement: several per-screen skeletons don't build on `BatshShimmerBox`.

---

## 13. Architecture / scalability findings

**God files** (design-system-relevant):

| File | Size | Private widget classes |
|---|---|---|
| `core/l10n/strings.dart` | 85 KB | — (single flat class, no grouping) |
| `features/shell/presentation/profile_screen.dart` | 55 KB | 24 |
| `features/discovery/.../contractor_showcase.dart` | 43 KB | 18 |
| `features/auth/presentation/phone_entry_screen.dart` | 41 KB | 14 |
| `features/discovery/presentation/discover_screen.dart` | 35 KB | 6 |
| `features/briefs/.../contractor/post_detail_screen.dart` | 28 KB | 11 |

Private widgets inside god files are the *mechanism* of duplication: invisible to the rest of the codebase, so the next screen reimplements them.

**Folder organisation:** `lib/core/widgets/` is a flat bag of 23 files mixing primitives (`batsh_button`) with domain components (`contractor_card`, `brief_card`, `tier_badge`). No `primitives/` vs `composites/` vs `domain/` separation.

**No design-system surface.** `docs/design-tokens.md` is referenced by `CLAUDE.md`, but there is no in-app gallery screen, so drift stays invisible until someone greps.

---

## 14. Ranked remediation plan (Tasks 2–7)

Ordered by value ÷ risk. No business logic touched at any step.

| # | Work | Files (est.) | Risk |
|---|---|---|---|
| 1 | **New tokens:** `BatshIconSize` (5 rungs), `BatshBorderWidth` (3 rungs), `BatshElevation` (0–5 → shadow + tint) | 3 new | none |
| 2 | **`BatshSnack`** — success/error/info feedback helper; migrate 77 call sites | 1 new, 20 edits | low |
| 3 | **`BatshBadge`** — one primitive; retire 13 ad-hoc badge/pill classes | 1 new, ~10 edits | low |
| 4 | **`BatshDialog`** + **`BatshSheet`** — shape/handle/padding/motion; migrate 25 + 8 sites | 2 new, ~15 edits | low |
| 5 | **`BatshSearchBar`**, **`BatshAppBar`**, **`BatshStat`**; promote `AvatarWithInitials` to core | 4 files | low |
| 6 | **Token sweep:** 143 icon sizes → `BatshIconSize`; 21 radii → `BatshRadius`; 18 spacings → `BatshSpacing`; 66 curves + 16 durations → `BatshMotion`; 2 hex → `BatshColors` | ~45 files, mechanical | low but wide |
| 7 | **Empty states:** illustration slot + required description + CTA emphasis on `BatshEmptyState`; audit all 15 + add the missing ones | 1 + ~18 edits | medium (copy) |
| 8 | **Skeletons:** rewrite per-screen skeletons to compose `BatshShimmerBox`; fix 2 remaining bare spinners | ~10 edits | low |
| 9 | **Perceived quality:** centralise reduced-motion behind a `BatshMotion.of(context)` accessor; route every tappable through `BatshPressable`; wire `pageTransition` tokens into `go_router` `CustomTransitionPage` | ~12 edits | medium |
| 10 | **Folder split:** `core/widgets/{primitives,composites,domain}/`; extract private widget classes out of the 6 god files | ~30 moves | medium (churn) |

**Deliberately excluded from Phase 1** (would change UX, copy, or features — out of scope per the brief): splitting `strings.dart`, rewriting any copy, changing navigation structure, dark-mode colour re-derivation.

---

## 15. Already good — do not touch

- `BatshMotion` design (custom cubics + reduced-motion helpers) is correct; only its *usage* needs fixing.
- `BatshShadows` warm-tinting for brand cohesion is a genuinely premium detail.
- Colour discipline: 2 hex literals in 170 files is excellent.
- `BatshPressable` and `BatshSuccessCheckmark` already exist — the perceived-quality foundation is laid.
- Feature-first structure `lib/features/<name>/{data,domain,presentation}` is consistent across all 14 features.

---

*End of Task 1. No files modified.*
