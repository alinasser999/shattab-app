-- Fix quote submission RLS recursion without weakening the quota.
--
-- The previous policy counted rows directly from public.quotes while
-- PostgreSQL was evaluating a policy on public.quotes. That recursively
-- re-entered the policy and rejected every new quote with:
--   infinite recursion detected in policy for relation "quotes"
--
-- Keep the count behind a tightly scoped SECURITY DEFINER helper. The helper
-- only reads rows for auth.uid(), uses a fixed search_path, and is callable by
-- authenticated users because the INSERT policy invokes it on their behalf.

create or replace function public.can_submit_quote(p_brief_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    exists (
      select 1
      from public.contractor_profiles cp
      where cp.profile_id = (select auth.uid())
        and cp.plan = 'pro'
        and cp.plan_expires_at > now()
    )
    or exists (
      select 1
      from public.quotes q
      where q.contractor_id = (select auth.uid())
        and q.brief_id = p_brief_id
    )
    or (
      select count(*)
      from public.quotes q
      where q.contractor_id = (select auth.uid())
        and q.created_at > now() - interval '30 days'
    ) < public.free_quote_limit();
$$;

revoke all on function public.can_submit_quote(uuid) from public, anon;
grant execute on function public.can_submit_quote(uuid) to authenticated;

drop policy if exists "contractor_insert_own" on public.quotes;
create policy "contractor_insert_own" on public.quotes
  for insert to public
  with check (
    contractor_id = (select auth.uid())
    and status = 'sent'
    and public.can_submit_quote(brief_id)
  );
