-- Privacy-safe product telemetry.
--
-- The mobile client writes only the current user's action rows. Operations
-- reads them through the existing admin boundary; there is intentionally no
-- client SELECT policy and no free-text/user-contact payload contract.
create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  event_name text not null check (event_name ~ '^[a-z0-9_]{1,80}$'),
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists analytics_events_user_created_idx
  on public.analytics_events (user_id, created_at desc);
create index if not exists analytics_events_name_created_idx
  on public.analytics_events (event_name, created_at desc);

alter table public.analytics_events enable row level security;
revoke all on public.analytics_events from public, anon, authenticated;
grant insert on public.analytics_events to authenticated;

drop policy if exists "analytics_insert_own" on public.analytics_events;
create policy "analytics_insert_own" on public.analytics_events
  for insert to authenticated
  with check ((select auth.uid()) = user_id);
