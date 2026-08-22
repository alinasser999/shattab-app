-- Expose plan_expires_at through the four catalogue functions that feed
-- ContractorListing, so the client can render Pro badges only while a
-- subscription is actually active. Previously the RPCs emitted plan alone,
-- and ContractorListing.isPro checked only plan == 'pro' - an expired but
-- not-yet-flipped row rendered paid badges publicly (audit finding).
--
-- Bodies are otherwise identical to the live definitions as of 2026-08-22;
-- only the CTE column lists and jsonb_build_object calls gain the field.
-- plan_expires_at is business data in the same class as plan itself
-- (contractor_profiles is publicly readable by design).

-- ── 1. discover_contractors_cursor ─────────────────────────────
create or replace function public.discover_contractors_cursor(
  p_query text default null,
  p_specialty text default null,
  p_city text default null,
  p_limit int default 20,
  p_after_rank int default null,
  p_after_name text default null,
  p_after_id uuid default null
)
returns setof jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with needle as (
    select pg_catalog.replace(
             pg_catalog.replace(
               pg_catalog.replace(
                 public.shattab_normalize_ar(pg_catalog.btrim(coalesce(p_query, ''))),
                 '\', '\\'
               ),
               '%', '\%'
             ),
             '_', '\_'
           ) as q
  ), candidates as (
    select
      p.id,
      p.full_name,
      cp.business_name,
      cp.bio,
      cp.logo_url,
      cp.cover_photo_url,
      cp.headline,
      cp.specialties,
      cp.service_areas,
      cp.years_experience,
      cp.projects_completed,
      cp.rating_avg,
      cp.rating_count,
      cp.verified,
      cp.plan,
      cp.plan_expires_at,
      cp.provider_kind,
      cp.created_at,
      case
        when n.q = '' then 1
        when public.shattab_normalize_ar(cp.business_name) like n.q || '%'
          or public.shattab_normalize_ar(p.full_name) like n.q || '%'
        then 0
        else 1
      end as match_rank
    from public.profiles p
    join public.contractor_profiles cp on cp.profile_id = p.id
    cross join needle n
    where p.role = 'contractor'
      and (p_specialty is null or cp.specialties @> array[p_specialty])
      and (p_city is null or cp.service_areas @> array[p_city])
      and (
        n.q = '' or
        public.shattab_normalize_ar(cp.business_name) like '%' || n.q || '%' or
        public.shattab_normalize_ar(p.full_name) like '%' || n.q || '%'
      )
  )
  select jsonb_build_object(
    'id', c.id,
    'full_name', c.full_name,
    'match_rank', c.match_rank,
    'contractor_profiles', jsonb_build_object(
      'business_name', c.business_name,
      'bio', c.bio,
      'logo_url', c.logo_url,
      'cover_photo_url', c.cover_photo_url,
      'headline', c.headline,
      'specialties', c.specialties,
      'service_areas', c.service_areas,
      'years_experience', c.years_experience,
      'projects_completed', c.projects_completed,
      'rating_avg', c.rating_avg,
      'rating_count', c.rating_count,
      'verified', c.verified,
      'plan', c.plan,
      'plan_expires_at', c.plan_expires_at,
      'provider_kind', c.provider_kind,
      'created_at', c.created_at
    )
  )
  from candidates c
  where p_after_rank is null
    or c.match_rank > p_after_rank
    or (
      c.match_rank = p_after_rank
      and coalesce(c.full_name, '') > coalesce(p_after_name, '')
    )
    or (
      c.match_rank = p_after_rank
      and coalesce(c.full_name, '') = coalesce(p_after_name, '')
      and c.id > coalesce(p_after_id, '00000000-0000-0000-0000-000000000000'::uuid)
    )
  order by c.match_rank, coalesce(c.full_name, ''), c.id
  limit least(greatest(p_limit, 1), 50);
$$;

revoke all on function public.discover_contractors_cursor(
  text, text, text, int, int, text, uuid
) from public, anon, authenticated;
grant execute on function public.discover_contractors_cursor(
  text, text, text, int, int, text, uuid
) to anon, authenticated;

