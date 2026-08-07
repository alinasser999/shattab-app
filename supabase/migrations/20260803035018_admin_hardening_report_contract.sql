-- Admin hardening and report-contract alignment.
--
-- The console is an ordinary authenticated Supabase client. This migration
-- keeps that boundary intact while closing gaps that a forged RPC request or
-- stale dashboard could otherwise bypass.

-- ---------------------------------------------------------------------------
-- Admin levels
-- ---------------------------------------------------------------------------

-- This is a current-user-only projection. It cannot be used to enumerate
-- which other accounts are operators.
create or replace function public.admin_level()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select a.level
  from public.admin_users a
  where a.user_id = (select auth.uid());
$$;

revoke execute on function public.admin_level() from public, anon;
grant execute on function public.admin_level() to authenticated;

-- Read access remains available to every admin. Sensitive operations use this
-- second guard so the existing moderator level is not just decorative.
create or replace function public.admin_require_action(p_action text)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_level text;
begin
  select a.level into v_level
  from public.admin_users a
  where a.user_id = (select auth.uid());

  if v_level is null then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  if v_level = 'owner' then
    return;
  end if;

  if v_level = 'moderator' and p_action in (
    'user.suspend',
    'user.unsuspend',
    'contractor.verify',
    'contractor.unverify',
    'verification.approve',
    'verification.reject',
    'post.delete',
    'report.dismiss',
    'report.remove_content',
    'report.suspend_author'
  ) then
    return;
  end if;

  raise exception 'not_allowed' using errcode = '42501';
end;
$$;

