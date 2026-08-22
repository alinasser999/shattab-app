# Shattab Repository Audit

Date: 2026-08-14

This audit began as a pre-hardening baseline. The worktree contains substantial
uncommitted product and visual work; those changes are treated as the current
baseline and are not reverted. Current release status is maintained in
`docs/production-readiness.md`.

## Repository Map

| Area | Current responsibility |
| --- | --- |
| `lib/main.dart`, `lib/app.dart` | Flutter bootstrap, Sentry setup, `MaterialApp.router` |
| `lib/core/` | Router, theme, localization, Supabase client, shared widgets and utilities |
| `lib/features/auth/` | Phone/OTP auth, profile model, current-profile providers |
| `lib/features/onboarding/` | Homeowner and contractor onboarding flows |
| `lib/features/discovery/` | Homeowner discovery, contractor profiles, completed work and collections |
| `lib/features/briefs/` | Homeowner briefs and contractor opportunities |
| `lib/features/explore/` | Community feed, posts, comments, likes and saves |
| `lib/features/portfolio/` | Contractor portfolio CRUD and gallery |
| `lib/features/inbox/`, `lib/features/quotes/` | Requests, offers and quote lifecycle |
| `supabase/migrations/` | Versioned Postgres schema, RLS, storage policies and RPCs |
| `test/` | Domain, repository/provider and widget regression tests |
| `.github/workflows/ci.yml` | Flutter analyze and test gate |

## Confirmed Strengths

- Feature folders already separate most data, domain and presentation code.
- Riverpod code generation gives providers explicit ownership and keeps async
  state out of most widgets.
- Supabase access is generally concentrated in repositories rather than being
  scattered through every screen.
- The migration history includes keyset pagination, RLS initialization-plan
  optimizations, account deletion, moderation, quote lifecycle and admin
  lockdown work.
- Sentry is optional and configured to avoid default PII and screenshots.
- The current test suite has 330 passing tests, with two existing golden tests
  skipped by their own setup.
- The app has shared theme tokens and reusable `Batsh*` widgets, which should
  remain the visual and accessibility foundation.

## Findings

### High: Debug credentials are in source

- Location: `lib/core/debug/debug_config.dart`.
- Issue: a debug email and password are hard-coded in the repository.
- Risk: repository readers, logs or copied debug builds can obtain credentials
  for the seeded Supabase account. This is not a production auth path, but it
  is still an avoidable secret-management failure.
- Safe fix: require an explicit, ignored `.env` opt-in with local-only debug
  credentials. Release builds must never read or use this path.
- Validation: source scan for password literals, tests for disabled/missing
  debug configuration, debug startup with and without the opt-in.
- Status: fixed in phase 1; existing local `.env` files are not modified.

### High: Runtime error capture is not guaranteed without Sentry

- Location: `lib/main.dart` and the repository-wide `debugPrint` call sites.
- Issue: when `SENTRY_DSN` is empty, Flutter framework and uncaught async
  failures have no centralized application logging path.
- Risk: production-like failures become difficult to diagnose, and error
  messages are handled inconsistently.
- Safe fix: add a privacy-aware logger and install framework/async error hooks;
  preserve Sentry as the existing upstream reporter when configured.
- Validation: unit-test redaction and run a debug startup smoke test.
- Status: fixed in phase 1 for logging and hooks; remote alerting still needs
  an environment-specific Sentry DSN and operational ownership.

### High: CI did not verify a build or generated-code freshness

- Location: `.github/workflows/ci.yml`.
- Issue: CI runs `flutter analyze` and `flutter test`, but does not run a web or
  mobile build, format check, dependency audit, secret scan, or migration lint.
- Risk: broken release compilation, stale generated providers and migration
  errors can reach review.
- Safe fix: add gates incrementally after the existing baseline is clean. Do
  not turn on a format gate while 251 files are currently reported as already
  formatted and one dirty file would be rewritten without review.
- Validation: each new gate must pass on a clean branch before becoming
  required.
- Status: CI now generates ignored code, checks formatting and analysis, runs
  tests, compiles an unsigned Android release target, and verifies a web
  release build. Migration and remote-advisor gates remain intentionally
  separate.

### Medium: Presentation files are oversized

