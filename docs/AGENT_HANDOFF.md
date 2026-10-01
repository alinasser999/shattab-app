# Shattab — GitHub Agent Handoff

This is the maintained starting point for a new agent reading the repository from GitHub. It describes the checked-in source and the evidence available for this handoff; source presence is not a release claim.

## Product and architecture

Shattab is an Arabic-first, RTL marketplace for Egyptian home renovation. The consumer app has two roles: homeowner and contractor. There is no user-to-user chat; contact is handed off through phone or WhatsApp.

Database authorization belongs in Supabase RLS and reviewed server-side RPCs. Client route guards shape navigation but are not a security boundary. The separate operator console uses database-backed admin authorization. Do not place a service-role key in a client.

### Code map

| Area | Where to start |
|---|---|
| Flutter app entry | `lib/main.dart`, `lib/app.dart` |
| Shared Flutter core | `lib/core/`: routing and role guards, Supabase providers, environment loading, localization helpers, theme, analytics, media, cache, notifications, utilities, and shared widgets |
| Flutter feature modules | `lib/features/`: auth, onboarding, shell, home, discovery, explore, briefs, inbox, quotes, portfolio, profile, saved, reviews, billing, verification, moderation, notifications, assistant |
| Localization | Source ARBs: `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`; generated classes are in `lib/l10n/`; locale helpers are in `lib/core/l10n/` |
| Operator console | `admin/`: Next.js 16.3.1 App Router, with users, contractors, moderation, payments, activity, and API routes |
| Supabase server functions | `supabase/functions/`: `assistant-chat`, `send-push`, and shared helpers |
| Database contracts | `supabase/migrations/` and `supabase/tests/`; SQL on disk does not prove live application |
| Public-media signer | `infra/media-signer/`: Cloudflare Worker source for Supabase-token-verified R2 upload signing |

Flutter localization strings come from the Arabic and English ARB files. Add copy there and follow the repository's generated localization flow rather than adding new strings to the old `strings.dart` catalog.

The operator console's checked-in [README](../admin/README.md) explains its anon-key and database authorization boundary. The [media signer README](../infra/media-signer/README.md) explains external setup; its source does not prove the Worker is deployed or enabled.

## Authentication and onboarding

**The intended authentication policy is unresolved.** Current Flutter login source supports Egyptian phone/password sign-in and sign-up, Google, and Apple on supported Apple platforms. SMS OTP remains in phone-signup confirmation, forgot-password recovery, and the guest write-action sign-in sheet. Older `PRODUCT.md` and `AI_ONBOARDING.md` statements saying OTP-only/no password do not match the current checked-in login source. This documentation does not select a policy or authorize an auth behavior change.

A newly authenticated user selects homeowner or contractor during the first onboarding step. The server-side role-selection transition locks that choice; do not describe the current flow as necessarily choosing a role at account creation. A role lock or onboarding RPC in local source depends on its corresponding database contract being present in the target environment.

## In-flight source details

- The guest write-action sign-in sheet currently has a phone-entry step, a six-digit OTP entry step, a cooldown-based resend control, and profile/name readiness steps. Its phone and OTP fields use LocalizedDigitsOnlyFormatter. The shared phone formatter converts Arabic-Indic and Persian numerals to ASCII; Egyptian phone normalization strips 0020, 20, or a local leading 0 and returns +20 E.164 form.
- The guest assistant action awaits showSignInSheet and exits without sending unless sign-in completed, the assistant widget remains mounted, and currentSessionProvider contains a session. It sends the queued prompt only after all three conditions pass. This is checked-in source behavior only.
- The homeowner project-creation flow persists local form drafts through FormDraftStore, including owner_id and a stable publish_key. BriefsRepository includes homeowner_id and publish_key in the publish payload. When an insert raises PostgrestException 23505 and a publish key was supplied, it selects only by the same homeowner_id and publish_key, returns that row if found, and otherwise rethrows.
- **Known, unverified edge case:** after a brief insert succeeds but its response is lost, the restored draft can retain its publish_key while the homeowner edits fields or photos. A retry may hit 23505 and return the earlier brief through the owner/key lookup; that lookup does not compare or update submitted scalar fields such as title or details. The provider can then upload retry photos against the returned earlier brief ID and call `setPhotoUrls`, so those photos may be associated with that earlier brief. Decide whether edits after an ambiguous publish rotate the key or remain blocked until retry resolution. This behavior has not been validated.
- These are current checked-in source behaviors only. No tests, build, runtime interaction, or live backend verification was run for this snapshot.