revoke execute on function public.admin_require_action(text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Action RPCs: authorization, reasons, and state transitions are database
-- rules, not only form behavior.
-- ---------------------------------------------------------------------------

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
  perform public.admin_require_action(case when p_suspended then 'user.suspend' else 'user.unsuspend' end);

  if p_suspended and nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception 'reason_required' using errcode = '22023';
  end if;
  if length(coalesce(p_reason, '')) > 2000 then
    raise exception 'reason_too_long' using errcode = '22001';
  end if;

  if exists (select 1 from public.admin_users a where a.user_id = p_user) then
    raise exception 'cannot_suspend_admin' using errcode = '42501';
  end if;

  update public.profiles
     set suspended_at     = case when p_suspended then now() else null end,
         suspended_reason = case when p_suspended then nullif(btrim(p_reason), '') else null end
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
  perform public.admin_require_action(case when p_verified then 'contractor.verify' else 'contractor.unverify' end);

  if length(coalesce(p_reason, '')) > 2000 then
    raise exception 'reason_too_long' using errcode = '22001';
  end if;

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
  perform public.admin_require_action('contractor.set_plan');

  if p_plan not in ('free', 'pro') then
    raise exception 'invalid plan %', p_plan;
  end if;
  if p_plan = 'pro' and (p_days < 1 or p_days > 3650) then
    raise exception 'invalid plan days' using errcode = '22023';
  end if;

  update public.contractor_profiles
     set plan            = p_plan,
         plan_expires_at = case
                             when p_plan = 'pro' then now() + make_interval(days => p_days)
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
  perform public.admin_require_action('post.delete');

  if nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception 'reason_required' using errcode = '22023';
  end if;
  if length(coalesce(p_reason, '')) > 2000 then
    raise exception 'reason_too_long' using errcode = '22001';
  end if;

  select author_id into v_author from public.posts where id = p_post;
  if v_author is null then
    raise exception 'post % not found', p_post;
  end if;

  perform public.admin_log('post.delete', 'posts', p_post,
    jsonb_build_object('reason', btrim(p_reason), 'author_id', v_author));

  delete from public.posts where id = p_post;
end;
$$;

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
  perform public.admin_require_action('report.' || p_action);

  if p_action <> 'dismiss' and nullif(btrim(coalesce(p_note, '')), '') is null then
    raise exception 'reason_required' using errcode = '22023';
  end if;
  if length(coalesce(p_note, '')) > 2000 then
    raise exception 'reason_too_long' using errcode = '22001';
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
    elsif r.target_type = 'profile' then
      v_author := r.target_id;
    elsif r.target_type = 'brief' then
      select homeowner_id into v_author from public.briefs where id = r.target_id;
    elsif r.target_type = 'review' then
      select homeowner_id into v_author from public.reviews where id = r.target_id;
    else
      raise exception 'unsupported_report_target' using errcode = '22023';
    end if;

    if p_action = 'remove_content' and r.target_type not in ('post', 'comment') then
      raise exception 'unsupported_report_target' using errcode = '22023';
    end if;

    if p_action = 'suspend_author' then
      if v_author is null then
        raise exception 'reported target no longer exists';
      end if;
      perform public.admin_set_suspended(v_author, true,
        coalesce(nullif(btrim(p_note), ''), 'Reported content: ' || r.reason));
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
  v_status text;
begin
  perform public.admin_require();
  perform public.admin_require_action(case when p_approve then 'verification.approve' else 'verification.reject' end);

  if not p_approve and nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception 'reason_required' using errcode = '22023';
  end if;
  if length(coalesce(p_reason, '')) > 2000 then
    raise exception 'reason_too_long' using errcode = '22001';
  end if;

  select contractor_id, status into v_contractor, v_status
    from public.verification_requests where id = p_request for update;
  if v_contractor is null then
    raise exception 'verification request % not found', p_request;
  end if;
  if v_status <> 'pending' then
    raise exception 'verification request % already %', p_request, v_status;
  end if;

  if p_approve then
    perform public.approve_verification_request(p_request);
  else
    perform public.reject_verification_request(p_request, btrim(p_reason));
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
  perform public.admin_require_action(case when p_approve then 'payment.approve' else 'payment.reject' end);

  if not p_approve and nullif(btrim(coalesce(p_reason, '')), '') is null then
    raise exception 'reason_required' using errcode = '22023';
  end if;
  if length(coalesce(p_reason, '')) > 2000 then
    raise exception 'reason_too_long' using errcode = '22001';
  end if;

  select * into r from public.payment_requests where id = p_request for update;
  if r.id is null then
    raise exception 'payment request % not found', p_request;
  end if;
  if r.status <> 'pending' then
    raise exception 'payment request % already %', p_request, r.status;
  end if;

  if p_approve then
    perform public.approve_payment_request(p_request);
  else
    perform public.reject_payment_request(p_request, btrim(p_reason));
  end if;

  perform public.admin_log(
    case when p_approve then 'payment.approve' else 'payment.reject' end,
    'payment_requests', p_request,
    jsonb_build_object('reason', p_reason, 'contractor_id', r.contractor_id,
                       'amount_egp', r.amount_egp, 'purpose', r.purpose));
end;
$$;

-- The old queue helpers are internal implementation details. Keeping them
-- callable by authenticated users would let a moderator bypass the action
-- matrix and would duplicate audit behavior, so only the admin wrappers reach
-- them now.
revoke execute on function public.approve_verification_request(uuid) from public, anon, authenticated;
revoke execute on function public.reject_verification_request(uuid, text) from public, anon, authenticated;
revoke execute on function public.approve_payment_request(uuid) from public, anon, authenticated;
revoke execute on function public.reject_payment_request(uuid, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Read-model fixes
-- ---------------------------------------------------------------------------

-- The Flutter app stores profile reports as target_type = 'profile'. The old
-- read model used 'user', so the account drawer silently reported zero even
-- when the account had an actual report history.
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
      'reports_against', (select count(*) from public.content_reports cr
                           where cr.target_type = 'profile' and cr.target_id = p.id),
      'blocked_by',       (select count(*) from public.user_blocks ub where ub.blocked_id = p.id)
    ),
    'audit', (select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc), '[]'::jsonb)
                from (
                  select * from public.admin_audit_log
                  where target_id = p.id
                  order by created_at desc
                  limit 100
                ) a)
  ) into v
  from public.profiles p
  where p.id = p_user;

  if v is null then
    raise exception 'user % not found', p_user;
  end if;
  return v;
end;
$$;

-- Grants for the replaced RPCs are reapplied explicitly after CREATE OR
-- REPLACE. The generic admin grant loop in 0028 does not rerun on a migration.
revoke execute on function public.admin_set_suspended(uuid, boolean, text) from public, anon;
revoke execute on function public.admin_set_verified(uuid, boolean, text) from public, anon;
revoke execute on function public.admin_set_plan(uuid, text, integer) from public, anon;
revoke execute on function public.admin_delete_post(uuid, text) from public, anon;
revoke execute on function public.admin_resolve_report(uuid, text, text) from public, anon;
revoke execute on function public.admin_review_verification(uuid, boolean, text) from public, anon;
revoke execute on function public.admin_review_payment(uuid, boolean, text) from public, anon;
revoke execute on function public.admin_user_detail(uuid) from public, anon;

grant execute on function public.admin_set_suspended(uuid, boolean, text) to authenticated;
grant execute on function public.admin_set_verified(uuid, boolean, text) to authenticated;
grant execute on function public.admin_set_plan(uuid, text, integer) to authenticated;
grant execute on function public.admin_delete_post(uuid, text) to authenticated;
grant execute on function public.admin_resolve_report(uuid, text, text) to authenticated;
grant execute on function public.admin_review_verification(uuid, boolean, text) to authenticated;
grant execute on function public.admin_review_payment(uuid, boolean, text) to authenticated;
grant execute on function public.admin_user_detail(uuid) to authenticated;
