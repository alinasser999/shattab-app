-- 0020_brief_edit_delete — let a homeowner edit and remove their own brief
-- without destroying contractors' work.
--
-- RLS already permits both: policy "homeowner_all" (0004) is `for all` on
-- briefs where homeowner_id = auth.uid(). What is missing is the safety around
-- it, which is why this is a migration and not just client code:
--
-- 1. `briefs` cascades to `quotes` on delete (0004). A homeowner deleting a
--    brief that already has offers silently erases every quote contractors
--    wrote against it. Deletion has to be conditional, and the condition has to
--    be evaluated atomically on the server, not checked by the client first.
-- 2. Editing the scope after contractors have quoted moves the deal under them.
--    Edits stay allowed, but they leave a mark.
-- 3. Nothing stopped a homeowner rewriting a brief after hiring someone.

alter table public.briefs
  add column if not exists edited_at timestamptz;

-- ── Edit guard + edited_at stamp ────────────────────────────────────────────
-- Only fires when the *scope* actually changes. Ordinary lifecycle updates
-- (hired_at, completion_requested_at, completed_at, status) pass straight
-- through, so this cannot interfere with accept_quote or the 0019 completion
-- RPCs.
create or replace function public.tg_guard_brief_edit()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_scope_changed boolean;
begin
  v_scope_changed :=
       new.work_description   is distinct from old.work_description
    or new.apartment_type     is distinct from old.apartment_type
    or new.city               is distinct from old.city
    or new.district           is distinct from old.district
    or new.target_specialties is distinct from old.target_specialties
    or new.photo_urls         is distinct from old.photo_urls;

  if not v_scope_changed then
    return new;
  end if;

  -- Once someone is hired the brief describes work in progress. Rewriting it
  -- then would change what was agreed after the fact.
  if old.hired_at is not null then
    raise exception 'brief_locked';
  end if;

  new.edited_at := now();
  return new;
end;
$$;

-- Trigger functions have no business being reachable at /rest/v1/rpc.
revoke execute on function public.tg_guard_brief_edit()
  from public, anon, authenticated;

drop trigger if exists guard_brief_edit on public.briefs;
create trigger guard_brief_edit
  before update on public.briefs
  for each row execute function public.tg_guard_brief_edit();

-- ── Remove a brief without erasing contractors' work ────────────────────────
-- Hard delete only while nobody has invested effort. The moment a quote exists,
-- "delete" degrades to cancel: the brief stays visible as cancelled and every
-- contractor keeps their quote history. Returns which path it took so the UI
-- can tell the user what actually happened.
create or replace function public.delete_or_cancel_brief(p_brief_id uuid)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_homeowner uuid;
  v_has_quotes boolean;
begin
  select homeowner_id into v_homeowner
  from public.briefs
  where id = p_brief_id;

  if not found then
    raise exception 'brief_not_found';
  end if;

  if v_homeowner <> auth.uid() then
    raise exception 'not_authorized';
  end if;

  select exists (
    select 1 from public.quotes q where q.brief_id = p_brief_id
  ) into v_has_quotes;

  if v_has_quotes then
    update public.briefs
      set status = 'cancelled'
      where id = p_brief_id;
    return 'cancelled';
  end if;

  delete from public.briefs where id = p_brief_id;
  return 'deleted';
end;
$$;

-- See the note in 0019: revoking PUBLIC leaves Supabase's direct default grant
-- to anon in place, so revoke that explicitly too.
revoke all on function public.delete_or_cancel_brief(uuid) from public;
revoke execute on function public.delete_or_cancel_brief(uuid) from anon;
grant execute on function public.delete_or_cancel_brief(uuid) to authenticated;

-- Note: a hired brief always has quotes, so it can only ever be cancelled here,
-- never deleted. Cancelling work already underway is a dispute concern that
-- this migration deliberately does not try to model.