## Product and evidence constraints

- Keep the Arabic-first RTL experience, the two consumer roles, and the no-chat contact model.
- Keep authorization and entitlement decisions in reviewed database policies and server-side RPCs.
- Treat brand references, sample people, and sample work photos as concept assets. They do not prove a person's identity, contractor affiliation, ownership of work, or verification.
- Do not treat local migration files, generated assets, screenshots, or configured deployment files as evidence that a live service has matching state.
- Preserve the working tree and keep `.env`, local admin environment files, credentials, signing material, and service-role secrets out of commits and documentation.

## Local setup

Use a supported Flutter SDK compatible with the project. The checked-in CI currently selects Flutter 3.44.4.

From the repository root in PowerShell:

    flutter pub get
    Copy-Item .env.example .env
    dart run build_runner build
    flutter run

Fill only local development configuration in the local `.env`; never paste values into docs, task artifacts, or commands that may print them.

For the operator console, follow [admin/README.md](../admin/README.md). Its basic local install is from `admin/`:

    npm ci
    npm run dev

Use a local `.env.local` derived from the example there. The console runs on port 4321. Do not put a service-role key in its environment.

## CI commands

The command list below is copied from the checked-in `.github/workflows/ci.yml`; it is guidance, not evidence that CI or these commands passed for this snapshot.

### Flutter verify job

CI selects Flutter 3.44.4, then runs from the repository root:

    flutter pub get
    cp .env.example .env
    dart run build_runner build
    dart format --output=none --set-exit-if-changed lib test
    flutter analyze --no-pub
    flutter test --reporter=github
    flutter build web --release
    flutter build apk --release

### Admin console job

CI selects Node.js 22 and runs from `admin/`. The build receives fake placeholders only:

    npm ci
    npm run audit:contracts
    npm run typecheck
    npm run build

The workflow sets `NEXT_PUBLIC_SUPABASE_URL=https://placeholder.supabase.co` and `NEXT_PUBLIC_SUPABASE_ANON_KEY=ci-placeholder-anon-key` for this build.

### Database contract job

CI runs a local migration replay and an RLS contract suite. This job is marked `continue-on-error: true`; it is not proof of production migration state.

    supabase db reset
    PGPASSWORD=postgres psql -h localhost -p 54322 -U postgres -d postgres -v ON_ERROR_STOP=1 -f supabase/tests/rls_regression.sql | tee tap_output.txt
    if grep -q "^not ok" tap_output.txt; then echo "::error::RLS regression suite has failing assertions"; exit 1; fi

### iOS compile job

The macOS job selects Flutter 3.44.4, gets packages, generates code, creates the placeholder environment file, and runs:

    flutter pub get
    cp .env.example .env
    dart run build_runner build
    flutter build ios --release --no-codesign

## Current source snapshot

The source branch is `feat/bottom-nav-redesign`. The working snapshot includes active changes in Flutter auth/onboarding, shared core and navigation, home/discovery, briefs/quotes/inbox/portfolio, billing, media, assistant and localization; the Next.js admin console; Supabase function and migration source; tests, docs, and assets.

These areas are in flight. This documentation does not claim that each change is release-ready. For this combined snapshot, no tests, builds, app runtime checks, database commands, live service calls, or deployment checks were run. The documentation task does not apply database migrations, deploy the app or Worker, or merge to `main`. Recheck branch, working tree, compatibility, and required gates before follow-on work.

## Supabase migration source and prior audit

The following nine additions were present as local, untracked migration source when the task inspected this snapshot. Their presence in GitHub is not evidence of production application.

