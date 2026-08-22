-- Fixes a LIKE-metacharacter escaping regression in the Arabic search RPCs.
--
-- The original construction (20260807232000) escaped correctly with '\'
-- and '\\' literals. Every later rewrite doubled those to '\\' and '\\\\',
-- which under standard_conforming_strings = on are two and four literal
-- backslashes. Result: single backslashes in user queries pass through
-- unescaped and act as LIKE escape characters - a search that should match
-- "x\y" matches "xy" instead. Verified against production on 2026-08-22:
--   ('x\y' like 'x\y')                    -> false  (broken: needle misses itself)
--   ('aXb' like 'a%b')                    -> true   (% still wildcards)
-- With the corrected literals both behave as intended.
--
-- Bodies are otherwise byte-identical to the latest live versions
-- (20260814106000 / 20260814107000); only the three replace() literals change.

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
                 '\', '\\'
               ),
               '%', '\%'
             ),
             '_', '\_'
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
  from public, anon, authenticated;
grant execute on function public.discover_contractors(text, text, text, int, int)
  to anon, authenticated;

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
