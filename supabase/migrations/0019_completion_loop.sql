-- 0019_completion_loop — job completion as real state.
--
-- Two defects this fixes:
--
-- 1. Reviews measured hiring, not work. The reviews insert policy (0006) only
--    required a quote at status 'accepted', and accept_quote() (0009) sets
--    hired_at at that same moment — so a homeowner could post a five-star
--    review the instant they hired, before any work happened.
--
-- 2. contractor_profiles.projects_completed (0003) is `int not null default 0`
--    and nothing has ever written to it. Every "مشروع مكتمل" figure in the app
--    is permanently 0 unless edited by hand.
--
-- Completion requires the payer's confirmation: a contractor may signal that
-- work is done, but only the homeowner sets completed_at. Letting the supply
-- side self-certify the fact that unlocks its own reviews and public project
-- count puts the incentive in the wrong place.

alter table public.briefs
  add column if not exists completion_requested_at timestamptz,
  add column if not exists completed_at timestamptz;

-- Finding a hired brief's contractor means "who holds the accepted quote".
create index if not exists quotes_brief_accepted_idx
  on public.quotes (brief_id)
  where status = 'accepted';

-- ── Contractor signals work is finished ─────────────────────────────────────
-- A nudge, not a state change to completion. Idempotent: repeat calls keep the
-- original timestamp so a double tap cannot bump the brief up the homeowner's
-- list repeatedly.
create or replace function public.request_completion(p_brief_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_hired_at timestamptz;
begin
  select hired_at into v_hired_at
  from public.briefs
  where id = p_brief_id;

  if not found then
    raise exception 'brief_not_found';
  end if;

  if v_hired_at is null then
    raise exception 'not_hired';
  end if;

  -- Caller must be the contractor whose quote was accepted on this brief.
  if not exists (
    select 1 from public.quotes q
    where q.brief_id = p_brief_id
      and q.contractor_id = auth.uid()
      and q.status = 'accepted'
  ) then
    raise exception 'not_authorized';
  end if;

  update public.briefs
    set completion_requested_at = now()
    where id = p_brief_id
      and completion_requested_at is null;
end;
$$;

-- ── Homeowner confirms the work is done ─────────────────────────────────────
-- This is the transition that unlocks reviews and increments the contractor's
-- completed-project count. Idempotent via the `completed_at is null` guard, so
-- a retry after a dropped connection cannot double-count.
create or replace function public.confirm_completion(p_brief_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_hired_at timestamptz;
  v_homeowner uuid;
begin
  select hired_at, homeowner_id into v_hired_at, v_homeowner
  from public.briefs
  where id = p_brief_id;

  if not found then
    raise exception 'brief_not_found';
  end if;

  if v_homeowner <> auth.uid() then
    raise exception 'not_authorized';
  end if;

  if v_hired_at is null then
    raise exception 'not_hired';
  end if;

  update public.briefs
    set completed_at = now()
    where id = p_brief_id
      and completed_at is null;
end;
$$;

-- `from public` alone is not enough: Supabase's default privileges grant these
-- directly to anon and authenticated, so the PUBLIC revoke leaves anon holding
-- EXECUTE. Both bodies check auth.uid(), so an anon caller would fail the guard
-- rather than the permission check — the right outcome by luck, not by design.
-- See 0021_admin_rpc_lockdown for the incident this pattern caused.
revoke all on function public.request_completion(uuid) from public;
revoke all on function public.confirm_completion(uuid) from public;
revoke execute on function public.request_completion(uuid) from anon;
revoke execute on function public.confirm_completion(uuid) from anon;
grant execute on function public.request_completion(uuid) to authenticated;
grant execute on function public.confirm_completion(uuid) to authenticated;

-- ── projects_completed becomes derived ──────────────────────────────────────
-- Fires only on the null → non-null transition of completed_at, so no other
-- update to the row can double-increment. The counter is now a fact about
-- confirmed work rather than a column nobody writes.
create or replace function public.tg_bump_projects_completed()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if old.completed_at is null and new.completed_at is not null then
    update public.contractor_profiles cp
      set projects_completed = cp.projects_completed + 1
      where cp.profile_id = (
        select q.contractor_id from public.quotes q
        where q.brief_id = new.id and q.status = 'accepted'
        limit 1
      );
  end if;
  return new;
end;
$$;

-- Trigger functions have no business being reachable at /rest/v1/rpc.
revoke execute on function public.tg_bump_projects_completed()
  from public, anon, authenticated;

drop trigger if exists bump_projects_completed on public.briefs;
create trigger bump_projects_completed
  after update of completed_at on public.briefs
  for each row execute function public.tg_bump_projects_completed();

-- ── Reviews now require confirmed completion ────────────────────────────────
-- Same policy as 0006 plus the completed_at requirement. Without this the app
-- can show a review button that the database rejects.
drop policy if exists "reviews_homeowner_insert" on public.reviews;
create policy "reviews_homeowner_insert" on public.reviews
  for insert with check (
    homeowner_id = auth.uid()
    and exists (
      select 1 from public.briefs b
      where b.id = brief_id
        and b.homeowner_id = auth.uid()
        and b.completed_at is not null
    )
    and exists (
      select 1 from public.quotes q
      where q.brief_id = reviews.brief_id
        and q.contractor_id = reviews.contractor_id
        and q.status = 'accepted'
    )
  );

-- No backfill. There is no record of which past jobs were actually finished,
-- and inventing completions would recreate the problem this migration fixes.
