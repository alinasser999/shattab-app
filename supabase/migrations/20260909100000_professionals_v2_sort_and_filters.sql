-- Professionals catalogue forward contract.
--
-- This is additive: older clients continue using list_contractors_cursor while
-- the homeowner experience can opt into rating thresholds and stable
-- most-completed ordering. It intentionally returns the same public-safe JSON
-- projection and never exposes contact details.

create or replace function public.list_contractors_cursor_v2(
  p_specialty text default null,
  p_city text default null,
  p_limit int default 20,
  p_sort text default 'name',
  p_min_rating numeric default null,
  p_after_name text default null,
  p_after_id uuid default null,
  p_after_rating numeric default null,
  p_after_rating_count int default null,
  p_after_projects int default null
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
      and (p_specialty is null or cp.specialties @> array[p_specialty])
      and (p_city is null or cp.service_areas @> array[p_city])
      and (
        p_min_rating is null
        or (cp.rating_count > 0 and cp.rating_avg >= p_min_rating)
      )
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
    when p_sort = 'projects' then
      p_after_projects is null
      or c.projects_completed < p_after_projects
      or (
        c.projects_completed = p_after_projects
        and coalesce(c.full_name, '') > coalesce(p_after_name, '')
      )
      or (
        c.projects_completed = p_after_projects
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
    case when p_sort = 'projects' then c.projects_completed end desc,
    coalesce(c.full_name, '') asc,
    c.id asc
  limit least(greatest(p_limit, 1), 50);
$$;

revoke all on function public.list_contractors_cursor_v2(
  text, text, int, text, numeric, text, uuid, numeric, int, int
) from public, anon, authenticated;
grant execute on function public.list_contractors_cursor_v2(
  text, text, int, text, numeric, text, uuid, numeric, int, int
) to anon, authenticated;
