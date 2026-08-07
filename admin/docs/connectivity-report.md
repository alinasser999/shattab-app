# Admin Connectivity Report

## Supabase client

The Admin console uses `createServerClient` from `@supabase/ssr` with
`NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`. The server client
reads and refreshes the signed-in user's cookies. There is no service-role
client, server secret, or privileged API route.

## Tables used by the console

The dashboard reads the shared public tables through RLS or admin RPCs:

- `profiles`, `homeowner_profiles`, `contractor_profiles`
- `briefs`, `quotes`, `reviews`, `portfolio_projects`
- `posts`, `post_comments`, `post_likes`
- `verification_requests`, `payment_requests`, `payments`
- `content_reports`, `user_blocks`, `saved_contractors`
- `admin_audit_log`

Auth-only metrics and sign-in history come from `auth.users` and
`auth.sessions` inside guarded SECURITY DEFINER read RPCs.

## Storage

- `verification-docs`: private; the Admin console creates five-minute signed
  URLs after the database has allowed the admin read.
- `payment-proofs`: private; the console uses the same five-minute signed URL
  pattern.
- `avatars`, `contractor-logos`, and `post-media`: public application media;
  the console does not add a cleanup path when content is removed, preserving
  evidence for appeals.

## Edge Functions and Realtime

No Admin page currently calls an Edge Function or subscribes to Realtime. The
console uses request-time reads and explicit refresh navigation after mutation.
That is consistent with the current schema, but it means queue freshness is
bounded by page refresh rather than push events.

## Shared contract verification

The Flutter moderation repository writes the exact `content_reports` target and
reason enum values defined in `0024_reports_and_blocks.sql`. The Admin labels,
account report aggregate, and report decision RPC now use those same values.

The connected project was inspected read-only on 2026-08-03. Its deployed
admin RPCs all contain the `admin_require()` guard, anonymous access to
`admin_overview()` returned HTTP 401, and the deployed migration list currently
ends at the existing `admin_rpc` migration. No live mutation was run.
