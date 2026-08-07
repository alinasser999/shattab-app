# Media Storage Architecture

Shattab keeps Supabase as the system of record for authentication, PostgreSQL,
RLS, RPCs, and all marketplace state. Cloudflare R2 is an optional delivery
provider for explicitly approved public media only.

## Current boundary

| Category | Default provider | Visibility decision |
| --- | --- | --- |
| Avatars | Supabase Storage | Public in the checked-in policy; R2 can be enabled explicitly |
| Contractor logos | Supabase Storage | Public in the checked-in policy; R2 can be enabled explicitly |
| Community post media | Supabase Storage | Public in the checked-in policy; R2 can be enabled explicitly |
| Portfolio photos | Supabase Storage | Existing app treats these as public URLs; R2 requires explicit rollout configuration |
| Brief photos | Supabase Storage | Kept here until the current live bucket/privacy contract is verified |
| Verification documents | Supabase Storage | Private; never sent to public R2 |
| Payment proofs | Supabase Storage | Private; never sent to public R2 |

No existing Supabase objects are migrated or deleted by this change.

## Flutter flow

The feature repositories continue returning URL strings. They now depend on
`MediaStorageService`, which routes an upload to R2 only when all of the
following are true:

1. `R2_PUBLIC_MEDIA_ENABLED=true`.
2. `R2_SIGNER_URL` is configured.
3. `R2_PUBLIC_BASE_URL` is configured.
4. The category is present in `R2_PUBLIC_MEDIA_CATEGORIES`.
5. The category is in the public allowlist.

If the signer cannot be reached before an upload URL is issued, the router
falls back to Supabase. If an R2 upload has started and fails, the error is
returned rather than pretending the upload succeeded.

## Worker security boundary

`infra/media-signer` verifies the Supabase access token through Supabase Auth,
derives the user id from that verified session, validates the media category,
content type, and size, and creates a short-lived R2 PUT URL. R2 credentials
exist only as Worker secrets.

The Worker accepts only:

- `avatars`
- `contractor-logos`
- `post-media`
- `portfolio-photos`

Every object is namespaced under `public/{category}/{userId}/`. Delete and
account-purge requests require ownership of that namespace.

## Account deletion

The existing `delete_my_account` RPC continues to remove Supabase-owned files.
When R2 is enabled, the app first asks the authenticated Worker to purge the
current user's public R2 namespace. If that purge fails, the irreversible
Supabase deletion RPC is not called.

## Rollout

Keep the following values empty/disabled until a non-production bucket has been
tested:

```text
R2_PUBLIC_MEDIA_ENABLED=false
R2_SIGNER_URL=
R2_PUBLIC_BASE_URL=
R2_PUBLIC_MEDIA_CATEGORIES=
```

Enable one category at a time, beginning with public post media or portfolio
photos, and verify old Supabase URLs before enabling account deletion purge in
production.

Do not place R2 access keys, Worker secrets, Firebase private keys, or Supabase
service-role keys in Flutter `.env` files.
