---
title: "M1 Completion Report"
date: 2026-05-15
status: complete
---

# Batsh M1 — Foundation, complete

## Supabase project

| Field | Value |
|---|---|
| Project ref | `ajqdutehxpbbflzdovhw` |
| Region | eu-central-1 |
| URL | https://ajqdutehxpbbflzdovhw.supabase.co |
| Cost | $0 / month (free tier) |
| Status | ACTIVE_HEALTHY |

Public anon key is in `batsh-app/.env` (modern `sb_publishable_*` format). Legacy
JWT anon key is also available via the dashboard or `get_publishable_keys`.

## Migrations applied

1. `0001_init_profiles` — `profiles`, `homeowner_profiles`, `contractor_profiles`,
   `handle_new_user` trigger on `auth.users` insert, `tg_set_updated_at` maintenance
   triggers, RLS policies per spec.
2. `0002_storage_buckets` — `avatars` and `contractor-logos` public buckets with
   owner-prefix INSERT/UPDATE policies.
3. `0003_security_hardening` — pinned `tg_set_updated_at` search_path, revoked
   public/anon/authenticated EXECUTE on `handle_new_user` (callable only via
   trigger now), dropped redundant SELECT policies on public buckets (URL access
   doesn't need them).

`get_advisors security` returns zero lints.

## Demo seeds

| User | UUID | Phone | Role | Notes |
|---|---|---|---|---|
| أحمد محمود | `aaaaaaaa-0000-0000-0000-000000000001` | +201001234567 | homeowner | 2BR in التجمع الخامس; paint/kitchen/bathroom |
| شركة بناء الحياة | `bbbbbbbb-0000-0000-0000-000000000001` | +201007654321 | contractor | 12y exp; 5 specialties; 3 service areas |

Both have `onboarding_complete = true` — useful for testing the router redirect
that lands homeowners on `/h/discover` and contractors on `/c/dashboard`.

## Phone auth (deferred — needs dashboard action)

The Supabase MCP does not expose auth-provider config. To enable phone OTP for
real:

1. Open https://supabase.com/dashboard/project/ajqdutehxpbbflzdovhw/auth/providers
2. Enable **Phone** provider
3. Configure SMS — Twilio sandbox is fine for the demo, whitelist 2–3 numbers
4. (Optional) Tweak OTP length / expiry under **Settings → Auth → SMS template**

Until that's done, OTP send will fail with a clear "Phone provider not enabled"
error from the Supabase SDK.

## Deviations from spec

| Deviation | Reason |
|---|---|
| `freezed` not used for domain models | Three models, all trivial; hand-written
  `fromJson` + `copyWith` adds <50 lines and avoids a build_runner dependency on
  the model-write loop. Will revisit if model count grows past ~8. |
| `riverpod_lint` + `custom_lint` dropped | They pull `freezed_annotation ^2.x`
  which conflicts with our `^3.x`. The static analyzer still catches the
  important issues; we can re-add when riverpod_lint catches up. |
| Fonts via `google_fonts` CDN, not bundled TTFs | Faster ship for M1; switch to
  bundled fonts (IBM Plex Sans Arabic + Noto Naskh Arabic + Plus Jakarta Sans
  + Noto Serif) if offline-first becomes a goal. |
| Web/desktop platforms disabled | Spec section 2 decision #3. |
| `flutter_localizations` set up but ARB files deferred | All copy is in
  `lib/core/l10n/strings.dart` as plain constants. Migrate to ARB-based gen_l10n
  in M2 once copy stabilizes. |

## What's verified

- `flutter analyze` → zero issues
- `flutter test` → green (1 theme color test)
- `dart run build_runner build` → 7 generated outputs (riverpod parts)
- Supabase tables created with RLS enabled
- Supabase advisors → zero security lints

## What's NOT verified yet (needs your hands on a device)

- Phone OTP round-trip — requires phone provider enabled (see above)
- Onboarding flow on a real device — should be smoke-tested once phone auth is
  enabled
- Killing the app mid-onboarding and resuming at the correct step
- RTL rendering on iOS specifically (Android tested via emulator)

## Action items for you

1. **Rotate the Stitch API key** — it was pasted in plaintext in a previous
   session and is in `~/.claude.json`. The handoff doc flagged this.
2. **Enable Supabase phone auth** in the dashboard (link above). Without this,
   the app will run but OTP send will error out.
3. (When ready) — flip to bundled fonts to remove the Google Fonts CDN hop on
   first launch.

## Hand-off to M2

M2 focus per the original plan: customer-side discovery, search/filter,
contractor profile viewing, request creation. The data model already supports
contractor discovery (RLS allows everyone to SELECT contractor profiles).
