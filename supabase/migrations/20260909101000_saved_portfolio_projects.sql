-- Optional homeowner saves for portfolio project detail pages.

create table if not exists public.saved_portfolio_projects (
  homeowner_id uuid not null references public.profiles(id) on delete cascade,
  project_id uuid not null references public.portfolio_projects(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (homeowner_id, project_id)
);

create index if not exists saved_portfolio_projects_homeowner_idx
  on public.saved_portfolio_projects(homeowner_id, created_at desc);

alter table public.saved_portfolio_projects enable row level security;

-- The Flutter client reads save state and upserts/deletes a homeowner's own
-- bookmark. Keep those API privileges explicit: table defaults differ across
-- Supabase versions and anonymous users must not reach this table.
revoke all privileges on table public.saved_portfolio_projects
  from public, anon, authenticated;
grant select, insert, update, delete
  on table public.saved_portfolio_projects to authenticated;

drop policy if exists "homeowner_manage_saved_portfolio_projects"
  on public.saved_portfolio_projects;
create policy "homeowner_manage_saved_portfolio_projects"
  on public.saved_portfolio_projects for all to authenticated
  using (
    homeowner_id = (select auth.uid())
    and exists (
      select 1
      from public.profiles p
      where p.id = homeowner_id
        and p.role = 'homeowner'
    )
  )
  with check (
    homeowner_id = (select auth.uid())
    and exists (
      select 1
      from public.profiles p
      where p.id = homeowner_id
        and p.role = 'homeowner'
    )
  );
