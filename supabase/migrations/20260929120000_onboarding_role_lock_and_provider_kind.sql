-- Make role selection a one-time, server-owned onboarding transition.
-- This migration is additive and must be applied before shipping the client
-- that calls these RPCs. Direct legacy writes remain guarded during rollout.

-- Run the legacy backfills only when this marker is first introduced. That
-- keeps a replay from reclassifying newly-repaired accounts as unselected.
do $$
declare
  v_marker_added boolean;
begin
  select not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'role_selection_locked'
  ) into v_marker_added;

  alter table public.profiles
    add column if not exists role_selection_locked boolean not null default true;

  if v_marker_added then
    -- Existing installations cannot distinguish an automatically-created
    -- blank homeowner from an intentional homeowner choice. A non-empty name
    -- was written with the old role choice, and a branch profile proves
    -- progress.
    update public.profiles p
    set role_selection_locked = case
      when p.onboarding_complete then true
      when p.role = 'contractor' then true
      when p.role = 'homeowner'
        and btrim(coalesce(p.full_name, '')) = ''
        and not exists (
          select 1
          from public.homeowner_profiles hp
          where hp.profile_id = p.id
        )
        and not exists (
          select 1
          from public.contractor_profiles cp
          where cp.profile_id = p.id
        ) then false
      else true
    end;

    -- Older clients could mark a profile complete before requiring homeowner
    -- location. Preserve the chosen role, but return invalid completed rows to
    -- the required onboarding flow so the router can direct users to repair.
    update public.profiles p
    set onboarding_complete = false
    where p.onboarding_complete
      and case
        when p.role = 'homeowner' then not exists (
          select 1
          from public.homeowner_profiles hp
          where hp.profile_id = p.id
            and char_length(btrim(coalesce(p.full_name, ''))) >= 2
            and hp.apartment_type is not null
            and exists (
              select 1
              from unnest(coalesce(hp.renovation_interests, '{}'::text[]))
                as interests(interest)
              where btrim(interest) <> ''
            )
            and btrim(coalesce(hp.city, '')) <> ''
            and btrim(coalesce(hp.district, '')) <> ''
        )
        when p.role = 'contractor' then not exists (
          select 1
          from public.contractor_profiles cp
          where cp.profile_id = p.id
            and char_length(btrim(coalesce(p.full_name, ''))) >= 2
            and cp.provider_kind in (
              'contractor',
              'engineer',
              'engineering_office',
              'finishing_company',
              'interior_designer',
              'specialized_provider',
              'tradesman'
            )
            and exists (
              select 1
              from unnest(coalesce(cp.specialties, '{}'::text[]))
                as specialties(specialty)
              where btrim(specialty) <> ''
            )
            and exists (
              select 1
              from unnest(coalesce(cp.service_areas, '{}'::text[]))
                as areas(area)
              where btrim(area) <> ''
            )
            and (
              cp.provider_kind not in ('engineering_office', 'finishing_company')
              or char_length(btrim(coalesce(cp.business_name, ''))) >= 2
            )
        )
        else true
      end;
  end if;
end;
$$;

-- Never trust user-controlled auth metadata for the authorization-bearing
-- role. New accounts start as homeowners with role choice still available.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    role,
    full_name,
    phone,
    role_selection_locked
  )
  values (
    new.id,
    'homeowner',
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.phone, ''),
    false
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_user()
  from public, anon, authenticated;

