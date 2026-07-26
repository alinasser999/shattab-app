-- 0025_free_quote_quota — let free contractors quote, up to a monthly cap.
--
-- Before this, `contractor_insert_own` (0013_monetization) required
-- `plan = 'pro' AND plan_expires_at > now()`. A free contractor could not
-- insert a single quote — not rate-limited, blocked outright at the database.
--
-- In a two-sided marketplace before liquidity exists that is fatal. The
-- homeowner posts a brief and receives no offers; the contractor browses jobs
-- he cannot bid on. Neither side ever sees the product work, so neither
-- converts, and the paywall protects revenue that was never going to arrive.
-- The live numbers agree: 13 contractors, 1 quote.
--
-- New rule: Pro is unlimited; everyone else gets `free_quote_limit()` quotes
-- per rolling 30 days. The contractor wins a job first and is asked to pay
-- second.

-- Single source of truth for the cap, so the policy and the quota RPC below
-- cannot drift apart and changing the number is a one-line edit.
create or replace function public.free_quote_limit()
returns int
language sql
immutable
set search_path = public
as $$ select 5 $$;

-- The count is over quotes the contractor *sent*, in a rolling window rather
-- than a calendar month — a calendar reset would hand everyone a fresh batch at
-- midnight on the 1st and concentrate load there.
--
-- Deleting a quote frees a slot. That is deliberate rather than overlooked: the
-- quote disappears from the homeowner too, so the contractor gives up the lead
-- to reclaim the credit, which is not a trade worth policing.
drop policy if exists "contractor_insert_own" on public.quotes;
create policy "contractor_insert_own" on public.quotes
  for insert with check (
    contractor_id = (select auth.uid())
    and status = 'sent'
    and (
      exists (
        select 1 from public.contractor_profiles cp
        where cp.profile_id = (select auth.uid())
          and cp.plan = 'pro'
          and cp.plan_expires_at > now()
      )
      or (
        select count(*) from public.quotes q
        where q.contractor_id = (select auth.uid())
          and q.created_at > now() - interval '30 days'
      ) < public.free_quote_limit()
    )
  );

-- Supports the counting subquery above and the RPC below. quotes(contractor_id)
-- exists from 0005; the composite lets the window filter use the index too.
create index if not exists quotes_contractor_created_idx
  on public.quotes (contractor_id, created_at desc);

-- Lets the client show "3 of 5 left this month" instead of discovering the cap
-- by having an insert rejected. SECURITY INVOKER on purpose: RLS already limits
-- `quotes` to the caller's own rows, so the count is correct without elevating.
create or replace function public.my_quote_quota()
returns table(is_pro boolean, used int, quota int)
language sql
stable
set search_path = public
as $$
  select
    exists (
      select 1 from public.contractor_profiles cp
      where cp.profile_id = (select auth.uid())
        and cp.plan = 'pro'
        and cp.plan_expires_at > now()
    ),
    (
      select count(*)::int from public.quotes q
      where q.contractor_id = (select auth.uid())
        and q.created_at > now() - interval '30 days'
    ),
    public.free_quote_limit();
$$;

revoke all on function public.my_quote_quota() from public, anon;
grant execute on function public.my_quote_quota() to authenticated;

revoke all on function public.free_quote_limit() from public, anon;
grant execute on function public.free_quote_limit() to authenticated;