- Locations: `profile_screen_homeowner.dart` (2,356 lines),
  `public_professional_profile.dart` (1,528),
  `profile_screen_contractor.dart` (1,507), and
  `job_opportunities_screen.dart` (1,206).
- Issue: several screens contain many private components and orchestration
  concerns in one file.
- Risk: visual changes and state changes have large regression surfaces and
  are difficult to review.
- Safe fix: extract one cohesive component family at a time, beginning with
  pure sections that have existing widget coverage. Preserve route and provider
  APIs during extraction.
- Validation: widget tests, analyzer, screenshots for affected screens.
- Status: deferred to feature-by-feature phase 3.

### Medium: Database security surface needs a focused live-schema review

- Locations: `supabase/migrations/0027_admin.sql`,
  `0028_admin_rpc.sql`, and earlier `SECURITY DEFINER` functions.
- Issue: the repository contains many privileged functions and admin policies.
  Static inspection alone cannot prove deployed grants, ownership, or policy
  state.
- Risk: an incorrect grant, search path, or policy could create privilege
  escalation or make an intended operation silently fail.
- Safe fix: compare local migration intent with the linked project using
  Supabase advisors and explicit policy/function/grant queries before changing
  SQL.
- Validation: RLS tests for anonymous, authenticated-owner and authenticated-
  non-owner cases; migration lint; advisor output.
- Status: live authority, projection, payment, contact, verification,
  interaction and pagination migrations have been applied and checked against
  the linked project. The repository now includes an RLS regression harness;
  it still needs a disposable local/staging database with the pgTAP dependency
  enabled before it can run.

### Medium: Collection reads need a complete pagination inventory

- Evidence: several repositories now cap reads at 100 rows, while the product
  has feed, inbox, saved, review, quote, portfolio and discovery collections.
- Issue: a cap is safer than an unbounded query, but it is not a user-visible
  pagination contract.
- Risk: older records can become unreachable, or screens can retain too much
  state as the dataset grows.
- Safe fix: inventory each collection, define cursor ownership and add a stable
  `(created_at, id)` ordering before adding more caching or realtime behavior.
- Validation: repository tests for duplicate-free page merges and stable cursors.
- Status: discovery, briefs, community feed, completed work and saved
  professionals use stable cursors. Bounded account-history lists remain on
  the register until their screens need a user-visible next-page contract.

### Low: Documentation and operational handover are incomplete

- Locations: `README.md` and `docs/`.
- Issue: the README describes the product and setup, but there is no concise
  architecture boundary document, incident runbook or measurable scaling
  roadmap.
- Risk: future contributors repeat risky assumptions and incidents take longer
  to diagnose.
- Safe fix: add the engineering documents in phase 1 and keep them close to
  the code.
- Status: fixed in phase 1.

## Phased Plan

1. Baseline and documentation: this audit, architecture boundaries and
   operational runbook.
2. Foundation hardening: logging, startup configuration validation, CI build
   gate and generated-code policy.
3. Feature extraction: split the largest presentation files along existing
   route/provider boundaries, one feature at a time.
4. Data contracts: finish cursor pagination, typed failures, repository
   timeouts/retry policy and deterministic mutation behavior.
5. Supabase review: compare migrations with the deployed schema, test RLS and
   storage policies, then add only evidence-backed indexes or migrations.
6. Performance and operations: image sizing, request deduplication, measured
   caching, Sentry ownership, backup/restore drills and safe staging load tests.
7. CI/CD maturity: add format, build, dependency, secret, migration and
   release checks once each baseline is clean.

## Original Phase Boundaries

- No microservices, queue, external cache or search service.
- No framework migration or unrelated product-area rewrite; targeted
  production hardening migrations were added only where the live boundary
  required them.
- No visual redesign or route change.
- No claim that the product currently supports one million concurrent users.

## Validation Notes

- `flutter analyze --no-pub`: passed with no issues after phase 1 cleanup.
- `flutter test --no-pub`: 330 tests passed, with two existing golden skips.
- `dart format --output=none --set-exit-if-changed lib test`: passed.
- `dart run build_runner build`: completed and wrote generated outputs.
- `flutter build web --release`: passed.
- `supabase test db --workdir supabase`: blocked because the local Postgres
  service is not running; run it in the disposable/staging gate described in
  `docs/production-readiness.md`.
