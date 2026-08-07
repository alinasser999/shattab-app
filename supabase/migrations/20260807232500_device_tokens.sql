-- Push delivery targets.
--
-- Realtime (20260807231500) closed the foreground gap: a user with the app open
-- now sees a quote land without touching anything. This table closes the other
-- one — the app is shut, the socket is gone, and the notification row that
-- 20260803202740's triggers just wrote has nowhere to go.
--
-- One row per device, not per user. A contractor with a phone and a tablet gets
-- both, and the token is the primary key so a device handed to a second account
-- re-points instead of accumulating: the upsert rewrites `user_id`, and the
-- previous owner stops receiving on hardware they no longer hold. That is a
-- privacy property, not housekeeping.

create table if not exists public.device_tokens (
  token       text primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  platform    text not null check (platform in ('android', 'ios')),
  -- Notifications are stored as l10n keys, so something has to choose a
  -- language at send time. The device knows; the database would be guessing.
  -- Per-device rather than per-user because the setting it mirrors
  -- (`localeProvider`) is a device preference too.
  locale      text not null default 'ar' check (locale in ('ar', 'en')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists device_tokens_user_idx
  on public.device_tokens (user_id);

drop trigger if exists set_updated_at on public.device_tokens;
create trigger set_updated_at
  before update on public.device_tokens
  for each row execute function public.tg_set_updated_at();

alter table public.device_tokens enable row level security;
revoke all on public.device_tokens from public, anon, authenticated;
grant select, insert, update, delete on public.device_tokens to authenticated;

-- A client may only ever speak for itself. The Edge Function that fans
-- notifications out runs with the service role and bypasses these policies,
-- which is the only context with any business reading another user's tokens.
drop policy if exists "device_tokens_select_own" on public.device_tokens;
create policy "device_tokens_select_own" on public.device_tokens
  for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "device_tokens_insert_own" on public.device_tokens;
create policy "device_tokens_insert_own" on public.device_tokens
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- USING is permissive on the row's *current* owner so a device changing hands
-- can be claimed; WITH CHECK still forces the resulting row to belong to the
-- caller, so this grants re-pointing, not theft.
drop policy if exists "device_tokens_update_own" on public.device_tokens;
create policy "device_tokens_update_own" on public.device_tokens
  for update to authenticated
  using (true)
  with check ((select auth.uid()) = user_id);

drop policy if exists "device_tokens_delete_own" on public.device_tokens;
create policy "device_tokens_delete_own" on public.device_tokens
  for delete to authenticated
  using ((select auth.uid()) = user_id);
