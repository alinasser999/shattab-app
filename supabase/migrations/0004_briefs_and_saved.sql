-- 0004_briefs_and_saved — briefs (posts + direct requests) + saved contractors
-- Applied live on Supabase 2026-05-16; now written to disk for migration completeness.

-- ── briefs ───────────────────────────────────────────────────────────────────

create table if not exists public.briefs (
  id uuid primary key default gen_random_uuid(),
  homeowner_id uuid not null references public.profiles(id),
  target_contractor_id uuid references public.profiles(id),  -- null = public post
  apartment_type text not null,
  city text not null,
  district text,
  work_description text not null,
  photo_urls text[] not null default '{}',
  target_specialties text[] not null default '{}',
  status text not null default 'open' check (status in ('open', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists briefs_homeowner_idx on public.briefs(homeowner_id);
create index if not exists briefs_contractor_target_idx on public.briefs(target_contractor_id);
create index if not exists briefs_open_posts_idx on public.briefs(status) where status = 'open' and target_contractor_id is null;
create index if not exists briefs_target_specialties_idx on public.briefs using gin (target_specialties);

drop trigger if exists set_briefs_updated_at on public.briefs;
create trigger set_briefs_updated_at before update on public.briefs
  for each row execute procedure public.tg_set_updated_at();

-- ── RLS (briefs) ─────────────────────────────────────────────────────────────

alter table public.briefs enable row level security;

-- Homeowner: full CRUD on own briefs
drop policy if exists "homeowner_all" on public.briefs;
create policy "homeowner_all"
  on public.briefs for all
  using (homeowner_id = auth.uid())
  with check (homeowner_id = auth.uid());

-- Contractor: read open public posts (not targeted at a specific contractor)
drop policy if exists "contractor_read_open" on public.briefs;
create policy "contractor_read_open"
  on public.briefs for select
  using (
    status = 'open'
    and target_contractor_id is null
  );

-- Contractor: read direct briefs targeted at them
drop policy if exists "contractor_read_targeted" on public.briefs;
create policy "contractor_read_targeted"
  on public.briefs for select
  using (target_contractor_id = auth.uid());

-- ── saved_contractors ────────────────────────────────────────────────────────

create table if not exists public.saved_contractors (
  homeowner_id uuid not null references public.profiles(id),
  contractor_id uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  primary key (homeowner_id, contractor_id)
);

create index if not exists saved_contractors_homeowner_idx
  on public.saved_contractors(homeowner_id);

alter table public.saved_contractors enable row level security;

drop policy if exists "homeowner_manage_saved" on public.saved_contractors;
create policy "homeowner_manage_saved"
  on public.saved_contractors for all
  using (homeowner_id = auth.uid())
  with check (homeowner_id = auth.uid());
