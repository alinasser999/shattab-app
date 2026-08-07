# Shattab Admin

Operations console for the Shattab marketplace. Next.js 15 (App Router), reading
the same Supabase project as the Flutter app.

## The one thing to understand

**This app holds no service-role key.** It authenticates as *you*, an ordinary
Supabase user, using the anon key. Every privilege comes from `public.is_admin()`
inside Postgres:

- read access is granted by `admin_read_all` RLS policies on 16 tables
- every privileged action is a `SECURITY DEFINER` RPC that starts with
  `admin_require()`
- every mutation writes a row to `admin_audit_log`, which no admin can edit or
  delete from the console

So a leaked build of this app grants nothing. If the middleware were deleted
outright, a non-admin reaching `/users` would still see nothing, because the
database refuses them independently. Middleware here is a signpost, not a gate.

## Setup

```bash
cp .env.local.example .env.local   # paste SUPABASE_URL and SUPABASE_ANON_KEY from ../.env
npm install
npm run dev                        # http://localhost:4321
```

## Creating an operator account

The console signs in with **email and password**, not phone OTP. The app keeps
phone OTP; an ops tool that needs an SMS to deliver costs money per login, breaks
during a provider outage, and is unusable from any machine that is not holding
your phone.

Two steps, both outside this app on purpose — the first admin has to come from
outside the system, or the system has a bootstrap hole.

1. Supabase dashboard → **Authentication → Users → Add user → Create new user**.
   Set an email and a strong password, and tick **Auto Confirm User** so no
   confirmation email is needed.

2. Grant it admin, in the SQL editor:

```sql
insert into public.admin_users (user_id, level)
select id, 'owner' from auth.users where email = 'you@example.com';
```

`handle_new_user()` creates the matching `profiles` row automatically, with
`role = 'homeowner'` and an empty phone. That role is irrelevant here: admin is a
separate table precisely so it is orthogonal to the app's product roles.

Signing in does not grant admin. An account that is not in `admin_users` reaches
the console and sees nothing, which is correct.

**Turn on leaked-password protection** once you are using passwords: dashboard →
Authentication → Policies. It checks new passwords against HaveIBeenPwned. The
security advisor flags it as disabled today.

## Pages

| Route | What it answers |
|---|---|
| `/` | How the app is doing: accounts, activity, the marketplace funnel, revenue, and what is waiting on you |
| `/users` | Who signed up. Search, filter, and a per-account panel with full history plus suspend / verify / plan controls |
| `/contractors` | The verification queue with signed document links, then the whole supply roster |
| `/moderation` | Open reports, the accounts users block most, and recent decisions |
| `/payments` | Manual transfers awaiting confirmation, and what has actually been collected |
| `/activity` | Every admin action ever taken, and who has been signing in |

## Conventions

- **Server components throughout.** The authenticated routes ship ~172 B of
  JavaScript each. The only client components are the login form and the sidebar
  (which needs the current pathname).
- **Filter state lives in the URL**, so any view can be bookmarked and shared.
- **Mutations are plain `<form action={serverAction}>`.** Outcomes come back as
  `?done=` / `?error=`, rendered by `OutcomeBanner`.
- **Destructive actions require a typed reason**, which lands in the audit log.
- Design tokens are in `app/globals.css`. Never hard-code a colour; the ink ramp
  is contrast-checked against the surfaces it sits on.

## Checks

```bash
npm run audit:contracts
npm run typecheck
npm run build
```

`npm run build` is the check that counts. `tsc --noEmit` alone will not catch an
illegal export from a route file, which is a real error this project already hit.

## Audit and production notes

The current audit, connectivity map, permission matrix, and staging test
matrix live in [`docs/`](docs/). The admin hardening migration is
`supabase/migrations/20260803035018_admin_hardening_report_contract.sql` in the
repository root. Apply it to staging before deploying the matching console
build; the new `owner`/`moderator` action guard is enforced by PostgreSQL.

## Deliberately not here

- **No service-role key**, per above.
- **No account deletion.** `0023_account_deletion.sql` is written but unapplied;
  deletion belongs in the app for store compliance, not in an admin tool.
- **Storage is not cleaned up when content is removed.** Removing a post keeps
  its media, so an appeal can still be reviewed. Purging is a separate,
  deliberate act.
