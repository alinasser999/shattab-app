-- 0016_accept_quote_guard — make accept_quote idempotent / single-winner.
--
-- Bug (found in production audit): accept_quote() only declines sibling quotes
-- whose status = 'sent'. If a brief is accepted twice (double-tap, or a second
-- accept after the first), the first 'accepted' quote is NOT 'sent', so it stays
-- 'accepted' while the new one also becomes 'accepted' → two accepted quotes on
-- one brief. Guard on briefs.hired_at so only the first accept wins.
--
-- Safe to run more than once (create or replace).

create or replace function public.accept_quote(p_quote_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_brief uuid;
  v_hired timestamptz;
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

  -- Single-winner: refuse a second accept once the brief is hired.
  select hired_at into v_hired from public.briefs where id = v_brief;
  if v_hired is not null then
    raise exception 'already_hired';
  end if;

  update public.quotes set status = 'accepted' where id = p_quote_id;
  update public.quotes set status = 'declined'
    where brief_id = v_brief and id <> p_quote_id and status = 'sent';
  update public.briefs set hired_at = now() where id = v_brief;
end;
$$;