| Local migration | What the prior read-only audit reported |
|---|---|
| `20260824054052_accept_quote_status_guard.sql` | The exact timestamped version was present in the reported live migration history. The function body was not freshly compared here. |
| `20260907120000_specialized_provider_kind.sql` | The version was reported absent. |
| `20260909100000_professionals_v2_sort_and_filters.sql` | The version was reported absent. |
| 20260909100500_homeowner_brief_publish_fields.sql | The prior audit reported the version absent. Current client source persists a stable publish key and only recovers a 23505 through an exact homeowner_id/publish_key lookup; this path remains unverified. |
| `20260909101000_saved_portfolio_projects.sql` | The prior audit reported the version absent. Local SQL explicitly revokes PUBLIC/anon/authenticated, grants CRUD to authenticated, and limits its RLS policy to the authenticated homeowner who owns the saved row. Live application of these controls was not refreshed. |
| `20260910210000_assistant_quota.sql` | A live quota entry was reported as `20260910195950_assistant_quota` and described as semantically equivalent. This is not a fresh SQL comparison or proof for the local timestamp. |
| `20260929004741_contractor_contact_entitlement.sql` | The version was reported absent; the product must accept its contact-entitlement behavior before replacing a live contract. |
| `20260929025936_fix_homeowner_public_profile_sync_key.sql` | The version was reported absent. |
| `20260929120000_onboarding_role_lock_and_provider_kind.sql` | The version was reported absent and remains blocked for production as described below. |

### How to read that evidence

This is a summary of a previous dated, read-only audit recorded in the 2026-10-01 database sync task artifacts. The audit used Supabase read-only migration/catalog queries; its exact query timestamps were not recorded. **No live Supabase state was queried or refreshed for this GitHub handoff. Current live migration history, schema, grants, policies, and production client compatibility are unknown here.** The reported comparison is prior evidence and may have drifted.

The previous report said that, among these local versions, the exact `20260824054052` version was present, the seven versions listed as absent were not found, and the quota migration had a different live timestamp reported as semantically equivalent. Do not infer a safe apply order from this summary.

### Live-application gates and source-only status

- **20260929120000_onboarding_role_lock_and_provider_kind.sql remains blocked for production pending review.** Local SQL now includes role and completion guards to preserve the legacy client write shape; its completion trigger rejects true-to-false updates and validates true requests against required onboarding fields. This is source evidence only, not live validation. Prior audit evidence found old clients directly writing role/completion, and its backfill estimate would reopen 11 of 32 completed profiles. Verify rollout compatibility and review the 11/32 impact before live use; neither was refreshed here.
- The local SQL for `20260909101000_saved_portfolio_projects.sql` explicitly revokes table privileges from PUBLIC, anon, and authenticated, grants SELECT/INSERT/UPDATE/DELETE to authenticated, and checks both row ownership and `p.role = 'homeowner'` in its RLS policy. The prior audit reported this migration version absent; no live refresh occurred here, so these controls are not claimed as deployed.
- **Migration 5**, `20260929004741_contractor_contact_entitlement.sql`, changes the contact entitlement contract; the product must accept the narrower behavior before any live replacement.
- **Migration 3, 20260909100500_homeowner_brief_publish_fields.sql:** current client source carries a stable publish key in the persisted project draft and, on SQLSTATE 23505, looks up only the same homeowner_id/publish_key row, rethrowing if none exists. The prior audit reported the migration version absent. This retry support remains unverified for this snapshot; do not claim live idempotency.
- Reconcile the timestamped local files, live history, client compatibility, and full grants/policies against fresh evidence before any database action. No migration was applied for this task.

## Related guides

- Detailed engineering map: [AI_ONBOARDING.md](../AI_ONBOARDING.md)
- Product brief: [PRODUCT.md](../PRODUCT.md)
- Operator console: [admin/README.md](../admin/README.md)
- Media signer: [infra/media-signer/README.md](../infra/media-signer/README.md)
- Shipping: [docs/SHIPPING.md](SHIPPING.md)
- Go-live checklist: [docs/go-live-checklist.md](go-live-checklist.md). Its operational statements are not live evidence; refresh before acting.
