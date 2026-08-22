-- Durable contractor bookmarks for opportunities.
-- SharedPreferences remains only a short-lived offline fallback in the client;
-- the server is the source of truth when a session is available.

create table if not exists public.saved_briefs (
  contractor_id uuid not null references public.profiles(id) on delete cascade,
  brief_id uuid not null references public.briefs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (contractor_id, brief_id)
);

create index if not exists saved_briefs_contractor_created_idx
  on public.saved_briefs (contractor_id, created_at desc, brief_id);

alter table public.saved_briefs enable row level security;

revoke all on public.saved_briefs from public, anon, authenticated;
grant select, insert, delete on public.saved_briefs to authenticated;

drop policy if exists "contractor_read_own_saved_briefs"
  on public.saved_briefs;
create policy "contractor_read_own_saved_briefs"
  on public.saved_briefs for select
  to authenticated
  using ((select auth.uid()) = contractor_id);

drop policy if exists "contractor_save_visible_briefs"
  on public.saved_briefs;
create policy "contractor_save_visible_briefs"
  on public.saved_briefs for insert
  to authenticated
  with check (
    (select auth.uid()) = contractor_id
    and exists (
      select 1
      from public.profiles p
      where p.id = contractor_id
        and p.role = 'contractor'
    )
    and exists (
      select 1
      from public.briefs b
      where b.id = brief_id
        and b.status = 'open'
        and (
          b.target_contractor_id is null
          or b.target_contractor_id = (select auth.uid())
        )
    )
  );

drop policy if exists "contractor_delete_own_saved_briefs"
  on public.saved_briefs;
create policy "contractor_delete_own_saved_briefs"
  on public.saved_briefs for delete
  to authenticated
  using ((select auth.uid()) = contractor_id);

comment on table public.saved_briefs is
  'Durable contractor bookmarks for visible opportunities; no contact data.';
