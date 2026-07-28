# Shattab — Onboarding Brief for a New AI Agent

Read this before touching anything. It is the current-state map of the repo as of
**2026-07-27**, branch `feat/bottom-nav-redesign`.

> **`CLAUDE.md`, `README.md` and `PRODUCT.md` are stale.** They stop at M3 and say
> "M4 not started". The app has since shipped reviews, monetization, verification,
> moderation, account deletion, trust tiers, a social feed, and a separate Next.js
> admin console. Where those files disagree with this one, this one is right —
> but verify against code before relying on either.

---

## 1. What the product is

**Shattab (شطب)** — a Flutter marketplace connecting Egyptian homeowners with
renovation/finishing professionals. Arabic-first, RTL, Android + iOS only.

Two roles, chosen at signup and **locked** (no switching):

- **Homeowner (طالب خدمة)** — posts renovation briefs, browses professionals,
  receives quotes, hires, confirms completion, reviews.
- **Contractor / professional (مقاول)** — sees briefs matched to their specialty
  and service area, sends quotes, manages a portfolio, receives direct requests.

Core product rules that shape a lot of the code:

- **No in-app chat.** All contact is WhatsApp / phone deep links (`url_launcher`).
  Do not add messaging.
- **Phone OTP auth only** (+20 Egypt), plus Sign in with Apple for App Store
  compliance. No email/password in the mobile app.
- **Arabic is the source language.** Every user-facing string lives in
  `lib/core/l10n/strings.dart` (class `S`, ~1370 lines). Never hardcode copy.

---

## 2. Stack

| Layer | Choice |
|---|---|
| Client | Flutter, Dart SDK `^3.11.5` — Android + iOS (web/desktop disabled) |
| Backend | Supabase — Postgres + RLS + Auth + Storage, project ref `ajqdutehxpbbflzdovhw`, `eu-central-1` |
| State | Riverpod 3.x with codegen (`riverpod_annotation`, `@Riverpod`) |
| Routing | `go_router` v17, `StatefulShellRoute.indexedStack` |
| Motion | `flutter_animate` |
| Crash reporting | `sentry_flutter` (PII off by default; DSN optional in `.env`) |
| Admin console | Separate Next.js 15 app in `admin/` |

Package name is still **`batsh`** — the brand was renamed to Shattab in M2 but the
repo was not, to avoid churn. Keep `package:batsh/...` imports.

---

## 3. Repo layout

```
lib/
├── main.dart, app.dart, preview_pro.dart
├── core/
│   ├── env/          .env wrapper
│   ├── l10n/         strings.dart (all copy) + locale_provider
│   ├── models/       shared models (DraftPhoto, …)
│   ├── router/       app_router.dart, routes.dart, role_guard.dart, transitions.dart
│   ├── supabase/     client wrapper + provider
│   ├── theme/        11 token files (see §6)
│   ├── utils/        error_mapper, validators, time_format, image_url, extensions
│   └── widgets/      29 shared Batsh* widgets (see §6)
└── features/         auth, onboarding, shell, discovery, briefs, explore, inbox,
                      quotes, portfolio, profile, reviews, saved, billing,
                      verification, moderation
supabase/migrations/  0001 … 0028
admin/                Next.js operator console
docs/                 specs, completion reports, design tokens, legal, checklists
test/                 20 test files (~186 tests)
```

Each feature follows `{data, domain, presentation}`. `presentation/providers/`
holds Riverpod providers; larger screens are split into `part` files.

---

## 4. Navigation

Role-aware guard in `lib/core/router/role_guard.dart`. Paths in
`lib/core/router/routes.dart` — **always use the `Routes.*` constants**, never
string literals.

**Homeowner `/h/*` — 5 tabs:** Explore (feed) · Discover (professionals) ·
Requests (own briefs) · Saved · Profile

**Contractor `/c/*` — 5 tabs:** Explore (feed) · Opportunities (`/c/dashboard`,
matched briefs) · Inbox (direct requests) · Portfolio · Profile

`/pro` is a full-screen route above both shells (monetization).

Note the naming trap: the contractor Opportunities tab lives at
`Routes.contractorDashboard` = `/c/dashboard`, not `/c/opportunities`.

---

## 5. Domain model — the concepts that actually matter

- **Brief** — a job. Two flavours: a public post, or a *direct* request aimed at
  one professional (`target_contractor_id`). `BriefStatus` (open | cancelled)
  plus `BriefStage` for the completion loop.
