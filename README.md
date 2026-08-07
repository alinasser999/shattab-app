# شطب (Shattab / Batsh)

Egyptian contractor hiring marketplace — homeowners post renovation jobs; contractors quote, get hired, and manage their portfolio.

**Status:** M3 (Contractor Core) complete — quotes, inbox, portfolio management, shimmer/motion polish. M4 (Comm & Polish) deferred.

## Stack

- Flutter 3.41 — Android + iOS only (web/desktop disabled)
- Supabase (auth, Postgres + RLS, storage) — project ref `ajqdutehxpbbflzdovhw`
- Riverpod 3.x with code generation (`riverpod_annotation`)
- go_router v17 with `StatefulShellRoute.indexedStack`
- Phone OTP auth only (+20 Egypt), role locked at signup
- Arabic RTL by default; all copy in `lib/core/l10n/strings.dart`

## Setup

```bash
flutter pub get
copy .env.example .env   # fill in SUPABASE_URL + SUPABASE_ANON_KEY
dart run build_runner build
flutter run
```

## Commands

```bash
flutter analyze        # lint check (generated .g.dart files excluded)
dart run build_runner build --delete-conflicting-outputs   # regenerate Riverpod code
```

## Architecture

Feature-first structure — each feature has `{data, domain, presentation}` layers:

```
lib/
├── main.dart, app.dart         Entry point, MaterialApp.router
├── core/
│   ├── env/                    Environment variables (.env wrapper)
│   ├── l10n/                   Arabic/English strings, locale provider
│   ├── models/                 Shared domain models (e.g., DraftPhoto)
│   ├── router/                 go_router config + role-aware guard + route constants
│   ├── supabase/               Supabase client wrapper + Riverpod provider
│   ├── theme/                  Design tokens — colors, typography, spacing, radius, shadows, motion
│   ├── utils/                  ErrorMapper, validators, time formatting, extensions
│   └── widgets/                Shared UI: BatshButton, BatshCard, BatshScaffold, shimmer, etc.
└── features/
    ├── auth/                   Phone entry, OTP, AuthRepository, current-profile provider
    ├── onboarding/             Role select + multi-step flows (homeowner / contractor)
    ├── shell/                  HomeownerShell, ContractorShell (tab shell), splash, profile
    ├── briefs/                 Public posts, create post, send brief, post detail (both roles)
    ├── discovery/              Discover contractors grid, filter sheet, contractor showcase
    ├── inbox/                  Contractor inbox — received requests, request detail, quote sheet
    ├── quotes/                 Quote CRUD, contractor CTA, homeowner received-quotes section
    ├── portfolio/              Contractor portfolio — CRUD, gallery, project detail, editor
    ├── profile/                Homeowner edit-profile screen, profile repository
    ├── reviews/                Review write sheet, review repository (M4 deferred)
    └── saved/                  Saved contractors list, toggle provider
```

## Conventions

- **State management:** Riverpod 3 with `@Riverpod` codegen. Notifiers for mutable state, providers for derived data.
- **Models:** Hand-written `copyWith` + `fromJson` unless 8+ fields or union variants (then freezed).
- **Widgets:** Compose `Batsh*` atoms (`BatshButton`, `BatshCard`, `BatshScaffold`), not bare Material widgets.
- **Design tokens:** Always reference `BatshColors.*`, `BatshTypography.*`, `BatshSpacing.*` — never raw hex.
- **Imports:** Relative paths throughout. Package imports for third-party libraries only.
- **Shimmer skeletons:** Use `BatshShimmerBox` for custom shapes or `BatshListSkeleton`/`BatshProfileSkeleton` for common patterns.
- **Reduced motion:** Guard all `.animate()` calls with `MediaQuery.of(context).disableAnimations` ternary.
- **Naming:** `_<Feature>Skeleton` for loading states, `_<Feature>Fallback` for error fallbacks.

## Key files

| Path | Purpose |
|------|---------|
| `lib/core/router/app_router.dart` | All routes + tab shell definitions |
| `lib/core/router/routes.dart` | Route path constants |
| `lib/core/l10n/strings.dart` | All Arabic + English copy |
| `lib/core/theme/` | BatshColors, BatshTypography, BatshSpacing, BatshRadius, BatshShadows, BatshMotion |
| `lib/features/auth/data/auth_repository.dart` | Auth + profile data access |

## Database

Migrations live in a separate Supabase project. Existing migrations:
- `0001_init_profiles` — initial profiles table + RLS
- `0002_storage_buckets` — storage buckets for photos
- `0003_contractors` — contractor skills/service-areas arrays
- `0004_briefs_and_saved` — briefs table, saved_contractors, brief-photos bucket
- `0005_quotes` — quotes table with RLS policies

See `CLAUDE.md` and `docs/` for full spec documents.

Engineering handover documents live in `docs/engineering/`: the repository
audit, target architecture, operations runbook and scaling roadmap.
