# Shattab Production Readiness

This document is the release contract for the Flutter app, shared Supabase
project, media signer, and Admin console. It deliberately separates checks we
can run from the repository from credentials and dashboard changes that need a
staging owner.

## Implemented in the app

- Signup role selection is persisted before onboarding starts; incomplete
  onboarding remains recoverable through the guarded router.
- Quotes, reviews, brief creation, post publishing, likes, saves, comments, and
  comment actions have in-flight guards so repeated taps do not create a
  duplicate write or race an optimistic rollback.
- Notifications use one role-aware destination mapper for inbox taps and FCM
  taps. Unknown or stale payloads fall back to the notification inbox.
- Realtime notifications remain the foreground source of truth. Push is a
  delivery enhancement and never replaces the database row.
- Network error surfaces retry when connectivity returns. Pagination failures
  preserve already loaded content and expose a retry action at the list footer.
- Public image uploads are resized/compressed before Supabase or R2 upload and
  stored as JPEG with a validated content type. Failed URLs use a branded
  placeholder instead of exposing a server error page.
- Analytics is privacy-safe and write-only from the client. Event names are
  lowercase snake case and properties must not contain phone numbers, names,
  free-text descriptions, or raw contact data.
- Analytics writes are protected by RLS, limited to the signed-in owner, and
  sanitized at the client boundary to a small bounded scalar allowlist.
- Account sign-out and deletion unregister the device token before clearing the
  session. A registration generation guard prevents an old account's token
  refresh callback from writing after an account switch.
- Community identity and comment RPCs are narrow public projections so guests
  can browse the community. Anonymous identity responses never include phone
  numbers; device-token updates require the current row owner.
- Like and comment-like tables are owner-readable only; public counts and
  current-user state come from the bounded feed/comment projections.
- Contractor catalogue reads use bounded, stable public projections. Phone is
  available only through the authenticated detail RPC after a profile is open;
  catalogue, saved-list, and community hydration paths do not select it.
- Contractor access to a homeowner phone is brief-scoped through
  `get_homeowner_contact_for_brief()`. A profile id alone cannot authorize a
  contact lookup.
- Discovery landing, search, nearby, all-professional, and top-rated shelves use
  server-side keyset cursors with deterministic tie-breakers. The old offset
  RPCs remain only for authenticated backward compatibility and are not used by
  the paginated UI.
- Saved-professional collections use the same bounded keyset approach, so a
  homeowner account does not silently download an unbounded saved list as it
  grows.
- Billing state is read through the authenticated `get_my_billing_state()` RPC.
  The approved contractor plan is authoritative; a pending payment request is
  never treated as an active Pro subscription, and repeated payment submission
  keeps its idempotency key.
- Verification request rows and private document uploads require the signed-in
  profile to have the contractor role; the client cannot create a homeowner
  verification queue entry.

## Repository checks

Run the full preflight from the repository root:

```powershell
pwsh -File tool/release_check.ps1
```

The script runs Riverpod generation, `flutter analyze`, Flutter tests, a web
release build, the Admin typecheck/contract audit/build, and the R2 media
signer's typecheck/tests. It also fails fast when `.env` is missing or contains
a service-role Supabase key.

For a store submission, run the stricter gate after adding private release
inputs locally:

```powershell
pwsh -File tool/release_credentials_check.ps1
pwsh -File tool/release_credentials_check.ps1 -RequirePublicMediaRollout
```

The strict gate requires native Firebase configuration and Android signing
inputs. The optional R2 flag additionally requires the signer URL, public
hostname, and at least one explicitly approved public category. None of these
secrets belong in Git or in the Flutter bundle.

## Staging gates still required

- Enable Supabase Phone Auth and verify the SMS provider can deliver to Egyptian
  `+20` numbers. Test OTP expiry, retry, rate limiting, and wrong-code states.
- Enable Supabase leaked-password protection. This is a dashboard Auth setting,
  not a client-code change.
- Add Firebase configuration for the real Android/iOS application ids, deploy
  the active `send-push` Edge Function, set its webhook secret and FCM
  service-account secrets, configure a database webhook for
  `public.notifications` INSERT with `x-push-secret`, then insert a staging
  notification and verify delivery on a locked device. The function is
  deployed, but push delivery remains disabled until these external values are
  configured.
- Configure Apple push credentials and Android release signing. Never commit
  `android/key.properties`, service-account JSON, or APNs keys.
- Run the auth, role, quote, completion, review, report, block, account-delete,
  R2 upload, and notification deep-link journeys on two physical devices.
- Test the Admin console with isolated owner and moderator accounts. Verify
  the database guard, audit entry, and rollback behavior for every destructive
  action.
- Run Supabase security/performance advisors against staging. Do not remove
  indexes or weaken RLS based only on an unused-index notice; use query plans
  and traffic evidence.
- Run `supabase test db --workdir supabase` against the disposable local or
  staging database after enabling the repository's pgTAP test dependency. The
  `supabase/tests/rls_regression.sql` contract covers payment, contact,
  verification, profile and interaction boundaries. It must not run against
  production from an untrusted pull request.
- Expected advisor exceptions are documented: the community identity/comments
  projections are intentionally public for guest browsing, while admin
  SECURITY DEFINER functions remain protected by their internal admin guard.
  Treat any new public definer, missing RLS policy, or leaked personal field as
  a release blocker.
- The public contractor catalogue projections are also intentional public
  definers: they return only contractor profile fields and explicitly omit
  phone/contact data. `get_contractor_contact` and billing state are
  authenticated-only. Review these exact signatures when advisors report a new
  public definer rather than suppressing the warning globally.
- R2 is code-integrated but opt-in, not yet a live production media path. Before enabling it, create the bucket and
  custom hostname, configure Worker secrets and CORS, deploy the Worker, run
  authenticated upload/finalize/delete/purge smoke tests, and only then set the
  Flutter R2 flag for approved public categories. Verification documents and
  payment proofs must remain in private Supabase Storage.

## Operational ownership

Before launch, assign an owner for Sentry alerts, Supabase billing/quotas,
push delivery failures, moderation queue response, backups/restore drills, and
support escalation. A polished empty or error state is not an incident plan;
the team needs a response path behind it.