- **Quote** — one per contractor per brief (unique constraint). Status:
  sent | accepted | declined | withdrawn. Accepting is guarded server-side
  (`accept_quote` RPC + `tg_lock_accepted_quote`), not in the client.
- **Post** (`features/explore`) — the social feed, distinct from briefs.
  `PostType`: project_showcase | tip | milestone | renovation_update. Likes,
  comments, saves. Feed is keyset-paginated (`get_for_you_feed`).
- **ContractorTier** — bronze | silver | gold. **Earned**, never purchased,
  derived from completed jobs + reviews + verification. Rendered by `TierBadge`,
  which deliberately shares no visual language with the paid Pro badge. Bronze is
  not shown publicly (`isPublic`).
- **ProviderKind** — self-declared identity: contractor | engineer |
  engineering_office | finishing_company | interior_designer | tradesman. The
  enum's `wire` value must match the `provider_kind` CHECK in migration `0026`.
- **Pro plan** — paid subscription (`contractor_profiles.plan == 'pro'`),
  orthogonal to tier.

### Monetization (`lib/features/billing/pricing.dart` is the single source of truth)

- Free contractors: **3 quotes / calendar month** (`free_quote_limit`,
  `my_quote_quota` RPCs), **5 portfolio projects**.
- Pro: 299 EGP/mo or 2990 EGP/yr. Featured week 199 EGP, quote boost 49 EGP.
- Payment is **manual InstaPay transfer + proof upload → admin approval**
  (`payment_requests`, `payment-proofs` bucket). Apple Pay is a stub.
- Change a price in `pricing.dart` and every surface follows. Do not inline numbers.

---

## 6. Design system — the rules you will be judged on

Tokens in `lib/core/theme/`: `BatshColors`, `BatshTypography`, `BatshSpacing`,
`BatshRadius`, `BatshShadows`, `BatshMotion`, `BatshIconSize`, `BatshBorderWidth`,
plus `theme_mode_provider` and `motion_mode_provider`.

**Modern Heritage** palette: terracotta `#9E3D18` primary, olive secondary, gold
tertiary, warm cream surface. Light + dark both fully defined.

Hard rules (a recent multi-commit sweep enforced all of these — do not regress):

1. **No raw hex, ever.** Use `BatshColors.*`.
2. **No bare Material widgets** in feature code. Compose the 29 `Batsh*` atoms:
   `BatshScaffold`, `BatshCard`, `BatshButton`, `BatshTextField`, `BatshChip`,
   `BatshBadge`, `BatshSnack`, `BatshDialog`, `BatshSheet`, `BatshEmptyState`,
   `BatshError`, `BatshShimmer`, `BatshSearchBar`, `BatshSectionHeader`,
   `BatshPressable`, `BatshPhotoViewer`, `BatshStars`, `BatshBottomNav`, …
3. **No literal icon sizes** → `BatshIconSize.*`. No `BorderRadius.circular()` →
   `BatshRadius.*`. No `Curves.*` → `BatshMotion.*`.
4. **Skeletons, not spinners.** Async content surfaces use `BatshShimmerBox` /
   `BatshListSkeleton` / `BatshProfileSkeleton`.
5. **Guard every animation** with `MediaQuery.of(context).disableAnimations` —
   reduced motion is honoured including in page transitions.
6. Transient feedback → `BatshSnack`. Confirmations → `BatshDialog`. Bottom
   sheets → `BatshSheet`. Empty states → `BatshEmptyState` with a reason *and* an
   action; errors → `BatshError`, not an empty state.
7. Minimum touch target 44×44dp; WCAG AA contrast.

Naming: `_<Feature>Skeleton` for loading, `_<Feature>Fallback` for error fallbacks.

Reference docs: `docs/design-tokens.md`, `docs/design-system-audit.md`,
`docs/design-system-completion.md`.

---

## 7. Database

18 tables. `profiles` · `homeowner_profiles` · `contractor_profiles` · `briefs` ·
`quotes` · `reviews` · `saved_contractors` · `portfolio_projects` · `posts` ·
`post_likes` · `post_comments` · `post_saves` · `payments` · `payment_requests` ·
`verification_requests` · `content_reports` · `user_blocks` · `admin_users` ·
`admin_audit_log`.

Storage buckets: `avatars`, `brief-photos`, `portfolio-photos`, `post-media`,
`payment-proofs`, `verification-docs`.

