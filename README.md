# بطش (Batsh)

Egyptian contractor hiring marketplace — homeowners discover and request renovation work
from contractors; contractors manage leads and showcase portfolios.

**Status:** M1 (Foundation) — phone OTP auth, role-aware onboarding, dual portal shells.
M2/M3/M4 features (discovery, requests, chat) deferred.

## Stack

- Flutter 3.41 (stable) — Android + iOS only
- Supabase (auth, Postgres + RLS, storage)
- Riverpod 3.x with code generation
- go_router with `StatefulShellRoute` for role-scoped tab navigation
- Stitch design system (Modern Heritage — terracotta/olive/gold on warm cream)

## Setup

```bash
flutter pub get
cp .env.example .env   # fill in SUPABASE_URL + SUPABASE_ANON_KEY
dart run build_runner build
flutter run
```

For phone OTP to fire real SMS you need Supabase phone auth + an SMS provider
(Twilio sandbox is fine for the demo).

## Layout

```
lib/
├── main.dart, app.dart                  Entry point, MaterialApp.router
├── core/
│   ├── theme/        Stitch tokens — colors, typography, spacing, radius, shadows
│   ├── router/       go_router config + role-aware redirect guard
│   ├── supabase/     Typed client wrapper + Riverpod provider
│   ├── widgets/      BatshButton/Card/TextField/Chip/Scaffold/Loading/Error
│   ├── env/, l10n/, utils/
└── features/
    ├── auth/         Phone entry, OTP, AuthRepository, providers
    ├── onboarding/   Role select + role-specific multi-step flows
    ├── shell/        HomeownerShell, ContractorShell, splash, profile
    ├── customer_home/, contractor_home/   M2/M3 placeholders
```

See `docs/specs/2026-05-14-m1-foundation-design.md` for the full architecture.
See `docs/design-tokens.md` for the Stitch token extraction.

## RTL

The whole app runs in `TextDirection.rtl` and Arabic copy lives in
`lib/core/l10n/strings.dart`. Will migrate to ARB-based `flutter_localizations`
once copy stabilizes in M2.