create or replace function public.select_onboarding_role(
  p_role text,
  p_full_name text
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_full_name text := btrim(coalesce(p_full_name, ''));
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '42501';
  end if;

  if p_role is null or p_role not in ('homeowner', 'contractor') then
    raise exception 'invalid_onboarding_role' using errcode = '22023';
  end if;

  if char_length(v_full_name) < 2 then
    raise exception 'invalid_onboarding_name' using errcode = '22023';
  end if;

  select * into v_profile
  from public.profiles
  where id = v_user_id
  for update;

  if not found then
    raise exception 'profile_not_found' using errcode = 'P0002';
  end if;

  if v_profile.role_selection_locked or v_profile.onboarding_complete then
    if v_profile.role = p_role and btrim(v_profile.full_name) = v_full_name then
      -- The client may have lost the first response. Repeating the exact
      -- selection is a successful no-op; a changed selection stays locked.
      return;
    end if;
    raise exception 'onboarding_role_locked' using errcode = '42501';
  end if;

  update public.profiles
  set role = p_role,
      full_name = v_full_name,
      role_selection_locked = true
  where id = v_user_id;
end;
$$;

revoke all on function public.select_onboarding_role(text, text)
  from public, anon, authenticated;
grant execute on function public.select_onboarding_role(text, text)
  to authenticated;

create or replace function public.complete_onboarding()
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_homeowner public.homeowner_profiles%rowtype;
  v_contractor public.contractor_profiles%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '42501';
  end if;

  select * into v_profile
  from public.profiles
  where id = v_user_id
  for update;

  if not found then
    raise exception 'profile_not_found' using errcode = 'P0002';
  end if;

  if not v_profile.role_selection_locked then
    raise exception 'onboarding_role_not_selected' using errcode = '42501';
  end if;

  if char_length(btrim(coalesce(v_profile.full_name, ''))) < 2 then
    raise exception 'invalid_onboarding_name' using errcode = '22023';
  end if;

  if v_profile.role = 'homeowner' then
    select * into v_homeowner
    from public.homeowner_profiles
    where profile_id = v_user_id;

    if not found
       or v_homeowner.apartment_type is null
       or not exists (
         select 1
         from unnest(coalesce(v_homeowner.renovation_interests, '{}'::text[]))
           as interests(interest)
         where btrim(interest) <> ''
       )
       or btrim(coalesce(v_homeowner.city, '')) = ''
       or btrim(coalesce(v_homeowner.district, '')) = '' then
      raise exception 'homeowner_onboarding_incomplete' using errcode = '22023';
    end if;
  elsif v_profile.role = 'contractor' then
    select * into v_contractor
    from public.contractor_profiles
    where profile_id = v_user_id;

    if not found
       or v_contractor.provider_kind not in (
         'contractor',
         'engineer',
         'engineering_office',
         'finishing_company',
         'interior_designer',
         'specialized_provider',
         'tradesman'
       )
       or not exists (
         select 1
         from unnest(coalesce(v_contractor.specialties, '{}'::text[]))
           as specialties(specialty)
         where btrim(specialty) <> ''
       )
       or not exists (
         select 1
         from unnest(coalesce(v_contractor.service_areas, '{}'::text[]))
           as areas(area)
         where btrim(area) <> ''
       )
       or (
         v_contractor.provider_kind in ('engineering_office', 'finishing_company')
         and char_length(btrim(coalesce(v_contractor.business_name, ''))) < 2
       ) then
      raise exception 'contractor_onboarding_incomplete' using errcode = '22023';
    end if;
  else
    raise exception 'invalid_onboarding_role' using errcode = '22023';
  end if;

  -- An idempotent retry is successful only after the persisted branch fields
  -- still satisfy the completion contract. Invalid legacy rows are repaired
  -- by the backfill above; later invalid rows stay blocked here as well.
  if v_profile.onboarding_complete then
    return false;
  end if;

  update public.profiles
  set onboarding_complete = true
  where id = v_user_id;

  return true;
end;
$$;

revoke all on function public.complete_onboarding()
  from public, anon, authenticated;
grant execute on function public.complete_onboarding()
  to authenticated;

-- Compatibility for the checked-in client, which still writes role and
-- onboarding_complete directly. A role update (including SET role = role)
-- records the one-time choice. Only the same locked role plus a corrected
-- previously-invalid name is accepted for legacy name repair.
create or replace function public.tg_guard_profile_role_selection()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Migrations, service-role jobs, and admin repair retain their trusted path.
  if auth.uid() is null then
    return new;
  end if;

  if new.id is distinct from auth.uid() then
    raise exception 'profile_owner_mismatch' using errcode = '42501';
  end if;

  if new.role is null or new.role not in ('homeowner', 'contractor') then
    raise exception 'invalid_onboarding_role' using errcode = '22023';
  end if;

  if old.role_selection_locked or old.onboarding_complete then
    if new.role is distinct from old.role then
      raise exception 'onboarding_role_locked' using errcode = '42501';
    end if;

    if new.full_name is distinct from old.full_name
       and (
         char_length(btrim(coalesce(old.full_name, ''))) >= 2
         or char_length(btrim(coalesce(new.full_name, ''))) < 2
       ) then
      raise exception 'onboarding_role_locked' using errcode = '42501';
    end if;
  elsif char_length(btrim(coalesce(new.full_name, ''))) < 2 then
    raise exception 'invalid_onboarding_name' using errcode = '22023';
  end if;

  -- The client has no UPDATE grant for this server-owned column. The trigger
  -- also makes the first explicit role assignment authoritative even when the
  -- user chose the placeholder homeowner role already present on the row.
  new.role_selection_locked := true;
  return new;
end;
$$;

revoke all on function public.tg_guard_profile_role_selection()
  from public, anon, authenticated;

drop trigger if exists guard_profile_role_selection on public.profiles;
create trigger guard_profile_role_selection
  before update of role on public.profiles
  for each row execute function public.tg_guard_profile_role_selection();

-- Legacy clients mark a profile complete after saving the final screen. Keep
-- that write compatible but make the database state authoritative: invalid
-- requests become a persisted false value and the legacy router can send the
-- user to the next missing step. The owner-checked RPC above remains strict.
create or replace function public.tg_guard_profile_onboarding_completion()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Preserve trusted service/admin repair behavior.
  if auth.uid() is null then
    return new;
  end if;

  if new.id is distinct from auth.uid() then
    raise exception 'profile_owner_mismatch' using errcode = '42501';
  end if;

  if old.onboarding_complete and not new.onboarding_complete then
    raise exception 'onboarding_completion_locked' using errcode = '42501';
  end if;

  if not new.onboarding_complete then
    return new;
  end if;

  if not new.role_selection_locked
     or char_length(btrim(coalesce(new.full_name, ''))) < 2 then
    new.onboarding_complete := false;
    return new;
  end if;

  if new.role = 'homeowner' then
    if not exists (
      select 1
      from public.homeowner_profiles hp
      where hp.profile_id = new.id
        and hp.apartment_type is not null
        and exists (
          select 1
          from unnest(coalesce(hp.renovation_interests, '{}'::text[]))
            as interests(interest)
          where btrim(interest) <> ''
        )
        and btrim(coalesce(hp.city, '')) <> ''
        and btrim(coalesce(hp.district, '')) <> ''
    ) then
      new.onboarding_complete := false;
      return new;
    end if;
  elsif new.role = 'contractor' then
    if not exists (
      select 1
      from public.contractor_profiles cp
      where cp.profile_id = new.id
        and cp.provider_kind in (
          'contractor',
          'engineer',
          'engineering_office',
          'finishing_company',
          'interior_designer',
          'specialized_provider',
          'tradesman'
        )
        and exists (
          select 1
          from unnest(coalesce(cp.specialties, '{}'::text[]))
            as specialties(specialty)
          where btrim(specialty) <> ''
        )
        and exists (
          select 1
          from unnest(coalesce(cp.service_areas, '{}'::text[]))
            as areas(area)
          where btrim(area) <> ''
        )
        and (
          cp.provider_kind not in ('engineering_office', 'finishing_company')
          or char_length(btrim(coalesce(cp.business_name, ''))) >= 2
        )
    ) then
      new.onboarding_complete := false;
      return new;
    end if;
  else
    new.onboarding_complete := false;
    return new;
  end if;

  new.role_selection_locked := true;
  return new;
end;
$$;

revoke all on function public.tg_guard_profile_onboarding_completion()
  from public, anon, authenticated;

drop trigger if exists guard_profile_onboarding_completion on public.profiles;
create trigger guard_profile_onboarding_completion
  before update of onboarding_complete on public.profiles
  for each row execute function public.tg_guard_profile_onboarding_completion();

-- Ordinary profile editing still works. Legacy role selection/completion
-- columns are writable only through the owner RLS policy and the guards above;
-- the server-owned lock column is never writable through the client API.
revoke update on table public.profiles from public, anon, authenticated;
revoke update (
  id,
  role,
  full_name,
  phone,
  avatar_url,
  onboarding_complete,
  created_at,
  updated_at,
  suspended_at,
  suspended_reason,
  role_selection_locked
) on table public.profiles from public, anon, authenticated;
grant update (role, onboarding_complete, full_name, avatar_url)
  on table public.profiles to authenticated;

alter table public.contractor_profiles
  drop constraint if exists contractor_profiles_provider_kind_check;

alter table public.contractor_profiles
  add constraint contractor_profiles_provider_kind_check
  check (provider_kind in (
    'contractor',
    'engineer',
    'engineering_office',
    'finishing_company',
    'interior_designer',
    'specialized_provider',
    'tradesman'
  ));