Migrations `0001`–`0028` are on disk in `supabase/migrations/`. Highlights:
`0013` monetization, `0016` accept-quote guard, `0019` completion loop,
`0021` admin RPC lockdown (privilege-escalation fix), `0022` RLS initplan perf,
`0023` account deletion, `0024` reports + blocks, `0025` free quote quota,
`0027`/`0028` admin table + 8 SECURITY DEFINER RPCs with audit logging.

**Security posture — do not weaken it:**

- Everything is behind RLS. There is **no service-role key in any client**,
  mobile or admin.
- Privileged operations are `SECURITY DEFINER` RPCs that begin with
  `admin_require()`; each writes to `admin_audit_log`, which admins cannot edit
  or delete.
- Triggers enforce invariants the client must not be trusted with:
  `tg_block_selfupgrade`, `tg_block_self_suspend`, `tg_guard_quote_fields`,
  `tg_guard_brief_edit`, `tg_lock_accepted_quote`, `tg_reject_if_suspended`,
  `tg_reviews_rollup`.
- Some early tables (`portfolio_projects`, parts of `0003`/`0004`) were applied
  live before the SQL landed on disk. **Do not re-run `0003`/`0004`** blindly.

Before schema work: `list_tables` first, and check `docs/go-live-checklist.md`.

---

## 8. Admin console (`admin/`)

Next.js 15 App Router on port **4321**, reading the same Supabase project with the
**anon key only**. Six pages: overview (timeseries/funnel), users (+suspend/block),
contractors (+verify/plan/tier), moderation queue, payments, audit log.

Auth is **email + password**, not phone OTP — deliberately, so an ops tool does not
cost an SMS per login. Admin status comes from the `admin_users` table via
`public.is_admin()`, orthogonal to the app's homeowner/contractor roles.
Middleware is a signpost; the database is the gate.

Bootstrapping the first admin is manual and off-system by design — see
`admin/README.md`.

---

## 9. Code conventions

- **Riverpod 3:** use `.value`, not `.valueOrNull` (removed). `@Riverpod` codegen;
  regenerate with `dart run build_runner build --delete-conflicting-outputs`.
  Generated `.g.dart` files **are committed**.
- **`riverpod_lint` / `custom_lint` must not be added** — they conflict with
  `freezed_annotation ^3.x`.
- **Models:** hand-written `copyWith` + `fromJson`. Only reach for freezed at 8+
  fields or union variants.
- **Imports:** relative paths inside the app; package imports for third-party only.
- **Enums that cross the wire** carry an explicit `wire`/`dbValue` and a tolerant
  `fromWire`/`fromDb` that falls back rather than throwing — an older client must
  not crash on a value a newer migration added.
- `dart format` is **not** enforced; most files are not format-clean, and a
  blanket reformat would bury real diffs.

---

## 10. Verification

```bash
flutter analyze
```

```bash
flutter test
```

CI (`.github/workflows/ci.yml`) runs `pub get` → `analyze` → `test` on PRs and
pushes to `main`. Both must stay green; ~186 tests currently pass. Format checks
and build_runner freshness are deliberately not gated.

Setup from scratch:

```bash
flutter pub get && cp .env.example .env && dart run build_runner build --delete-conflicting-outputs
```

`.env` needs `SUPABASE_URL`, `SUPABASE_ANON_KEY`, optionally `SENTRY_DSN` and
`SUPABASE_IMAGE_TRANSFORMS` (leave `false` unless the Supabase plan includes image
transformations — turning it on without one 404s every photo). **Never commit `.env`.**

---

## 11. Known open items

- **Push notifications are not built.** Nobody is told when a quote or request
  arrives; the loop depends on reopening the app. Biggest retention gap.
- Supabase **Phone provider + an SMS gateway that delivers to +20** must be
  enabled in the dashboard or no one can log in. Pending as of the last checklist.
- Android release signing needs a local, gitignored `android/key.properties`
  (see `docs/SHIPPING.md`).
- Leaked-password protection is off in Supabase; the advisor flags it.
- Store submission steps: `docs/store-submission.md`, `docs/go-live-checklist.md`.

---

## 12. Do not

- Add in-app chat.
- Add `riverpod_lint` or `custom_lint`.
- Commit `.env`, or put a service-role key in any client.
- Use raw hex, bare Material widgets, or literal sizes/radii/curves.
- Re-run migrations `0003` / `0004` against the live project.
- Change homeowner-facing portfolio screens (`portfolio_gallery_screen.dart`)
  without a reason — they are wired and stable.
- Trust `CLAUDE.md` / `README.md` / `PRODUCT.md` on anything past M3.
