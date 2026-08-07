# Shattab Operations Runbook

Date: 2026-08-03

## Local Startup

```powershell
flutter pub get
Copy-Item .env.example .env
dart run build_runner build
flutter run
```

Required client values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Optional values:

- `SENTRY_DSN` enables crash reporting.
- `SUPABASE_IMAGE_TRANSFORMS=true` enables paid Supabase image transforms.
- `DEBUG_AUTH_ENABLED=true`, `DEBUG_AUTH_EMAIL` and `DEBUG_AUTH_PASSWORD`
  enable the local seeded-user shortcut in debug builds only.

Never place a Supabase service-role key or any server secret in `.env` bundled
with Flutter. `.env` is ignored locally, but values included in a client build
must be treated as public.

## Verification Commands

```powershell
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
flutter build web --release
supabase db lint --workdir supabase
```

The migration command requires the Supabase CLI and a compatible local setup.
Run remote advisors and RLS checks only against the intended project or a safe
staging project.

## Incident Triage

### App fails during startup

1. Confirm `.env` contains the two required public client values.
2. Check the first logged bootstrap error category, not the raw response body.
3. Confirm Supabase status and auth reachability.
4. If only one feature fails, bypass the affected route and inspect its
   repository/provider logs.

### Authentication failures

1. Confirm the OTP provider and Supabase Auth status.
2. Do not ask users for tokens or log them.
3. Check whether the session expired or the role/profile row is missing.
4. Verify route-guard behavior with an anonymous session and an authenticated
   user in a safe environment.

### Database or RLS failures

1. Capture the operation name and safe error category.
2. Reproduce with an owner and non-owner test account.
3. Inspect the relevant migration and policy before changing client code.
4. Use Supabase advisors and `EXPLAIN` on a staging database.
5. Ship policy changes only as a versioned migration.

### Broken deployment

1. Stop promotion of the affected build.
2. Compare the build commit with the last known-good commit.
3. Roll back the client release or revert the migration only with the
   documented expand-and-contract plan.
4. Re-run smoke tests before reopening promotion.

## Recovery Requirements

- Confirm database backup and point-in-time recovery settings with the Supabase
  project owner.
- Test restoration against a non-production project before relying on it.
- Document storage recovery separately; database backup does not guarantee
  recovery of every object in a storage bucket.
- Rotate any credential that appears in a log, build artifact or repository.
- Record the incident, impact, trigger, mitigation and follow-up test.

## Ownership Gaps

The repository does not yet encode an on-call owner, alert destination or
restore drill schedule. Those are operational decisions that must be assigned
before production traffic grows; the code change in phase 1 does not pretend
to solve them.
