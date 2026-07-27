-- 0027_admin
-- Foundation for the Shattab admin console.
--
-- Design notes:
--  * Admin is NOT a value of profiles.role. That column has a CHECK allowing
--    only 'homeowner' | 'contractor' and it drives role-aware routing in the
--    app; adding a third value would leak a privilege concern into every route
--    guard. Admin lives in its own table.
--  * The console runs on the ANON key with the admin's own session. Every
--    privilege therefore has to be enforced here, in the database, not in the
--    web app. A compromised or buggy console leaks nothing it wasn't granted.
--  * Every admin mutation writes to admin_audit_log. A privilege surface with
--    no record of who used it is not auditable, and "who blocked this user?"
--    is the first question anyone asks.
-- Idempotent.

-- ─────────────────────────────────────────────────────────────
-- 1. Who is an admin
-- ─────────────────────────────────────────────────────────────

create table if not exists public.admin_users (
  user_id    uuid primary key references public.profiles(id) on delete cascade,
  level      text not null default 'moderator'
             check (level in ('owner', 'moderator')),
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
-- Deliberately zero policies: RLS-enabled with no policy denies every client
-- read and write. The table is only ever read by the SECURITY DEFINER helpers
-- below, which bypass RLS. Admins are added from the SQL editor.

-- Zero-argument on purpose. An is_admin(uuid) overload would let any caller ask
-- "is this user an admin?" about anyone whose id they hold — an enumeration
-- oracle for the highest-value accounts in the system. Reading auth.uid()
-- internally makes the question unanswerable about anyone but yourself.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users a where a.user_id = (select auth.uid())
  );
$$;

-- `revoke from anon` alone is not enough: PostgreSQL grants EXECUTE to PUBLIC on
-- every new function, and has_function_privilege() resolves through any path,
-- PUBLIC included. Revoke PUBLIC first, then grant the one role that needs it.
-- Only `authenticated` does — the admin_read_all policies below are declared
-- `to authenticated`, so anon never evaluates them.
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- ─────────────────────────────────────────────────────────────
-- 2. Audit log
-- ─────────────────────────────────────────────────────────────

create table if not exists public.admin_audit_log (
  id           bigserial primary key,
  actor_id     uuid not null references public.profiles(id),
  action       text not null,
  target_table text,
  target_id    uuid,
  meta         jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);

create index if not exists admin_audit_log_created_idx
  on public.admin_audit_log(created_at desc);
create index if not exists admin_audit_log_target_idx
  on public.admin_audit_log(target_id);

alter table public.admin_audit_log enable row level security;

drop policy if exists "audit_read_admin" on public.admin_audit_log;
create policy "audit_read_admin" on public.admin_audit_log
  for select to authenticated using (public.is_admin());
-- No insert/update/delete policy. The log is append-only from the client's
-- point of view: only admin_log() below writes to it, and it bypasses RLS.
-- An admin who can edit the record of their own actions has no audit trail.

create or replace function public.admin_log(
  p_action text,
  p_table  text,
  p_target uuid,
  p_meta   jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.admin_audit_log (actor_id, action, target_table, target_id, meta)
  values ((select auth.uid()), p_action, p_table, p_target, coalesce(p_meta, '{}'::jsonb));
$$;

-- Internal helper only. The admin RPCs run as the function owner and reach it
-- through the owner's own privileges, so no client grant is needed. Revoke
-- AFTER create-or-replace: replacing a function re-applies the schema default
-- privileges, which on Supabase grant EXECUTE to anon and authenticated.
revoke execute on function public.admin_log(text, text, uuid, jsonb)
  from public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 3. Suspension
-- ─────────────────────────────────────────────────────────────

alter table public.profiles
  add column if not exists suspended_at timestamptz;
alter table public.profiles
  add column if not exists suspended_reason text;

create index if not exists profiles_suspended_idx
  on public.profiles(suspended_at) where suspended_at is not null;

create or replace function public.is_suspended()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.suspended_at is not null
  );
$$;
-- Same PUBLIC caveat as is_admin(). Only tg_block_selfupgrade() evaluates a
-- helper as the caller; the suspension triggers are SECURITY DEFINER and reach
-- is_suspended() through the owner's own privileges.
revoke execute on function public.is_suspended() from public, anon;
grant execute on function public.is_suspended() to authenticated;

