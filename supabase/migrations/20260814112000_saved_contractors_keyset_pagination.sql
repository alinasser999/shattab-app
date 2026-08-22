-- Keep the saved-professionals collection bounded and stable as accounts grow.
-- The older get_saved_contractors(uuid, int) RPC remains for released clients;
-- new clients use this cursor contract instead of an unbounded list.

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

revoke all on function public.get_saved_contractors_cursor(uuid, int, timestamptz, uuid)
  from public, anon, authenticated;
grant execute on function public.get_saved_contractors_cursor(uuid, int, timestamptz, uuid)
  to authenticated;
