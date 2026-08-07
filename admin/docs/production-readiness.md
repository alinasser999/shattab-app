# Admin Production Readiness

## Ready in this pass

- No service-role key in the Admin source or environment contract.
- Middleware refreshes sessions but does not act as the authorization boundary.
- Admin reads use RLS and guarded database RPCs.
- Sensitive mutations use SECURITY DEFINER RPCs that check the current admin.
- Owner/moderator action authorization is now database-enforced.
- Destructive reasons and queue state transitions are database-enforced.
- Audit writes are append-only from the console perspective.
- Private verification and payment files use short-lived signed URLs.
- Server action redirects and displayed backend errors are constrained.
- Typecheck, contract audit, and production build pass.
- Read-only live checks confirmed anonymous RPC denial and the current deployed
  admin RPC guard pattern.

## Deployment checklist

- Apply `20260803035018_admin_hardening_report_contract.sql` to staging first.
- The connected project currently has two `owner` admin accounts and no
  `moderator` account; create a staging moderator deliberately before testing
  the restricted matrix.
- Run Supabase advisors and database lint against the reachable project.
- Execute the isolated permission and destructive-action tests in
  [test-matrix.md](test-matrix.md).
- Confirm at least one owner account and one moderator account exist in
  `admin_users`.
- Confirm the Admin environment has only the URL and anon/publishable key.
- Confirm no production destructive tests are used as fixtures.

## Operational gaps

- No queue metrics, traces, or correlation IDs are emitted by the Admin server.
- No alerting or incident dashboard is connected.
- No automated RLS test harness is committed yet.
- No server-side pagination exists for every large operational list.
- No admin-user management screen exists; bootstrap remains an external SQL
  operation by design.

## Live advisor snapshot

The connected project returned 26 security notices and 52 performance notices
on 2026-08-03. The important categories are:

- `admin_users` has RLS with no policy. This is intentional deny-by-default,
  but remains an informational advisor result.
- `pg_trgm` is installed in `public`; moving it requires an index/operator-class
  migration and should be tested separately.
- Authenticated-callable SECURITY DEFINER functions are reported. Admin RPCs
  must remain callable by the authenticated admin session, so their in-body
  `admin_require()` guard is the intentional control. The new migration also
  revokes the older queue helper RPCs that do not need to be public admin entry
  points.
- Leaked-password protection is an Auth dashboard setting, not a repository
  change; enable it before password-based operator access is considered ready.
- Performance notices include unindexed foreign keys, unused indexes, and
  multiple permissive policies. These need query plans and traffic evidence
  before changing indexes or merging policies.
