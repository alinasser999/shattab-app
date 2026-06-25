-- Batsh M1 — initial schema: profiles, homeowner_profiles, contractor_profiles
-- Mirrors design spec section 3.4.

-- ── Tables ──────────────────────────────────────────────────────────────────

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('homeowner', 'contractor')),
  full_name text not null default '',
  phone text not null default '',
  avatar_url text,
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_role_idx on public.profiles(role);

create table if not exists public.homeowner_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  apartment_type text check (apartment_type in (
    'studio', 'one_bedroom', 'two_bedroom', 'three_bedroom_plus',
    'duplex', 'villa', 'penthouse'
  )),
  city text,
  district text,
  renovation_interests text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.contractor_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  business_name text,
  logo_url text,
  bio text,
  specialties text[] not null default '{}',
  service_areas text[] not null default '{}',
  years_experience int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists contractor_specialties_idx
  on public.contractor_profiles using gin (specialties);
create index if not exists contractor_service_areas_idx
  on public.contractor_profiles using gin (service_areas);

-- ── Triggers ────────────────────────────────────────────────────────────────

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'role', 'homeowner'),
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.phone, '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at before update on public.profiles
  for each row execute procedure public.tg_set_updated_at();

drop trigger if exists set_homeowner_updated_at on public.homeowner_profiles;
create trigger set_homeowner_updated_at before update on public.homeowner_profiles
  for each row execute procedure public.tg_set_updated_at();

drop trigger if exists set_contractor_updated_at on public.contractor_profiles;
create trigger set_contractor_updated_at before update on public.contractor_profiles
  for each row execute procedure public.tg_set_updated_at();

-- ── RLS ─────────────────────────────────────────────────────────────────────

alter table public.profiles enable row level security;
alter table public.homeowner_profiles enable row level security;
alter table public.contractor_profiles enable row level security;

drop policy if exists "Read own profile" on public.profiles;
create policy "Read own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "Read public contractor profiles" on public.profiles;
create policy "Read public contractor profiles"
  on public.profiles for select
  using (role = 'contractor');

drop policy if exists "Update own profile" on public.profiles;
create policy "Update own profile"
  on public.profiles for update
  using (auth.uid() = id);

drop policy if exists "Owner read/write homeowner profile" on public.homeowner_profiles;
create policy "Owner read/write homeowner profile"
  on public.homeowner_profiles for all
  using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

drop policy if exists "Anyone read contractor profile" on public.contractor_profiles;
create policy "Anyone read contractor profile"
  on public.contractor_profiles for select using (true);

drop policy if exists "Owner write contractor profile" on public.contractor_profiles;
create policy "Owner write contractor profile"
  on public.contractor_profiles for insert
  with check (auth.uid() = profile_id);

drop policy if exists "Owner update contractor profile" on public.contractor_profiles;
create policy "Owner update contractor profile"
  on public.contractor_profiles for update
  using (auth.uid() = profile_id);
