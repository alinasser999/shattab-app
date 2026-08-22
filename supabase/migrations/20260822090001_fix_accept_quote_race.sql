-- Closes the double-accept hole found in the 2026-08 production audit.
--
-- Two defects, both still live:
--   1. TOCTOU in accept_quote(): hired_at was read with a plain SELECT and the
--      claiming UPDATE carried no "hired_at is null" predicate, so two
--      concurrent accepts (double-tap, two devices) could both pass the guard
--      and land two accepted quotes on one brief.
--   2. The homeowner_status RLS policy allowed setting status='accepted'
--      directly through PostgREST, bypassing the RPC entirely: no sibling
--      declines, no hired_at write, no single-winner check.
--
-- This migration closes both doors:
--   - The RPC claims the brief atomically (conditional UPDATE + rowcount),
--     mirroring the pattern approve_payment_request already uses.
--   - The policy is narrowed to declined-only; accepting must go through the
--     RPC (verified: the Flutter client already routes accepts exclusively
--     through accept_quote).
--   - A trigger makes the RPC the only door to 'accepted', so a future
--     policy regression cannot silently reopen the bypass. The RPC marks its
--     transaction with a session-local GUC the trigger checks.

create or replace function public.accept_quote(p_quote_id uuid)
returns void
language plpgsql
security definer set search_path = public, pg_temp
as $$
declare
  v_brief uuid;
begin
  select brief_id into v_brief from public.quotes where id = p_quote_id;
  if v_brief is null then
    raise exception 'quote_not_found';
  end if;
  if not exists (
    select 1 from public.briefs b
    where b.id = v_brief and b.homeowner_id = auth.uid()
  ) then
    raise exception 'not_authorized';
  end if;

  -- Mark this transaction as the sanctioned accept path for the trigger gate.
  perform set_config('app.quote_accept_rpc', 'on', true);

  -- Single-winner claim: only one caller can flip hired_at from null. The
  -- row lock taken here serializes concurrent accepts; a second caller's
  -- UPDATE matches zero rows once the first commits.
  update public.briefs set hired_at = now()
    where id = v_brief and hired_at is null;
  if not found then
    raise exception 'already_hired';
  end if;

  update public.quotes set status = 'accepted' where id = p_quote_id;
  update public.quotes set status = 'declined'
    where brief_id = v_brief and id <> p_quote_id and status = 'sent';
end;
$$;

revoke execute on function public.accept_quote(uuid)
  from public, anon;
grant execute on function public.accept_quote(uuid)
  to authenticated;

-- Gate: only a transaction running inside accept_quote() may move a quote
-- into 'accepted'. Everything else (direct REST writes, future code paths)
-- is rejected at the door.
create or replace function public.tg_only_rpc_accepts_quotes()
returns trigger
language plpgsql
security definer set search_path = public, pg_temp
as $$
begin
  if new.status = 'accepted'
     and old.status is distinct from 'accepted'
     and coalesce(current_setting('app.quote_accept_rpc', true), 'off') <> 'on'
  then
    raise exception 'use_accept_quote_rpc' using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke execute on function public.tg_only_rpc_accepts_quotes()
  from public, anon, authenticated;

drop trigger if exists only_rpc_accepts_quotes on public.quotes;
create trigger only_rpc_accepts_quotes
  before insert or update on public.quotes
  for each row execute function public.tg_only_rpc_accepts_quotes();

-- Homeowner keeps decline; accept is RPC-only now.
drop policy if exists "homeowner_status" on public.quotes;
create policy "homeowner_status" on public.quotes
  for update
  using (exists (
    select 1 from public.briefs b
    where b.id = quotes.brief_id and b.homeowner_id = (select auth.uid())
  ))
  with check (status = 'declined');
