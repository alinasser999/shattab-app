-- Keep accept_quote from reviving a withdrawn/declined quote or hiring from a
-- cancelled/already-hired brief. The existing atomic hired_at claim closes the
-- double-accept race, but its broad UPDATE predicates still allowed an old
-- quote id to be promoted after its lifecycle had ended.

create or replace function public.accept_quote(p_quote_id uuid)
returns void
language plpgsql
security definer set search_path = public, pg_temp
as $$
declare
  v_brief uuid;
  v_quote_status text;
  v_brief_status text;
  v_hired_at timestamptz;
begin
  select brief_id, status
    into v_brief, v_quote_status
    from public.quotes
    where id = p_quote_id;
  if not found or v_brief is null then
    raise exception 'quote_not_found';
  end if;

  if not exists (
    select 1 from public.briefs b
    where b.id = v_brief and b.homeowner_id = auth.uid()
  ) then
    raise exception 'not_authorized';
  end if;

  if v_quote_status is distinct from 'sent' then
    raise exception 'quote_not_open';
  end if;

  -- Mark this transaction as the sanctioned accept path for the trigger gate.
  perform set_config('app.quote_accept_rpc', 'on', true);

  -- Claim only an open, un-hired brief. The conditional UPDATE both takes the
  -- row lock and prevents a cancelled brief from being accepted.
  update public.briefs
     set hired_at = now()
   where id = v_brief
     and homeowner_id = auth.uid()
     and status = 'open'
     and hired_at is null;
  if not found then
    select status, hired_at
      into v_brief_status, v_hired_at
      from public.briefs
      where id = v_brief;
    if not found then
      raise exception 'brief_not_found';
    end if;
    if v_hired_at is not null then
      raise exception 'already_hired';
    end if;
    raise exception 'brief_not_open';
  end if;

  -- Re-check the quote in the write predicate as well: a contractor may have
  -- withdrawn it after the initial read while this transaction was waiting.
  update public.quotes
     set status = 'accepted'
   where id = p_quote_id
     and brief_id = v_brief
     and status = 'sent';
  if not found then
    raise exception 'quote_not_open';
  end if;

  update public.quotes
     set status = 'declined'
   where brief_id = v_brief
     and id <> p_quote_id
     and status = 'sent';
end;
$$;

revoke execute on function public.accept_quote(uuid)
  from public, anon;
grant execute on function public.accept_quote(uuid)
  to authenticated;