-- A user must not be able to lift their own suspension. The profiles update
-- policy lets a user write their own row, so the guard belongs in a trigger,
-- mirroring tg_block_selfupgrade() on the billing columns.
create or replace function public.tg_block_self_suspend()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Only police requests that arrive through PostgREST as anon/authenticated.
  -- A service-role call or a SQL-editor session has no such claim and is
  -- trusted; without this check the founder could not suspend anyone by hand.
  if coalesce(
       nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
       ''
     ) in ('anon', 'authenticated')
     and not public.is_admin() then
    new.suspended_at     := old.suspended_at;
    new.suspended_reason := old.suspended_reason;
  end if;
  return new;
end;
$$;
revoke execute on function public.tg_block_self_suspend()
  from public, anon, authenticated;

drop trigger if exists block_self_suspend on public.profiles;
create trigger block_self_suspend
  before update on public.profiles
  for each row execute function public.tg_block_self_suspend();

-- Enforcement. Implemented as BEFORE INSERT triggers rather than by editing the
-- existing write policies: those predicates carry the Pro-plan gate (0025) and
-- the comment rate limit (0024), and rewriting them to append one condition is
-- precisely how a subtle regression gets shipped. A trigger composes instead.
create or replace function public.tg_reject_if_suspended()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_suspended() then
    raise exception 'account_suspended' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke execute on function public.tg_reject_if_suspended()
  from public, anon, authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['posts', 'post_comments', 'quotes', 'briefs', 'reviews']
  loop
    execute format('drop trigger if exists reject_if_suspended on public.%I', t);
    execute format(
      'create trigger reject_if_suspended before insert on public.%I
         for each row execute function public.tg_reject_if_suspended()', t);
  end loop;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- 4. Admin read access
-- ─────────────────────────────────────────────────────────────
-- Permissive SELECT policies OR with the existing ones, so nothing a normal
-- user can already see changes. Policies rather than a wall of bespoke
-- read RPCs: the console can then filter, sort and paginate through PostgREST
-- without a migration per query.

do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'contractor_profiles', 'homeowner_profiles',
    'briefs', 'quotes', 'reviews', 'posts', 'post_comments', 'post_likes',
    'content_reports', 'verification_requests', 'payment_requests', 'payments',
    'user_blocks', 'saved_contractors', 'portfolio_projects'
  ]
  loop
    execute format('drop policy if exists "admin_read_all" on public.%I', t);
    execute format(
      'create policy "admin_read_all" on public.%I
         for select to authenticated using (public.is_admin())', t);
  end loop;
end;
$$;

-- Verification documents live in a private bucket that only the owning
-- contractor can read. An admin reviewing a request has to see them.
drop policy if exists "vd_read_admin" on storage.objects;
create policy "vd_read_admin" on storage.objects
  for select to authenticated
  using (bucket_id = 'verification-docs' and public.is_admin());

-- Payment proof screenshots, same reasoning.
drop policy if exists "pp_read_admin" on storage.objects;
create policy "pp_read_admin" on storage.objects
  for select to authenticated
  using (bucket_id = 'payment-proofs' and public.is_admin());

-- ─────────────────────────────────────────────────────────────
-- 5. Re-gate the existing admin RPCs
-- ─────────────────────────────────────────────────────────────
-- 0021 locked these to the service role by rejecting any anon/authenticated
-- JWT, which was right when the only admin was a SQL-editor session. The
-- console calls them with a real user session, so the guard now has to admit a
-- verified admin. Bodies are reproduced verbatim from the live definitions;
-- the ONLY change is `and not public.is_admin()` on the guard.

-- Re-gating the functions alone is not enough. tg_block_selfupgrade() raises
-- unless auth.role() = 'service_role', and SECURITY DEFINER changes the
-- executing role, not the JWT claim that trigger reads — so an admin session
-- calling approve_payment_request() would still die on "billing fields are not
-- user-writable". Body verbatim from the live definition; the only change is
-- the added is_admin() exemption.
create or replace function public.tg_block_selfupgrade()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.role() <> 'service_role' and not public.is_admin() then
    if new.plan            is distinct from old.plan
    or new.plan_expires_at is distinct from old.plan_expires_at
    or new.sponsored_until is distinct from old.sponsored_until
    or new.boost_until     is distinct from old.boost_until
    or new.verified        is distinct from old.verified then
      raise exception 'billing fields are not user-writable';
    end if;
  end if;
  return new;
end;
$$;
-- Trigger functions have no business being callable over /rest/v1/rpc. This one
-- was never revoked, and create-or-replace above re-applied the schema defaults.
revoke execute on function public.tg_block_selfupgrade() from public, anon, authenticated;

create or replace function public.approve_verification_request(p_request uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.verification_requests;
begin
  if coalesce(
       nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
       ''
     ) in ('anon', 'authenticated')
     and not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  select * into r from public.verification_requests where id = p_request for update;
  if r.id is null then
    raise exception 'verification request % not found', p_request;
  end if;
  if r.status <> 'pending' then
    raise exception 'verification request % already %', p_request, r.status;
  end if;

  update public.contractor_profiles
    set verified = true
    where profile_id = r.contractor_id;

  update public.verification_requests
    set status = 'approved', reviewed_at = now() where id = p_request;
end;
$$;

create or replace function public.reject_verification_request(
  p_request uuid, p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(
       nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
       ''
     ) in ('anon', 'authenticated')
     and not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  update public.verification_requests
    set status = 'rejected', reject_reason = p_reason, reviewed_at = now()
    where id = p_request and status = 'pending';
end;
$$;

create or replace function public.approve_payment_request(p_request uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.payment_requests;
  v_start timestamptz := now();
  v_end timestamptz;
begin
  if coalesce(
       nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
       ''
     ) in ('anon', 'authenticated')
     and not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  select * into r from public.payment_requests where id = p_request for update;
  if r.id is null then
    raise exception 'payment request % not found', p_request;
  end if;
  if r.status <> 'pending' then
    raise exception 'payment request % already %', p_request, r.status;
  end if;

  insert into public.payments (contractor_id, provider, provider_ref,
      amount_piastres, currency, purpose, status, period_start, period_end)
  values (r.contractor_id, r.method, 'pr_' || r.id::text, r.amount_egp * 100,
      'EGP', r.purpose, 'paid', v_start, null);

  if r.purpose = 'pro' then
    v_end := case when r.plan_term = 'annual'
                  then v_start + interval '1 year'
                  else v_start + interval '1 month' end;
    update public.contractor_profiles
      set plan = 'pro', plan_expires_at = v_end
      where profile_id = r.contractor_id;
    update public.payments set period_end = v_end
      where provider_ref = 'pr_' || r.id::text;
  elsif r.purpose = 'sponsored' then
    update public.contractor_profiles
      set sponsored_until =
          greatest(coalesce(sponsored_until, v_start), v_start) + interval '7 days'
      where profile_id = r.contractor_id;
  elsif r.purpose = 'boost' then
    update public.contractor_profiles
      set boost_until =
          greatest(coalesce(boost_until, v_start), v_start) + interval '7 days'
      where profile_id = r.contractor_id;
  end if;

  update public.payment_requests
    set status = 'approved', reviewed_at = now() where id = p_request;
end;
$$;

create or replace function public.reject_payment_request(
  p_request uuid, p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(
       nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
       ''
     ) in ('anon', 'authenticated')
     and not public.is_admin() then
    raise exception 'not_authorized';
  end if;

  update public.payment_requests
    set status = 'rejected', reject_reason = p_reason, reviewed_at = now()
    where id = p_request and status = 'pending';
end;
$$;

-- These four stay revoked from anon. `authenticated` needs EXECUTE for an admin
-- session to reach them at all; the in-body guard is what stops everyone else.
-- Revoke/grant must follow create-or-replace, which re-applies the Supabase
-- schema default privileges.
revoke execute on function public.approve_verification_request(uuid) from public, anon;
revoke execute on function public.reject_verification_request(uuid, text) from public, anon;
revoke execute on function public.approve_payment_request(uuid) from public, anon;
revoke execute on function public.reject_payment_request(uuid, text) from public, anon;

grant execute on function public.approve_verification_request(uuid) to authenticated;
grant execute on function public.reject_verification_request(uuid, text) to authenticated;
grant execute on function public.approve_payment_request(uuid) to authenticated;
grant execute on function public.reject_payment_request(uuid, text) to authenticated;
