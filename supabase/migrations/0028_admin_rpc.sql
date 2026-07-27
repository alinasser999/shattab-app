-- 0028_admin_rpc
-- Read models and privileged actions for the admin console.
-- Depends on 0027_admin (is_admin, admin_log, profiles.suspended_at).
--
-- Every function here is SECURITY DEFINER and starts with admin_require().
-- SECURITY DEFINER without a guard is a public backdoor; the guard is the
-- entire access control story for this file.
--
-- Every mutating function calls admin_log(). Reads are not logged: they are
-- high-volume and low-consequence, and a log nobody can scan is not a control.
-- Idempotent.

create or replace function public.admin_require()
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
end;
$$;
revoke execute on function public.admin_require() from public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- Read models
-- ─────────────────────────────────────────────────────────────

-- One round trip for the whole overview page. Twenty-odd correlated counts is
-- still one query plan and one network hop; twenty PostgREST calls is not.
create or replace function public.admin_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v jsonb;
begin
  perform public.admin_require();

  select jsonb_build_object(
    'users', jsonb_build_object(
      'total',       (select count(*) from public.profiles),
      'homeowners',  (select count(*) from public.profiles where role = 'homeowner'),
      'contractors', (select count(*) from public.profiles where role = 'contractor'),
      'onboarded',   (select count(*) from public.profiles where onboarding_complete),
      'suspended',   (select count(*) from public.profiles where suspended_at is not null),
      'new_7d',      (select count(*) from public.profiles
                       where created_at > now() - interval '7 days'),
      -- The 7-day window immediately before the current one, so the console can
      -- show a real change instead of a number with no baseline.
      'prev_7d',     (select count(*) from public.profiles
                       where created_at > now() - interval '14 days'
                         and created_at <= now() - interval '7 days'),
      'new_30d',     (select count(*) from public.profiles
                       where created_at > now() - interval '30 days'),
      'active_7d',   (select count(*) from auth.users
                       where last_sign_in_at > now() - interval '7 days'),
      'active_30d',  (select count(*) from auth.users
                       where last_sign_in_at > now() - interval '30 days')
    ),
    'supply', jsonb_build_object(
      'verified',       (select count(*) from public.contractor_profiles where verified),
      'pro',            (select count(*) from public.contractor_profiles
                          where plan = 'pro' and plan_expires_at > now()),
      'with_portfolio', (select count(distinct contractor_id) from public.portfolio_projects),
      'quoting_7d',     (select count(distinct contractor_id) from public.quotes
                          where created_at > now() - interval '7 days')
    ),
    'demand', jsonb_build_object(
      'briefs',      (select count(*) from public.briefs),
      'briefs_open', (select count(*) from public.briefs where status = 'open'),
      'briefs_7d',   (select count(*) from public.briefs
                       where created_at > now() - interval '7 days'),
      'quotes',      (select count(*) from public.quotes),
      'quotes_7d',   (select count(*) from public.quotes
                       where created_at > now() - interval '7 days'),
      'accepted',    (select count(*) from public.quotes where status = 'accepted'),
      'completed',   (select count(*) from public.briefs where completed_at is not null)
    ),
    'content', jsonb_build_object(
      'posts',      (select count(*) from public.posts),
      'posts_7d',   (select count(*) from public.posts
                      where created_at > now() - interval '7 days'),
      'comments',   (select count(*) from public.post_comments),
      'reviews',    (select count(*) from public.reviews),
      'rating_avg', (select round(avg(rating)::numeric, 2) from public.reviews)
    ),
    'queues', jsonb_build_object(
      'verification', (select count(*) from public.verification_requests where status = 'pending'),
      'payment',      (select count(*) from public.payment_requests where status = 'pending'),
      'reports',      (select count(*) from public.content_reports where status = 'pending')
    ),
    'revenue', jsonb_build_object(
      'egp_total', (select coalesce(sum(amount_piastres), 0) / 100 from public.payments
                     where status = 'paid'),
      'egp_30d',   (select coalesce(sum(amount_piastres), 0) / 100 from public.payments
                     where status = 'paid' and created_at > now() - interval '30 days')
    )
  ) into v;

  return v;
end;
$$;

