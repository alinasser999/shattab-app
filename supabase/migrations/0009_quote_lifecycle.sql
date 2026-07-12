-- 0009_quote_lifecycle — close the hire loop and tighten quote RLS.
--
-- Fixes (from the workflow review, P0 #3/#4/#5):
--   #3 a hired job never closes: add briefs.hired_at, set it on accept,
--      auto-decline the brief's other pending quotes, drop it from the
--      contractor opportunities feed.
--   #4 RLS holes: a contractor could self-accept their own quote; a homeowner
--      could rewrite the contractor's offer fields while "accepting".
--   #5 editing an accepted quote silently reset it to 'sent'.
--
-- Safe to run more than once (drop-if-exists / add-column-if-not-exists).

-- ── 1. Brief terminal state ──────────────────────────────────────────────────
alter table public.briefs
  add column if not exists hired_at timestamptz;

-- ── 2. Quote RLS — split the contractor "for all" policy ─────────────────────
-- Contractors may create/read/delete their own quotes and update them only to
-- 'sent' or 'withdrawn'. They can no longer set 'accepted' themselves.
drop policy if exists "contractor_own" on public.quotes;

create policy "contractor_select_own" on public.quotes for select
  using (contractor_id = auth.uid());

create policy "contractor_insert_own" on public.quotes for insert
  with check (contractor_id = auth.uid() and status = 'sent');

create policy "contractor_update_own" on public.quotes for update
  using (contractor_id = auth.uid())
  with check (contractor_id = auth.uid() and status in ('sent', 'withdrawn'));

create policy "contractor_delete_own" on public.quotes for delete
  using (contractor_id = auth.uid());

-- homeowner_read / homeowner_status from 0005 stay as-is (status-only check).

-- ── 3. Guard triggers ────────────────────────────────────────────────────────
-- An accepted quote is frozen: nobody may edit its offer fields or push it
-- back to 'sent'. (Backs up the client-side hide of the edit button.)
create or replace function public.tg_lock_accepted_quote()
returns trigger language plpgsql as $$
begin
  if old.status = 'accepted' and (
       new.note          is distinct from old.note
    or new.price_min     is distinct from old.price_min
    or new.price_max     is distinct from old.price_max
    or new.duration_text is distinct from old.duration_text
    or new.status = 'sent'
  ) then
    raise exception 'quote_locked: an accepted quote cannot be edited';
  end if;
  return new;
end;
$$;

drop trigger if exists lock_accepted_quote on public.quotes;
create trigger lock_accepted_quote before update on public.quotes
  for each row execute procedure public.tg_lock_accepted_quote();

-- Only the owning contractor may change the offer fields. A homeowner update
-- (accept/decline) must leave note/price/duration untouched.
create or replace function public.tg_guard_quote_fields()
returns trigger language plpgsql as $$
begin
  if auth.uid() is distinct from new.contractor_id and (
       new.note          is distinct from old.note
    or new.price_min     is distinct from old.price_min
    or new.price_max     is distinct from old.price_max
    or new.duration_text is distinct from old.duration_text
  ) then
    raise exception 'quote_fields_locked: only the contractor may edit the offer';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_quote_fields on public.quotes;
create trigger guard_quote_fields before update on public.quotes
  for each row execute procedure public.tg_guard_quote_fields();

-- ── 4. accept_quote — the only path that reaches 'accepted' ───────────────────
-- Homeowner accepts one quote → that quote 'accepted', the brief's other
-- 'sent' quotes 'declined', the brief marked hired.
create or replace function public.accept_quote(p_quote_id uuid)
returns void
language plpgsql
security definer set search_path = public
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

  update public.quotes set status = 'accepted' where id = p_quote_id;
  update public.quotes set status = 'declined'
    where brief_id = v_brief and id <> p_quote_id and status = 'sent';
  update public.briefs set hired_at = now() where id = v_brief;
end;
$$;