-- ── 2. list_contractors_cursor ─────────────────────────────────
create or replace function public.list_contractors_cursor(
  p_specialty text default null,
  p_city text default null,
  p_limit int default 20,
  p_sort text default 'name',
  p_contractor_id uuid default null,
  p_only_reviewed boolean default false,
  p_after_name text default null,
  p_after_id uuid default null,
  p_after_rating numeric default null,
  p_after_rating_count int default null
)
returns setof jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with candidates as (
    select
      p.id,
      p.full_name,
      cp.business_name,
      cp.bio,
      cp.logo_url,
      cp.cover_photo_url,
      cp.headline,
      cp.specialties,
      cp.service_areas,
      cp.years_experience,
      cp.projects_completed,
      cp.rating_avg,
      cp.rating_count,
      cp.verified,
      cp.plan,
      cp.plan_expires_at,
      cp.provider_kind,
      cp.created_at
    from public.profiles p
    join public.contractor_profiles cp on cp.profile_id = p.id
    where p.role = 'contractor'
      and (p_contractor_id is null or p.id = p_contractor_id)
      and (not p_only_reviewed or cp.rating_count > 0)
      and (p_specialty is null or cp.specialties @> array[p_specialty])
      and (p_city is null or cp.service_areas @> array[p_city])
  )
  select jsonb_build_object(
    'id', c.id,
    'full_name', c.full_name,
    'contractor_profiles', jsonb_build_object(
      'business_name', c.business_name,
      'bio', c.bio,
      'logo_url', c.logo_url,
      'cover_photo_url', c.cover_photo_url,
      'headline', c.headline,
      'specialties', c.specialties,
      'service_areas', c.service_areas,
      'years_experience', c.years_experience,
      'projects_completed', c.projects_completed,
      'rating_avg', c.rating_avg,
      'rating_count', c.rating_count,
      'verified', c.verified,
      'plan', c.plan,
      'plan_expires_at', c.plan_expires_at,
      'provider_kind', c.provider_kind,
      'created_at', c.created_at
    )
  )
  from candidates c
  where case
    when p_sort = 'rating' then
      p_after_rating is null
      or coalesce(c.rating_avg, -1) < p_after_rating
      or (
        coalesce(c.rating_avg, -1) = p_after_rating
        and coalesce(c.rating_count, 0) < coalesce(p_after_rating_count, 0)
      )
      or (
        coalesce(c.rating_avg, -1) = p_after_rating
        and coalesce(c.rating_count, 0) = coalesce(p_after_rating_count, 0)
        and coalesce(c.full_name, '') > coalesce(p_after_name, '')
      )
      or (
        coalesce(c.rating_avg, -1) = p_after_rating
        and coalesce(c.rating_count, 0) = coalesce(p_after_rating_count, 0)
        and coalesce(c.full_name, '') = coalesce(p_after_name, '')
        and c.id > coalesce(p_after_id, '00000000-0000-0000-0000-000000000000'::uuid)
      )
    else
      p_after_name is null
      or coalesce(c.full_name, '') > p_after_name
      or (
        coalesce(c.full_name, '') = p_after_name
        and c.id > coalesce(p_after_id, '00000000-0000-0000-0000-000000000000'::uuid)
      )
  end
  order by
    case when p_sort = 'rating' then coalesce(c.rating_avg, -1) end desc,
    case when p_sort = 'rating' then coalesce(c.rating_count, 0) end desc,
    coalesce(c.full_name, '') asc,
    c.id asc
  limit least(greatest(p_limit, 1), 50);
$$;

revoke all on function public.list_contractors_cursor(
  text, text, int, text, uuid, boolean, text, uuid, numeric, int
) from public, anon, authenticated;
grant execute on function public.list_contractors_cursor(
  text, text, int, text, uuid, boolean, text, uuid, numeric, int
) to anon, authenticated;

-- ── 3. list_sponsored_contractors ──────────────────────────────
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
      'plan_expires_at', cp.plan_expires_at,
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

-- ── 4. get_saved_contractors_cursor ────────────────────────────
create or replace function public.get_saved_contractors_cursor(
  p_homeowner_id uuid,
  p_limit int default 20,
  p_after_saved_at timestamptz default null,
  p_after_contractor_id uuid default null
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
    'saved_at', sc.saved_at,
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
      'plan_expires_at', cp.plan_expires_at,
      'provider_kind', cp.provider_kind,
      'created_at', cp.created_at
    )
  )
  from public.saved_contractors sc
  join public.profiles p on p.id = sc.contractor_id
  join public.contractor_profiles cp on cp.profile_id = p.id
  where (select auth.uid()) = p_homeowner_id
    and sc.homeowner_id = p_homeowner_id
    and p.role = 'contractor'
    and (
      p_after_saved_at is null
      or sc.saved_at < p_after_saved_at
      or (
        sc.saved_at = p_after_saved_at
        and p_after_contractor_id is not null
        and sc.contractor_id > p_after_contractor_id
      )
    )
  order by sc.saved_at desc, sc.contractor_id asc
  limit least(greatest(coalesce(p_limit, 20), 1), 50);
$$;

revoke all on function public.get_saved_contractors_cursor(
  uuid, int, timestamptz, uuid
) from public, anon, authenticated;
grant execute on function public.get_saved_contractors_cursor(
  uuid, int, timestamptz, uuid
) to authenticated;