-- Daily activity. generate_series is the left side so days with no activity
-- come back as zeros; without it the chart silently closes gaps and a dead
-- week looks like a busy one.
create or replace function public.admin_timeseries(p_days int default 30)
returns table (
  day      date,
  signups  bigint,
  briefs   bigint,
  quotes   bigint,
  posts    bigint,
  signins  bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.admin_require();

  return query
  with d as (
    select generate_series(
      (current_date - (greatest(least(p_days, 365), 1) - 1))::date,
      current_date,
      interval '1 day'
    )::date as day
  )
  select
    d.day,
    (select count(*) from public.profiles p
      where p.created_at >= d.day and p.created_at < d.day + 1),
    (select count(*) from public.briefs b
      where b.created_at >= d.day and b.created_at < d.day + 1),
    (select count(*) from public.quotes q
      where q.created_at >= d.day and q.created_at < d.day + 1),
    (select count(*) from public.posts po
      where po.created_at >= d.day and po.created_at < d.day + 1),
    (select count(*) from auth.users u
      where u.last_sign_in_at >= d.day and u.last_sign_in_at < d.day + 1)
  from d
  order by d.day;
end;
$$;

-- Marketplace funnel. Each step counts distinct briefs so the numbers are
-- monotonically decreasing and the drop-off is readable.
create or replace function public.admin_funnel()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v jsonb;
begin
  perform public.admin_require();

  select jsonb_build_object(
    'homeowners',        (select count(*) from public.profiles where role = 'homeowner'),
    'posted_brief',      (select count(distinct homeowner_id) from public.briefs),
    'briefs',            (select count(*) from public.briefs),
    'briefs_quoted',     (select count(distinct brief_id) from public.quotes),
    'briefs_accepted',   (select count(distinct brief_id) from public.quotes
                           where status = 'accepted'),
    'briefs_completed',  (select count(*) from public.briefs where completed_at is not null),
    'briefs_reviewed',   (select count(distinct brief_id) from public.reviews),
    'contractors',       (select count(*) from public.profiles where role = 'contractor'),
    'contractors_quoted',(select count(distinct contractor_id) from public.quotes),
    'contractors_hired', (select count(distinct contractor_id) from public.quotes
                           where status = 'accepted')
  ) into v;

  return v;
end;
$$;

-- Who signed up. Reads auth.users rather than auth.audit_log_entries: that
-- table is empty on this project, so a feed built on it would render blank
-- forever and look like "no activity" rather than "no data source".
create or replace function public.admin_recent_signups(p_limit int default 25)
returns table (
  id           uuid,
  full_name    text,
  phone        text,
  role         text,
  onboarded    boolean,
  suspended_at timestamptz,
  created_at   timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.admin_require();

  return query
  select p.id, p.full_name, p.phone, p.role, p.onboarding_complete,
         p.suspended_at, p.created_at
  from public.profiles p
  order by p.created_at desc
  limit greatest(least(p_limit, 200), 1);
end;
$$;

-- Who signed in, most recent first. Null last_sign_in_at means an account that
-- was created but never completed a login, which is worth seeing.
create or replace function public.admin_recent_signins(p_limit int default 25)
returns table (
  id            uuid,
  full_name     text,
  phone         text,
  role          text,
  suspended_at  timestamptz,
  last_sign_in  timestamptz,
  session_count bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.admin_require();

  return query
  select p.id, p.full_name, p.phone, p.role, p.suspended_at,
         u.last_sign_in_at,
         -- GoTrue keeps no login counter. This is live sessions, which is the
         -- honest available signal; the UI labels it "sessions", not "logins".
         (select count(*) from auth.sessions s where s.user_id = u.id)
  from auth.users u
  join public.profiles p on p.id = u.id
  where u.last_sign_in_at is not null
  order by u.last_sign_in_at desc
  limit greatest(least(p_limit, 200), 1);
end;
$$;

-- Everything the user drawer needs, in one call.
create or replace function public.admin_user_detail(p_user uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v jsonb;
begin
  perform public.admin_require();

  select jsonb_build_object(
    'profile', to_jsonb(p),
    'auth', (select jsonb_build_object(
               'created_at', u.created_at,
               'last_sign_in_at', u.last_sign_in_at,
               'phone_confirmed_at', u.phone_confirmed_at
             ) from auth.users u where u.id = p.id),
    'contractor', (select to_jsonb(c) from public.contractor_profiles c
                    where c.profile_id = p.id),
    'homeowner', (select to_jsonb(h) from public.homeowner_profiles h
                   where h.profile_id = p.id),
    'stats', jsonb_build_object(
      'briefs',           (select count(*) from public.briefs b where b.homeowner_id = p.id),
      'quotes',           (select count(*) from public.quotes q where q.contractor_id = p.id),
      'posts',            (select count(*) from public.posts po where po.author_id = p.id),
      'comments',         (select count(*) from public.post_comments pc where pc.user_id = p.id),
      'reviews_written',  (select count(*) from public.reviews r where r.homeowner_id = p.id),
      'reviews_received', (select count(*) from public.reviews r where r.contractor_id = p.id),
      'reports_against',  (select count(*) from public.content_reports cr
                            where cr.target_type = 'user' and cr.target_id = p.id),
      'blocked_by',       (select count(*) from public.user_blocks ub where ub.blocked_id = p.id)
    ),
    'audit', (select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc), '[]'::jsonb)
                from public.admin_audit_log a where a.target_id = p.id)
  ) into v
  from public.profiles p
  where p.id = p_user;

  if v is null then
    raise exception 'user % not found', p_user;
  end if;
  return v;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Actions
-- ─────────────────────────────────────────────────────────────

create or replace function public.admin_set_suspended(
  p_user      uuid,
  p_suspended boolean,
  p_reason    text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.admin_require();

  -- An admin suspending themselves out of the console is unrecoverable without
  -- SQL access, and one admin suspending another is a fight the database should
  -- not adjudicate. Both are refused.
  if exists (select 1 from public.admin_users a where a.user_id = p_user) then
    raise exception 'cannot_suspend_admin' using errcode = '42501';
  end if;

  update public.profiles
     set suspended_at     = case when p_suspended then now() else null end,
         suspended_reason = case when p_suspended then p_reason else null end
   where id = p_user;

  if not found then
    raise exception 'user % not found', p_user;
  end if;

  perform public.admin_log(
    case when p_suspended then 'user.suspend' else 'user.unsuspend' end,
    'profiles', p_user, jsonb_build_object('reason', p_reason));
end;
$$;

create or replace function public.admin_set_verified(
  p_contractor uuid,
  p_verified   boolean,
  p_reason     text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.admin_require();

  update public.contractor_profiles
     set verified = p_verified
   where profile_id = p_contractor;

  if not found then
    raise exception 'contractor % not found', p_contractor;
  end if;

  perform public.admin_log(
    case when p_verified then 'contractor.verify' else 'contractor.unverify' end,
    'contractor_profiles', p_contractor, jsonb_build_object('reason', p_reason));
end;
$$;

-- Manual plan grant, for comped accounts and for a payment that arrived outside
-- the app. p_days = 0, or p_plan = 'free', revokes.
create or replace function public.admin_set_plan(
  p_contractor uuid,
  p_plan       text,
  p_days       int default 30
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.admin_require();

  if p_plan not in ('free', 'pro') then
    raise exception 'invalid plan %', p_plan;
  end if;

  update public.contractor_profiles
     set plan            = p_plan,
         plan_expires_at = case
                             when p_plan = 'pro' and p_days > 0
                             then now() + make_interval(days => p_days)
                             else null
                           end
   where profile_id = p_contractor;

  if not found then
    raise exception 'contractor % not found', p_contractor;
  end if;

  perform public.admin_log('contractor.set_plan', 'contractor_profiles', p_contractor,
    jsonb_build_object('plan', p_plan, 'days', p_days));
end;
$$;

-- Content removal. The post's media stays in storage: a removal that also
-- destroys the evidence makes an appeal impossible to review. Storage cleanup
-- is a separate, deliberate act.
create or replace function public.admin_delete_post(
  p_post   uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_author uuid;
begin
  perform public.admin_require();

  select author_id into v_author from public.posts where id = p_post;
  if v_author is null then
    raise exception 'post % not found', p_post;
  end if;

  -- Log before the delete. admin_audit_log's FK is to profiles, not posts, so
  -- the entry survives — but the author lookup would not.
  perform public.admin_log('post.delete', 'posts', p_post,
    jsonb_build_object('reason', p_reason, 'author_id', v_author));

  delete from public.posts where id = p_post;
end;
$$;

-- Resolve a report from the moderation queue.
--   dismiss         — no violation
--   remove_content  — delete the reported post or comment
--   suspend_author  — remove the content and suspend whoever posted it
create or replace function public.admin_resolve_report(
  p_report uuid,
  p_action text,
  p_note   text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r        public.content_reports;
  v_author uuid;
begin
  perform public.admin_require();

  if p_action not in ('dismiss', 'remove_content', 'suspend_author') then
    raise exception 'invalid action %', p_action;
  end if;

  select * into r from public.content_reports where id = p_report for update;
  if r.id is null then
    raise exception 'report % not found', p_report;
  end if;
  if r.status <> 'pending' then
    raise exception 'report % already %', p_report, r.status;
  end if;

  if p_action <> 'dismiss' then
    if r.target_type = 'post' then
      select author_id into v_author from public.posts where id = r.target_id;
      delete from public.posts where id = r.target_id;
    elsif r.target_type = 'comment' then
      select user_id into v_author from public.post_comments where id = r.target_id;
      delete from public.post_comments where id = r.target_id;
    elsif r.target_type = 'user' then
      v_author := r.target_id;
    end if;

    if p_action = 'suspend_author' and v_author is not null then
      -- Reuse the action RPC so the admin-immunity check and the audit entry
      -- are not duplicated here and cannot drift.
      perform public.admin_set_suspended(v_author, true,
        coalesce(p_note, 'Reported content: ' || r.reason));
    end if;
  end if;

  update public.content_reports
     set status      = case when p_action = 'dismiss' then 'dismissed' else 'actioned' end,
         reviewed_at = now()
   where id = p_report;

  perform public.admin_log('report.' || p_action, 'content_reports', p_report,
    jsonb_build_object('note', p_note, 'target_type', r.target_type,
                       'target_id', r.target_id, 'author_id', v_author));
end;
$$;

-- Thin wrappers over the 0015 / 0014 functions. The queue actions go through
-- these so every approval lands in the audit log, while the business logic
-- (setting verified, computing plan_expires_at from plan_term, writing the
-- payments row) stays in one place and is not restated here.
create or replace function public.admin_review_verification(
  p_request uuid,
  p_approve boolean,
  p_reason  text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_contractor uuid;
begin
  perform public.admin_require();

  select contractor_id into v_contractor
    from public.verification_requests where id = p_request;
  if v_contractor is null then
    raise exception 'verification request % not found', p_request;
  end if;

  if p_approve then
    perform public.approve_verification_request(p_request);
  else
    perform public.reject_verification_request(p_request, p_reason);
  end if;

  perform public.admin_log(
    case when p_approve then 'verification.approve' else 'verification.reject' end,
    'verification_requests', p_request,
    jsonb_build_object('reason', p_reason, 'contractor_id', v_contractor));
end;
$$;

create or replace function public.admin_review_payment(
  p_request uuid,
  p_approve boolean,
  p_reason  text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.payment_requests;
begin
  perform public.admin_require();

  select * into r from public.payment_requests where id = p_request;
  if r.id is null then
    raise exception 'payment request % not found', p_request;
  end if;

  if p_approve then
    perform public.approve_payment_request(p_request);
  else
    perform public.reject_payment_request(p_request, p_reason);
  end if;

  perform public.admin_log(
    case when p_approve then 'payment.approve' else 'payment.reject' end,
    'payment_requests', p_request,
    jsonb_build_object('reason', p_reason, 'contractor_id', r.contractor_id,
                       'amount_egp', r.amount_egp, 'purpose', r.purpose));
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- Grants
-- ─────────────────────────────────────────────────────────────
-- anon is revoked everywhere: none of this is reachable without a session.
-- authenticated needs EXECUTE to call at all; admin_require() is what decides.
-- Must come after create-or-replace, which re-applies Supabase's schema default
-- privileges (grant all on functions to anon, authenticated, service_role).

do $$
declare
  f record;
begin
  for f in
    select p.oid::regprocedure::text as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname like 'admin\_%'
      and p.proname not in ('admin_log', 'admin_require')
  loop
    execute format('revoke execute on function %s from public, anon', f.sig);
    execute format('grant execute on function %s to authenticated', f.sig);
  end loop;
end;
$$;
