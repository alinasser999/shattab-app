-- Special Pro is a paid placement product, not an earned trust signal.
-- Keep it visibly disclosed in the catalogue and keep verification, ratings,
-- reviews, and completed work independent from payment.

create index if not exists contractor_profiles_sponsored_until_idx
  on public.contractor_profiles (sponsored_until desc, profile_id)
  where sponsored_until is not null;

create or replace function public.submit_payment_request(
  p_method text,
  p_purpose text,
  p_plan_term text default null,
  p_proof_path text default null,
  p_reference_text text default null,
  p_idempotency_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := (select auth.uid());
  v_key text := nullif(btrim(p_idempotency_key), '');
  v_amount int;
  v_existing uuid;
  v_request uuid;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.profiles p
    where p.id = v_uid and p.role = 'contractor'
  ) then
    raise exception 'contractor profile required' using errcode = '42501';
  end if;
  if p_method is distinct from 'instapay' then
    raise exception 'payment method is not available';
  end if;
  if p_purpose = 'pro' then
    if p_plan_term not in ('monthly', 'annual') then
      raise exception 'invalid Pro plan term';
    end if;
    v_amount := case p_plan_term
      when 'monthly' then 299
      when 'annual' then 2990
    end;
  elsif p_purpose = 'sponsored' then
    if p_plan_term is distinct from 'weekly' then
      raise exception 'invalid placement term';
    end if;
    v_amount := 199;
  else
    raise exception 'payment purpose is not available';
  end if;
  if v_key is null or v_key !~ '^[A-Za-z0-9_-]{16,128}$' then
    raise exception 'invalid idempotency key';
  end if;
  if p_proof_path is null
     or p_proof_path !~ ('^' || v_uid::text || '/[A-Za-z0-9._/-]+$') then
    raise exception 'payment proof is required';
  end if;
  if not exists (
    select 1 from storage.objects so
    where so.bucket_id = 'payment-proofs' and so.name = p_proof_path
  ) then
    raise exception 'payment proof was not uploaded';
  end if;
  if p_reference_text is not null and length(p_reference_text) > 500 then
    raise exception 'reference is too long';
  end if;

  select pr.id into v_existing
  from public.payment_requests pr
  where pr.contractor_id = v_uid and pr.idempotency_key = v_key
  limit 1;
  if v_existing is not null then return v_existing; end if;

  if exists (
    select 1 from public.payment_requests pr
    where pr.contractor_id = v_uid
      and pr.purpose = p_purpose
      and pr.status = 'pending'
  ) then
    raise exception 'payment request already pending';
  end if;

  begin
    insert into public.payment_requests (
      contractor_id, method, purpose, plan_term, amount_egp,
      proof_path, reference_text, status, idempotency_key
    ) values (
      v_uid, p_method, p_purpose, p_plan_term, v_amount,
      p_proof_path, nullif(btrim(p_reference_text), ''), 'pending', v_key
    ) returning id into v_request;
  exception when unique_violation then
    select pr.id into v_request
    from public.payment_requests pr
    where pr.contractor_id = v_uid and pr.idempotency_key = v_key
    limit 1;
    if v_request is null then raise; end if;
  end;
  return v_request;
end;
$$;

revoke all on function public.submit_payment_request(text, text, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.submit_payment_request(text, text, text, text, text, text)
  to authenticated;

create or replace function public.get_my_billing_state()
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'plan', coalesce(
      (select cp.plan from public.contractor_profiles cp
       where cp.profile_id = (select auth.uid())), 'free'
    ),
    'plan_expires_at', (
      select cp.plan_expires_at from public.contractor_profiles cp
      where cp.profile_id = (select auth.uid())
    ),
    'sponsored_until', (
      select cp.sponsored_until from public.contractor_profiles cp
      where cp.profile_id = (select auth.uid())
    ),
    'latest_request', coalesce(
      (
        select jsonb_build_object(
          'id', pr.id,
          'status', pr.status,
          'purpose', pr.purpose,
          'plan_term', pr.plan_term,
          'amount_egp', pr.amount_egp,
          'reject_reason', pr.reject_reason,
          'created_at', pr.created_at,
          'reviewed_at', pr.reviewed_at
        )
        from public.payment_requests pr
        where pr.contractor_id = (select auth.uid())
        order by pr.created_at desc, pr.id desc
        limit 1
      ), '{}'::jsonb
    ),
    'latest_payment', coalesce(
      (
        select jsonb_build_object(
          'id', p.id,
          'status', p.status,
          'purpose', p.purpose,
          'amount_piastres', p.amount_piastres,
          'period_end', p.period_end,
          'created_at', p.created_at
        )
        from public.payments p
        where p.contractor_id = (select auth.uid())
        order by p.created_at desc, p.id desc
        limit 1
      ), '{}'::jsonb
    )
  )
  where (select auth.uid()) is not null;
$$;

revoke all on function public.get_my_billing_state() from public, anon, authenticated;
grant execute on function public.get_my_billing_state() to authenticated;

-- This is a deliberately separate collection. It lets the catalogue disclose
-- paid placement without corrupting the factual "top rated" collection.
create or replace function public.list_sponsored_contractors(
  p_specialty text default null,
  p_city text default null,
  p_limit int default 6
)
returns setof jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'id', p.id,
    'full_name', p.full_name,
    'is_sponsored', true,
    'contractor_profiles', jsonb_build_object(
      'business_name', cp.business_name,
      'bio', cp.bio,
      'logo_url', cp.logo_url,
      'cover_photo_url', cp.cover_photo_url,
      'headline', cp.headline,
      'specialties', cp.specialties,
      'service_areas', cp.service_areas,
      'years_experience', cp.years_experience,
      'projects_completed', cp.projects_completed,
      'rating_avg', cp.rating_avg,
      'rating_count', cp.rating_count,
      'verified', cp.verified,
      'plan', cp.plan,
      'provider_kind', cp.provider_kind,
      'created_at', cp.created_at
    )
  )
  from public.profiles p
  join public.contractor_profiles cp on cp.profile_id = p.id
  where p.role = 'contractor'
    and cp.sponsored_until > now()
    and (p_specialty is null or cp.specialties @> array[p_specialty])
    and (p_city is null or cp.service_areas @> array[p_city])
  order by
    md5(p.id::text || current_date::text),
    coalesce(p.full_name, ''),
    p.id
  limit least(greatest(p_limit, 1), 6);
$$;

revoke all on function public.list_sponsored_contractors(text, text, int)
  from public, anon, authenticated;
grant execute on function public.list_sponsored_contractors(text, text, int)
  to anon, authenticated;

comment on function public.list_sponsored_contractors(text, text, int) is
  'Public paid-placement shelf. The response is explicitly marked is_sponsored and never replaces earned ratings or verification.';
