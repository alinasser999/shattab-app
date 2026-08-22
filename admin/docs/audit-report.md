# Shattab Admin Audit

Audit date: 2026-08-03

The connected Supabase project currently reports the existing `admin` and
`admin_rpc` migrations as its latest deployed migrations. The new hardening
migration in the repository is not applied to that project yet.

## Scope

This report covers the Next.js Admin console, the Flutter application data
contracts, and the Supabase migrations that define the admin boundary. It does
not claim a live production database or destructive browser journey was tested
without an isolated admin test account.

## Runtime map

```text
Browser
  -> Next proxy refreshes the Supabase auth cookie and redirects strangers
  -> Server Components / Server Actions
  -> @supabase/ssr client with the signed-in user's session and anon key
  -> Supabase RLS and SECURITY DEFINER RPCs
  -> The same public tables, storage buckets, and business rules used by Flutter
```

The browser never receives a service-role key. The proxy is a signpost only;
`is_admin()` and the admin RPC guards are the authorization boundary.

## Route inventory

| Route | Data and actions | Current result |
| --- | --- | --- |
| `/` | `admin_overview`, `admin_timeseries`, `admin_funnel`, recent signups/sign-ins | Real database metrics; loading is request-time and failures have an explicit state |
| `/users` | URL search/filter/page state, profile list, `admin_user_detail`, suspend/unsuspend, verify, plan | Working with server-side page windows; plan changes are owner-only after the hardening migration |
| `/contractors` | Verification queue, signed verification documents, roster, verify/unverify, verification review, plan filter | Working; queue and roster have bounded windows but not full pagination |
| `/moderation` | Pending/resolved reports, block aggregate, report decision actions | Report enum drift fixed; removal for posts/comments works, brief/review removal remains intentionally deferred until moderation state exists |
| `/payments` | Payment queue, signed proofs, payment history, collected payments, approve/reject | Working; billing mutations are owner-only after the hardening migration |
| `/activity` | Append-only audit log and recent sign-ins | Working; fixed-size window with no URL filters or pagination yet |
| `/api/signout` | POST-only Supabase sign-out | Working; GET sign-out is not exposed |
| `/login` | Email/password Supabase sign-in and same-origin return path | Working; return path is constrained and auth errors are generic |

## Findings fixed in this pass

### High: report contract drift

The Flutter app and `content_reports.target_type` use `profile`, `offensive`,
`sexual`, and `violence`. The Admin UI previously used `user`, `harassment`,
and `nudity`, and the account report count queried the wrong target type. The
labels and account read model now match the shared contract.

### High: action authorization was only admin-wide

The existing schema had `owner` and `moderator` levels, but every admin RPC only
checked `is_admin()`. The new migration adds an internal action guard. Moderators
can operate moderation and verification workflows; billing and manual Pro
changes require owner access. The UI also explains the owner-only state.

### High: destructive reason checks were UI-only

Forged RPC calls could omit a reason even though the forms asked for one. The
new database functions require bounded reasons for suspension, rejection, post
removal, and report actioning. State transitions also reject already-reviewed
queue rows.

### Medium: server-action redirect trust

Hidden `path` fields are client-controlled. Server actions now use an exact
allowlist before `revalidatePath` or redirecting, eliminating the accidental
open-redirect surface.

### Medium: raw backend errors in the UI

PostgREST and database error messages can contain implementation details. Error
states now show safe operator copy instead of raw SQL/RPC details, and action
errors are mapped to safe messages.

## Findings not yet fixed

- Live RLS and Supabase advisor checks need a reachable project or local Postgres.
- Large queues use bounded windows rather than URL-persisted pagination.
- Block aggregation now runs in the database through `admin_most_blocked`, with
  deterministic ordering and a bounded operator-controlled limit.
- Brief and review moderation need explicit hide/invalidate states before the
  console offers a destructive content action for them.
- Admin audit rows have no correlation ID or actor IP/session context yet.
- Notifications, exports, system health, admin-user management, and feature
  flags are not present because the current schema has no safe connected model
  for them.
