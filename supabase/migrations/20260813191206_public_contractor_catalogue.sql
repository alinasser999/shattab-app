-- The homeowner discovery catalogue is intentionally browseable before sign-in.
-- Keep the projection narrow: this RPC never returns phone or other contact data.

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
  where p.role = 'contractor'
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
  from public;
grant execute on function public.list_contractors(text, text, int, int, text, uuid, boolean)
  to anon, authenticated;

comment on function public.list_contractors(text, text, int, int, text, uuid, boolean) is
  'Public contractor catalogue projection; contact details require the authenticated detail RPC.';
