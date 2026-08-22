-- Wrap auth.uid() in `(select auth.uid())` across RLS policies so Postgres
-- caches the result once per query instead of re-evaluating per row.
-- Pure query-plan optimization: every USING/WITH CHECK predicate below is
-- logically identical to what it replaces. Flagged by Supabase's own
-- `auth_rls_initplan` performance lint ahead of go-live.

-- Replayability guard: portfolio_projects was created live in M3 and never
-- landed in an earlier migration, yet the policies below (and the posts FK
-- in 0008) reference it. On production this is a no-op; on a fresh replay
-- it creates the exact table shape extracted from live on 2026-08-22,
-- before the first policy touches it.
create table if not exists public.portfolio_projects (
  id uuid primary key default gen_random_uuid(),
  contractor_id uuid not null references public.profiles(id) on delete cascade,
  title text not null constraint portfolio_projects_title_check
    check (length(title) >= 2 and length(title) <= 120),
  description text,
  cover_photo_url text not null,
  photo_urls text[] not null default '{}'::text[],
  category text,
  apartment_type text,
  location text,
  year_completed integer,
  "position" integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists portfolio_contractor_idx
  on public.portfolio_projects (contractor_id, "position" desc, created_at desc);

drop trigger if exists set_portfolio_updated_at on public.portfolio_projects;
create trigger set_portfolio_updated_at
  before update on public.portfolio_projects
  for each row execute function public.tg_set_updated_at();

-- briefs
drop policy if exists "contractor read direct briefs" on public.briefs;
create policy "contractor read direct briefs" on public.briefs
  for select
  using ((select auth.uid()) = target_contractor_id);

drop policy if exists "contractor read matched open posts" on public.briefs;
create policy "contractor read matched open posts" on public.briefs
  for select
  using (
    target_contractor_id is null
    and status = 'open'
    and exists (
      select 1 from public.contractor_profiles cp
      where cp.profile_id = (select auth.uid())
        and briefs.target_specialties && cp.specialties
        and briefs.city = any (cp.service_areas)
    )
  );

drop policy if exists "homeowner own briefs" on public.briefs;
create policy "homeowner own briefs" on public.briefs
  for all
  using ((select auth.uid()) = homeowner_id)
  with check ((select auth.uid()) = homeowner_id);

-- contractor_profiles
drop policy if exists "Owner update contractor profile" on public.contractor_profiles;
create policy "Owner update contractor profile" on public.contractor_profiles
  for update
  using ((select auth.uid()) = profile_id);

drop policy if exists "Owner write contractor profile" on public.contractor_profiles;
create policy "Owner write contractor profile" on public.contractor_profiles
  for insert
  with check ((select auth.uid()) = profile_id);

-- homeowner_profiles
drop policy if exists "Owner read/write homeowner profile" on public.homeowner_profiles;
create policy "Owner read/write homeowner profile" on public.homeowner_profiles
  for all
  using ((select auth.uid()) = profile_id)
  with check ((select auth.uid()) = profile_id);

-- portfolio_projects
drop policy if exists "owner delete portfolio" on public.portfolio_projects;
create policy "owner delete portfolio" on public.portfolio_projects
  for delete
  using ((select auth.uid()) = contractor_id);

drop policy if exists "owner update portfolio" on public.portfolio_projects;
create policy "owner update portfolio" on public.portfolio_projects
  for update
  using ((select auth.uid()) = contractor_id);

drop policy if exists "owner write portfolio" on public.portfolio_projects;
create policy "owner write portfolio" on public.portfolio_projects
  for insert
  with check ((select auth.uid()) = contractor_id);

-- profiles
drop policy if exists "Read own profile" on public.profiles;
create policy "Read own profile" on public.profiles
  for select
  using ((select auth.uid()) = id);

drop policy if exists "Update own profile" on public.profiles;
create policy "Update own profile" on public.profiles
  for update
  using ((select auth.uid()) = id);

-- quotes
drop policy if exists "contractor_own" on public.quotes;
create policy "contractor_own" on public.quotes
  for all
  using (contractor_id = (select auth.uid()))
  with check (contractor_id = (select auth.uid()));

drop policy if exists "homeowner_read" on public.quotes;
create policy "homeowner_read" on public.quotes
  for select
  using (exists (
    select 1 from public.briefs b
    where b.id = quotes.brief_id and b.homeowner_id = (select auth.uid())
  ));

drop policy if exists "homeowner_status" on public.quotes;
create policy "homeowner_status" on public.quotes
  for update
  using (exists (
    select 1 from public.briefs b
    where b.id = quotes.brief_id and b.homeowner_id = (select auth.uid())
  ))
  with check (status = any (array['accepted', 'declined']));

-- reviews
drop policy if exists "reviews_homeowner_insert" on public.reviews;
create policy "reviews_homeowner_insert" on public.reviews
  for insert
  with check (
    homeowner_id = (select auth.uid())
    and exists (
      select 1 from public.briefs b
      where b.id = reviews.brief_id and b.homeowner_id = (select auth.uid())
    )
    and exists (
      select 1 from public.quotes q
      where q.brief_id = reviews.brief_id
        and q.contractor_id = reviews.contractor_id
        and q.status = 'accepted'
    )
  );

drop policy if exists "reviews_homeowner_update" on public.reviews;
create policy "reviews_homeowner_update" on public.reviews
  for update
  using (homeowner_id = (select auth.uid()))
  with check (homeowner_id = (select auth.uid()));

-- saved_contractors
drop policy if exists "owner full access saved contractors" on public.saved_contractors;
create policy "owner full access saved contractors" on public.saved_contractors
  for all
  using ((select auth.uid()) = homeowner_id)
  with check ((select auth.uid()) = homeowner_id);
