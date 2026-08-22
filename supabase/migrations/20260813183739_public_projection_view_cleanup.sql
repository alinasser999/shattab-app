-- Views over profiles are security-definer by default and can bypass the
-- source table's RLS. The RPCs own the exact public projection, so remove the
-- temporary views and keep the boundary in one auditable place.

create or replace function public.get_community_author_identity(
  p_author_id uuid,
  p_author_role text
)
returns table(full_name text, avatar_url text, phone text)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select pr.full_name, pr.avatar_url, null::text as phone
  from public.profiles pr
  where pr.id = p_author_id
    and pr.role = p_author_role
    and p_author_role in ('homeowner', 'contractor');
$$;

revoke all on function public.get_community_author_identity(uuid, text)
  from public, anon, authenticated;
grant execute on function public.get_community_author_identity(uuid, text)
  to anon, authenticated;

create or replace function public.list_contractors(
  p_specialty text default null,
  p_city text default null,
  p_limit int default 20,
  p_offset int default 0,
  p_sort text default 'name',
  p_contractor_id uuid default null,
  p_only_reviewed boolean default false
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
  where (select auth.uid()) is not null
    and p.role = 'contractor'
    and (p_contractor_id is null or p.id = p_contractor_id)
    and (not p_only_reviewed or cp.rating_count > 0)
    and (p_specialty is null or cp.specialties @> array[p_specialty])
    and (p_city is null or cp.service_areas @> array[p_city])
  order by
    case when p_sort = 'rating' then cp.rating_avg end desc nulls last,
    case when p_sort = 'rating' then cp.rating_count end desc nulls last,
    p.full_name asc,
    p.id asc
  limit least(greatest(p_limit, 1), 50)
  offset greatest(p_offset, 0);
$$;

revoke all on function public.list_contractors(text, text, int, int, text, uuid, boolean)
  from public, anon;
grant execute on function public.list_contractors(text, text, int, int, text, uuid, boolean)
  to authenticated;

create or replace function public.discover_contractors(
  p_query text default null,
  p_specialty text default null,
  p_city text default null,
  p_limit int default 20,
  p_offset int default 0
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
                 '\\', '\\\\'
               ),
               '%', '\\%'
             ),
             '_', '\\_'
           ) as q
  )
  select jsonb_build_object(
    'id', p.id,
    'full_name', p.full_name,
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
      'response_rate', cp.response_rate,
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
  cross join needle n
  where p.role = 'contractor'
    and (p_specialty is null or cp.specialties @> array[p_specialty])
    and (p_city is null or cp.service_areas @> array[p_city])
    and (
      n.q = '' or
      public.shattab_normalize_ar(cp.business_name) like '%' || n.q || '%' or
      public.shattab_normalize_ar(p.full_name) like '%' || n.q || '%'
    )
  order by
    case
      when n.q = '' then 1
      when public.shattab_normalize_ar(cp.business_name) like n.q || '%'
        or public.shattab_normalize_ar(p.full_name) like n.q || '%'
      then 0
      else 1
    end,
    p.full_name,
    p.id
  limit least(greatest(p_limit, 1), 50)
  offset greatest(p_offset, 0);
$$;

revoke all on function public.discover_contractors(text, text, text, int, int)
  from public, anon;
grant execute on function public.discover_contractors(text, text, text, int, int)
  to anon, authenticated;

drop view if exists public.contractor_directory;
drop view if exists public.community_author_directory;
