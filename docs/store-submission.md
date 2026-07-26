# Store submission checklist — Shattab

Status as of 2026-07-26. Ticked items are done in code and verified against the
live Supabase project. Unticked items need a human: a payment, a credential, or
an account only you can hold.

---

## Blocking — must be done before either store

### 1. Apply migration 0023 (account deletion) — **NOT DONE**

`supabase/migrations/0023_account_deletion.sql` is written and verified against
the live schema, but is **not applied**. Until it is, the Delete Account button
throws for every user, which is worse than not having one.

Paste the file into the Supabase SQL editor and run it. Verify:

```sql
select exists(
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'delete_my_account'
);
```

### 2. Upload keystore — **NOT DONE**

`android/app/build.gradle.kts` falls back to **debug signing** when
`android/key.properties` is absent, and it is absent. A debug-signed AAB is
rejected by Play.

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (already gitignored):

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

**Back the .jks file up somewhere you will not lose it.** Lose it and you cannot
ship an update to the same listing, ever.

### 3. Host the legal documents — **NOT DONE**

`docs/legal/privacy-policy.md` and `docs/legal/terms-of-service.md` are written
against the app's real schema. Two steps:

1. Replace every `{{PLACEHOLDER}}` — legal entity, address, support email,
   jurisdiction, refund policy, SMS provider, Sentry region.
2. Publish both at stable URLs, then update `_privacyPolicyUrl` and `_termsUrl`
   in `lib/features/shell/presentation/profile_screen.dart`. They currently
   point at `shattab.app/privacy` and `/terms`, which do not exist yet.

GitHub Pages is sufficient and free.

### 4. Supabase Pro — **deliberately deferred**

Not a store requirement, but the free tier auto-pauses after ~7 days of
inactivity, so the app dies on a quiet week. Pro also unlocks image
transformations (`SUPABASE_IMAGE_TRANSFORMS`, currently `false` — enabling it
without a paid plan 404s every photo) and point-in-time recovery.

---

## Google Play

- [x] In-app account deletion (Profile → Settings → Delete account) — code done, needs item 1
- [x] Report content and block users
- [x] Crash reporting (Sentry, PII off)
- [x] Only `INTERNET` requested in the manifest — nothing awkward to justify in Data Safety
- [ ] Upload keystore (item 2)
- [ ] Privacy policy URL (item 3)
- [ ] Data Safety form. Declare: phone number, name, photos, user content;
      collected and stored, not shared for advertising, not sold; deletion
      available in-app. Encrypted in transit.
- [ ] Target API level — check Play's current minimum at submission time
- [ ] Store listing: icon, feature graphic, at least 2 screenshots per form
      factor, short and full description, content rating questionnaire

Play accepts an **account deletion URL** as an alternative to the in-app path.
The in-app path exists, so declare that.

---

## Apple App Store

- [x] **Sign in with Apple** — guideline 4.8. Mandatory because Google sign-in
      is offered. Button, repository method and entitlement are in place
- [x] **Guideline 1.2 (UGC)**: report content, block users, and terms stating
      zero tolerance for objectionable content, with a stated 24-hour response
- [x] Account deletion — guideline 5.1.1(v). Code done, needs item 1
- [x] `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` present
      in `ios/Runner/Info.plist`, in Arabic
- [ ] Apple Developer Program membership (US$99/year)
- [ ] Enable **Sign in with Apple** for the App ID in the developer portal, add
      the capability to the Runner target in Xcode, and configure Apple as a
      provider in Supabase Auth. `ios/Runner/Runner.entitlements` declares the
      entitlement but does none of that on its own — **the button will fail
      silently until all three are done**
- [ ] EULA URL in App Store Connect (use the terms from item 3)
- [ ] Privacy nutrition labels — same categories as the Play Data Safety form
- [ ] Demo account for review. Reviewers cannot receive an Egyptian SMS, so
      supply a working phone-and-password login, or they will reject for being
      unable to sign in. This is the single most common rejection for
      phone-auth apps
- [ ] Age rating: 18+, consistent with the Terms

---

## Known gaps, not blocking

- No rate limit or CAPTCHA on OTP send. Every signup is a paid SMS, and
  SMS-pumping fraud can run the bill up with no real users.
- Discover still uses `OFFSET` pagination; the feed and briefs use keyset.
- `get_for_you_feed` computes `like_count` / `comment_count` per read instead
  of denormalised counters.
- `briefs` has three permissive SELECT policies that could be one.
- Verification and payment approvals are manual SQL-editor operations. Fine at
  ten contractors, not at a thousand.

---

## Verified in production

Migrations applied and confirmed against `ajqdutehxpbbflzdovhw`:
`0018` indexes · `0019` completion loop · `0020` brief edit/delete ·
`0021` admin RPC lockdown · `0022` RLS InitPlan · `0024` reports and blocks.

Security advisor: 21 findings → 7, and the remaining ones are intended
(`authenticated` must be able to call the app's own RPCs) or cosmetic.
