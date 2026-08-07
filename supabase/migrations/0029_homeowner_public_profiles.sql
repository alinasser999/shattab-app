-- Public homeowner preview data for contractor opportunity details.
--
-- Keep this projection separate from profiles and homeowner_profiles. Both
-- source tables intentionally contain owner-only data, including phone data in
-- profiles. This table has no contact columns and is the only source exposed
-- to contractors for the homeowner preview.

create table if not exists public.homeowner_public_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  role text not null default 'homeowner' check (role = 'homeowner'),
  full_name text not null default '',
  avatar_url text,
  apartment_type text check (apartment_type in (
    'studio', 'one_bedroom', 'two_bedroom', 'three_bedroom_plus',
    'duplex', 'villa', 'penthouse'
  )),
  city text,
  district text,
  renovation_interests text[] not null default '{}',
  updated_at timestamptz not null default now()
);

create index if not exists homeowner_public_profiles_updated_at_idx
  on public.homeowner_public_profiles(updated_at desc);

alter table public.homeowner_public_profiles enable row level security;

revoke all on table public.homeowner_public_profiles from anon, authenticated;
grant select on table public.homeowner_public_profiles to authenticated;

drop policy if exists "Read homeowner public profiles" on public.homeowner_public_profiles;
create policy "Read homeowner public profiles"
  on public.homeowner_public_profiles for select
  to authenticated
  using (
    (select auth.uid()) = profile_id
    or exists (
      select 1
      from public.profiles viewer
      where viewer.id = (select auth.uid())
        and viewer.role = 'contractor'
    )
  );

-- The trigger runs with the table owner's privileges so callers can never
-- write this projection directly. It only copies explicitly approved fields.
create or replace function public.tg_sync_homeowner_public_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile_id uuid;
  v_role text;
begin
  v_profile_id := case when tg_op = 'DELETE' then old.profile_id else new.profile_id end;

  select p.role
    into v_role
  from public.profiles p
  where p.id = v_profile_id;

  if v_role is distinct from 'homeowner' then
    delete from public.homeowner_public_profiles
    where profile_id = v_profile_id;
  else
    insert into public.homeowner_public_profiles (
      profile_id,
      role,
      full_name,
      avatar_url,
      apartment_type,
      city,
      district,
      renovation_interests,
      updated_at
    )
    select
      p.id,
      'homeowner',
      p.full_name,
      p.avatar_url,
      h.apartment_type,
      h.city,
      h.district,
      coalesce(h.renovation_interests, '{}'),
      now()
    from public.profiles p
    left join public.homeowner_profiles h on h.profile_id = p.id
    where p.id = v_profile_id
    on conflict (profile_id) do update set
      role = excluded.role,
      full_name = excluded.full_name,
      avatar_url = excluded.avatar_url,
      apartment_type = excluded.apartment_type,
      city = excluded.city,
      district = excluded.district,
      renovation_interests = excluded.renovation_interests,
      updated_at = now();
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke execute on function public.tg_sync_homeowner_public_profile() from public, anon, authenticated;

drop trigger if exists sync_homeowner_public_profile_on_profile
  on public.profiles;
create trigger sync_homeowner_public_profile_on_profile
  after insert or update on public.profiles
  for each row execute function public.tg_sync_homeowner_public_profile();

drop trigger if exists sync_homeowner_public_profile_on_details
  on public.homeowner_profiles;
create trigger sync_homeowner_public_profile_on_details
  after insert or update or delete on public.homeowner_profiles
  for each row execute function public.tg_sync_homeowner_public_profile();

-- Backfill existing homeowners when this migration is applied.
insert into public.homeowner_public_profiles (
  profile_id,
  role,
  full_name,
  avatar_url,
  apartment_type,
  city,
  district,
  renovation_interests,
  updated_at
)
select
  p.id,
  'homeowner',
  p.full_name,
  p.avatar_url,
  h.apartment_type,
  h.city,
  h.district,
  coalesce(h.renovation_interests, '{}'),
  now()
from public.profiles p
left join public.homeowner_profiles h on h.profile_id = p.id
where p.role = 'homeowner'
on conflict (profile_id) do update set
  role = excluded.role,
  full_name = excluded.full_name,
  avatar_url = excluded.avatar_url,
  apartment_type = excluded.apartment_type,
  city = excluded.city,
  district = excluded.district,
  renovation_interests = excluded.renovation_interests,
  updated_at = now();
