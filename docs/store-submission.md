# Store Submission Checklist - Shattab

Status as of 2026-08-14. Items marked done are implemented in code and
verified against the live Supabase project where noted. Remaining unchecked
items require release credentials, dashboard access, legal decisions, or
physical-device testing.

## Blocking Before Store Submission

### Account deletion

The `delete_my_account()` RPC is applied to the live project through the
`consumer_account_deletion` migration. The client keeps the destructive action
behind an explicit confirmation flow and unregisters the device token first.
Run the journey on a staging account before submission; never use a real
account for this test.

Verify the function exists before the store build:

```sql
select exists(
  select 1 from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'delete_my_account'
);
```

### Android signing

The release build needs a private upload keystore and `android/key.properties`.
Keep both outside Git and back up the keystore securely. A debug-signed bundle
will be rejected by Google Play.

### Legal documents

Replace every placeholder in `docs/legal/privacy-policy.md` and
`docs/legal/terms-of-service.md`, publish both at stable URLs, and update the
URLs used by the app. Verify the pages from a logged-out mobile browser.

### Required dashboard and credential work

- Enable Supabase Phone Auth and verify Egyptian `+20` OTP delivery, expiry,
  retry, rate limiting, and wrong-code states.
- Enable Supabase leaked-password protection.
- Configure Firebase for the real Android/iOS application IDs.
- Configure the deployed `send-push` Edge Function with its webhook secret and
  FCM service-account secrets, then test a notification on a locked device.
- Configure Apple push credentials, Android release signing, and Sign in with
  Apple in the developer portal, Xcode, and Supabase Auth.
- Assign an owner for Sentry alerts, Supabase billing, push failures,
  moderation response, backups, and support escalation.

## Implemented Product Hardening

- Signup role selection persists before onboarding starts.
- Quotes, reviews, briefs, posts, likes, saves, comments, and comment actions
  guard against duplicate in-flight writes.
- Notifications use one role-aware destination mapper with safe inbox fallback.
- Realtime notifications remain the foreground source of truth; push is a
  delivery enhancement.
- Public contractor catalogue and saved-professional projections omit phone
  and operational response-rate fields.
- Phone/contact access is restricted to the authenticated profile-detail RPC.
- Billing state and payment submission are server-owned; payment proof is
  required and verified in private storage.
- Discovery landing/search, nearby, all-professional, and top-rated collections
  use stable keyset pagination with deterministic tie-breakers. Legacy offset
  RPCs remain only for backward-compatible detail reads.
- Public image uploads validate size/type, resize and compress before upload,
  and use a safe branded placeholder for failed URLs.
- Account sign-out and deletion unregister device tokens before clearing the
  session.
- Analytics is write-only, bounded, and excludes phone numbers, names, free
  text, and contact data.
- R2 is code-integrated but opt-in, not a live production media path. Private
  verification documents and payment proofs remain in private Supabase Storage.

## Store Forms

### Google Play

- [x] In-app account deletion path and live deletion RPC
- [x] Report content and block users
- [x] Crash reporting with PII disabled
- [ ] Upload keystore and signed AAB
- [ ] Privacy policy URL
- [ ] Data Safety form: phone number, name, photos, user content; stored,
      encrypted in transit, not sold or used for advertising
- [ ] Target API level check at submission time
- [ ] Store icon, feature graphic, screenshots, descriptions, and content rating

### Apple App Store

- [x] Sign in with Apple implementation and entitlement files
- [x] UGC report/block flows and moderation terms
- [x] Account deletion path and live deletion RPC
- [x] Camera and photo-library usage descriptions
- [ ] Apple Developer membership and portal configuration
- [ ] EULA and privacy URLs in App Store Connect
- [ ] Privacy nutrition labels
- [ ] Review demo account that does not depend on receiving an Egyptian SMS
- [ ] Age rating

## Known Follow-ups

- OTP abuse protection still needs a server/provider-level rate-limit or CAPTCHA
  policy; client debounce is not a security boundary.
- Feed counters are computed during reads and should be denormalized if feed
  volume makes the query plan expensive.
- Verification and payment approvals remain manual workflows and need an
  operator queue before supply grows materially.
- Remaining RLS advisor warnings must be reviewed against staging traffic and
  policy tests, not suppressed globally.

## Verification Commands

```powershell
pwsh -File tool/release_check.ps1
pwsh -File tool/release_credentials_check.ps1
pwsh -File tool/release_credentials_check.ps1 -RequirePublicMediaRollout
```

The strict credential gates are intentionally expected to fail until private
release inputs and external services are configured.
