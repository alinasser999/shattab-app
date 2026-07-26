-- 0021_admin_rpc_lockdown — close a live privilege-escalation hole.
--
-- 0014 and 0015 both end with:
--     revoke all on function public.approve_verification_request(uuid) from public;
-- and their comments claim this means "no client can self-verify". It does not.
--
-- Supabase ships with
--     alter default privileges in schema public
--       grant all on functions to anon, authenticated, service_role;
-- so every new function receives *direct* grants to `anon` and `authenticated`,
-- separate from the PUBLIC pseudo-role. Revoking PUBLIC leaves those intact, and
-- the database linter confirms all four admin functions were reachable at
-- /rest/v1/rpc/... by anonymous callers.
--
-- Exploit that worked before this migration:
--   1. sign up as a contractor
--   2. insert a verification_requests row (allowed by vr_insert_own)
--   3. read its id back (allowed by vr_read_own)
--   4. POST /rest/v1/rpc/approve_verification_request {"p_request": "<id>"}
--      -> contractor_profiles.verified = true
-- Same shape against payment_requests granted a free Pro subscription.
--
-- Two independent layers below, because either alone is fragile: the grants are
-- corrected, AND each body refuses client callers. The in-body guard is what
-- survives a future `create or replace` silently picking the default privileges
-- back up — which is exactly how this happened in the first place.

-- ── layer 2: in-body guard ───────────────────────────────────────────────────
-- `request.jwt.claims` is unset in the SQL editor (NULL -> guard passes) and
-- carries role 'anon' or 'authenticated' on every client path. The service_role
-- key reports 'service_role', so founder tooling keeps working unchanged.
-- nullif() guards against an empty setting, which would fail the ::jsonb cast.

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
     ) in ('anon', 'authenticated') then
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

create or replace function public.reject_verification_request(p_request uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(
       nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
       ''
     ) in ('anon', 'authenticated') then
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
     ) in ('anon', 'authenticated') then
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

create or replace function public.reject_payment_request(p_request uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(
       nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
       ''
     ) in ('anon', 'authenticated') then
    raise exception 'not_authorized';
  end if;

  update public.payment_requests
    set status = 'rejected', reject_reason = p_reason, reviewed_at = now()
    where id = p_request and status = 'pending';
end;
$$;

-- ── layer 1: revoke from the roles that actually hold the grant ──────────────
-- Must come after the create-or-replace above: replacing a function re-applies
-- the schema default privileges.

revoke execute on function public.approve_verification_request(uuid) from anon, authenticated;
revoke execute on function public.reject_verification_request(uuid, text) from anon, authenticated;
revoke execute on function public.approve_payment_request(uuid) from anon, authenticated;
revoke execute on function public.reject_payment_request(uuid, text) from anon, authenticated;

-- ── same class of problem: internals exposed as REST endpoints ───────────────
-- A trigger function and a rate-limit helper have no business being callable
-- over /rest/v1/rpc. tg_reviews_rollup is SECURITY DEFINER, so this one matters.

-- `from public` matters here as well as the direct role grants: unlike the four
-- admin functions, these two were never revoked from PUBLIC, and
-- has_function_privilege() resolves through any path — dropping only the direct
-- anon/authenticated grants left them still reachable. Verified after applying.
revoke execute on function public.tg_reviews_rollup() from public, anon, authenticated;
revoke execute on function public.check_comment_rate_limit(uuid) from public, anon, authenticated;

-- accept_quote (0009/0016) guards on briefs.homeowner_id = auth.uid(), so anon
-- already failed with 'not_authorized'. Make that a permission boundary rather
-- than a consequence of a null uid. `authenticated` keeps it: this is the
-- homeowner's accept action.
revoke execute on function public.accept_quote(uuid) from public, anon;
grant execute on function public.accept_quote(uuid) to authenticated;

-- ── pin search_path on the functions still missing it ────────────────────────
-- A mutable search_path on a SECURITY DEFINER function lets a caller who can
-- create objects shadow an unqualified reference inside the body. ALTER rather
-- than CREATE OR REPLACE so the bodies are not restated (and cannot drift).
-- get_for_you_feed and tg_block_selfupgrade are not definers, so for them this
-- is linter hygiene rather than a fix; both are cheap to align.

alter function public.tg_reviews_rollup() set search_path = public;
alter function public.check_comment_rate_limit(uuid) set search_path = public;
alter function public.tg_block_selfupgrade() set search_path = public;
alter function public.get_for_you_feed(uuid, integer, timestamptz, uuid)
  set search_path = public;

-- ── stop clients enumerating the post-media bucket ───────────────────────────
-- post_media_select_all granted SELECT on storage.objects for the whole bucket,
-- which lets any client list every file in it. Public buckets do not need this:
-- object reads go through /storage/v1/object/public/... which bypasses RLS, and
-- the app only ever calls uploadBinary() and getPublicUrl()
-- (lib/features/explore/data/post_repository.dart:241-242).

drop policy if exists "post_media_select_all" on storage.objects;
