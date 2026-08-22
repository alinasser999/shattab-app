-- Public catalogue responses must never expose operational estimates that are
-- backed by a legacy default rather than measured events.
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
