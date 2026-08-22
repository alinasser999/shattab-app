-- Phase 1: keep account authority in the database, not in a client-writable
-- profile field. A user chooses a role during onboarding; after onboarding the
-- role controls access to two different product surfaces and must not be
-- changed by a normal PostgREST update.

-- Do not let user-controlled auth metadata decide an authorization-bearing
-- profile role. New accounts start as homeowners and choose their role through
-- the authenticated onboarding write while onboarding_complete is still false.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name, phone)
  values (
    new.id,
    'homeowner',
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.phone, '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

drop policy if exists "Update own profile" on public.profiles;
create policy "Update own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Direct PostgREST reads of profiles would expose every selected column,
-- including phone, even when the Flutter catalogue only requested a narrow
-- projection. Public contractor data therefore travels through explicit
-- projection functions instead of a table-wide public SELECT policy.
drop policy if exists "Read public contractor profiles" on public.profiles;

create or replace function public.tg_guard_profile_authority()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Authenticated API calls are the only calls restricted here. Migrations,
  -- server-side jobs, and the admin service boundary have auth.uid() = null
  -- and remain able to repair an account through their own controlled path.
  if auth.uid() is not null then
    if old.onboarding_complete
       and new.role is distinct from old.role then
      raise exception 'role_locked_after_onboarding'
        using errcode = '42501';
    end if;

    if old.onboarding_complete
       and not new.onboarding_complete then
      raise exception 'onboarding_completion_locked'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.tg_guard_profile_authority() from public, anon, authenticated;

drop trigger if exists guard_profile_authority on public.profiles;
create trigger guard_profile_authority
  before update on public.profiles
  for each row execute function public.tg_guard_profile_authority();

comment on function public.tg_guard_profile_authority() is
  'Locks role and onboarding completion after onboarding for client API calls; '
  'role selection remains possible before onboarding is complete.';

-- Public contractor discovery must not become a phone directory. Contact is
-- deliberately fetched only by the detail surface after the profile is open.
-- Keep the old identity function's return shape for already released clients,
-- but never return phone through a feed/profile identity projection.
create or replace function public.get_community_author_identity(
  p_author_id uuid,
  p_author_role text
)
returns table(
  full_name text,
  avatar_url text,
  phone text
)
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

-- Contact is a deliberate, authenticated detail-surface action. It is not
-- part of a list projection, feed hydration RPC, or anonymous profile read.
create or replace function public.get_contractor_contact(p_contractor_id uuid)
returns table(phone text)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select p.phone
  from public.profiles p
  where (select auth.uid()) is not null
    and p.id = p_contractor_id
    and p.role = 'contractor';
$$;

revoke all on function public.get_contractor_contact(uuid)
  from public, anon, authenticated;
grant execute on function public.get_contractor_contact(uuid)
  to authenticated;

comment on function public.get_contractor_contact(uuid) is
  'Returns contractor contact only to an authenticated detail-surface request; never use for catalogue hydration.';

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

create or replace function public.get_saved_contractors(
  p_homeowner_id uuid,
  p_limit int default 100
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
  from public.saved_contractors sc
  join public.profiles p on p.id = sc.contractor_id
  join public.contractor_profiles cp on cp.profile_id = p.id
  where (select auth.uid()) = p_homeowner_id
    and sc.homeowner_id = p_homeowner_id
    and p.role = 'contractor'
  -- The baseline migration calls this column created_at. A later
  -- normalization migration renames it to saved_at on fresh databases; use
  -- the baseline name here so the migration history can replay cleanly.
  order by sc.created_at desc, sc.contractor_id asc
  limit least(greatest(p_limit, 1), 100);
$$;

revoke all on function public.get_saved_contractors(uuid, int) from public, anon;
grant execute on function public.get_saved_contractors(uuid, int) to authenticated;

create or replace function public.discover_contractors(
  p_query      text default null,
  p_specialty  text default null,
  p_city       text default null,
  p_limit      int  default 20,
  p_offset     int  default 0
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
                 public.shattab_normalize_ar(
                   pg_catalog.btrim(coalesce(p_query, ''))
                 ),
                 '\\', '\\\\'
               ),
               '%', '\\%'
             ),
             '_', '\\_'
           ) as q
  )
  select jsonb_build_object(
    'id',        p.id,
    'full_name', p.full_name,
    'contractor_profiles', jsonb_build_object(
      'business_name',      cp.business_name,
      'bio',                cp.bio,
      'logo_url',           cp.logo_url,
      'cover_photo_url',    cp.cover_photo_url,
      'headline',           cp.headline,
      'specialties',        cp.specialties,
      'service_areas',      cp.service_areas,
      'years_experience',   cp.years_experience,
      'projects_completed', cp.projects_completed,
      'response_rate',      cp.response_rate,
      'rating_avg',         cp.rating_avg,
      'rating_count',       cp.rating_count,
      'verified',           cp.verified,
      'plan',               cp.plan,
      'provider_kind',      cp.provider_kind,
      'created_at',         cp.created_at
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
