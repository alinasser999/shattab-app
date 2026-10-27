-- Homeowner Professionals publish flow fields.
-- Nullable additions keep historical briefs and older clients readable.
-- This migration owns one transaction so the lock and privacy transition are
-- atomic even when the runner executes statements individually.

begin;

-- SECURITY DEFINER functions below access a FORCE RLS table. Fail closed if
-- the migration executor cannot safely own those functions and bypass RLS.
do $$
declare
  v_executor_bypasses_rls boolean;
begin
  select r.rolbypassrls or r.rolsuper
    into v_executor_bypasses_rls
  from pg_catalog.pg_roles as r
  where r.rolname = current_user;

  if coalesce(v_executor_bypasses_rls, false) is not true then
    raise exception 'migration executor must have BYPASSRLS for private brief functions';
  end if;
end;
$$;

-- Hold concurrent brief writes until legacy notes have been moved and the
-- compatibility trigger is installed. This lock stays held through COMMIT.
lock table public.briefs in access exclusive mode;

alter table public.briefs
  add column if not exists project_title text,
  add column if not exists estimated_area integer,
  add column if not exists budget_note text,
  add column if not exists start_timing text,
  add column if not exists publish_key text,
  add column if not exists publish_payload_fingerprint text;

alter table public.briefs
  drop constraint if exists briefs_project_title_check,
  add constraint briefs_project_title_check
    check (project_title is null or (length(trim(project_title)) between 2 and 120)),
  drop constraint if exists briefs_estimated_area_check,
  add constraint briefs_estimated_area_check
    check (estimated_area is null or estimated_area between 1 and 100000),
  drop constraint if exists briefs_budget_note_check,
  add constraint briefs_budget_note_check
    check (budget_note is null or length(trim(budget_note)) between 1 and 120),
  drop constraint if exists briefs_start_timing_check,
  add constraint briefs_start_timing_check
    check (start_timing is null or start_timing in ('flexible', 'within_3_months', 'within_month'));

create unique index if not exists briefs_homeowner_publish_key_idx
  on public.briefs (homeowner_id, publish_key)
  where publish_key is not null;

comment on column public.briefs.publish_key is
  'Client-generated idempotency key for the homeowner publish flow.';
comment on column public.briefs.publish_payload_fingerprint is
  'SHA-256 of the immutable canonical homeowner publish payload and ordered source media.';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.briefs'::regclass
      and conname = 'briefs_publish_payload_fingerprint_check'
  ) then
    alter table public.briefs
      add constraint briefs_publish_payload_fingerprint_check
      check (
        publish_payload_fingerprint is null
        or publish_payload_fingerprint ~ '^[0-9a-f]{64}$'
      );
  end if;
end;
$$;

create or replace function public.prevent_brief_publish_identity_change()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.publish_key is distinct from old.publish_key
     or new.publish_payload_fingerprint
       is distinct from old.publish_payload_fingerprint then
    raise exception 'brief publish identity is immutable'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

revoke all on function public.prevent_brief_publish_identity_change()
  from public, anon, authenticated;
drop trigger if exists briefs_publish_identity_immutable on public.briefs;
create trigger briefs_publish_identity_immutable
  before update of publish_key, publish_payload_fingerprint
  on public.briefs
  for each row execute function public.prevent_brief_publish_identity_change();

-- Keep homeowner budget notes outside the contractor-readable brief row.
create table if not exists public.brief_private_fields (
  brief_id uuid primary key references public.briefs(id) on delete cascade,
  homeowner_id uuid not null references public.profiles(id) on delete cascade,
  budget_note text,
  publish_payload_fingerprint text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint brief_private_fields_budget_note_check
    check (budget_note is null or length(trim(budget_note)) between 1 and 120)
);

alter table public.brief_private_fields
  add column if not exists publish_payload_fingerprint text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.brief_private_fields'::regclass
      and conname = 'brief_private_fields_publish_fingerprint_check'
  ) then
    alter table public.brief_private_fields
      add constraint brief_private_fields_publish_fingerprint_check
      check (
        publish_payload_fingerprint is null
        or publish_payload_fingerprint ~ '^[0-9a-f]{64}$'
      );
  end if;
end;
$$;

create index if not exists brief_private_fields_homeowner_idx
  on public.brief_private_fields (homeowner_id, brief_id);

alter table public.brief_private_fields enable row level security;
alter table public.brief_private_fields force row level security;

drop policy if exists brief_private_fields_homeowner_only
  on public.brief_private_fields;
create policy brief_private_fields_homeowner_only
  on public.brief_private_fields
  for all
  to authenticated
  using (
    homeowner_id = (select auth.uid())
    and exists (
      select 1
      from public.profiles as p
      where p.id = (select auth.uid())
        and p.role = 'homeowner'
    )
  )
  with check (
    homeowner_id = (select auth.uid())
    and exists (
      select 1
      from public.profiles as p
      where p.id = (select auth.uid())
        and p.role = 'homeowner'
    )
  );

revoke all on table public.brief_private_fields from public, anon, authenticated;
do $$
begin
  execute format(
    'grant select, insert, update on table public.brief_private_fields to %I',
    current_user
  );
end;
$$;
comment on table public.brief_private_fields is
  'Owner-only fields that must never be returned by contractor brief queries.';

-- Move any old public values privately before enabling the legacy-write bridge.
-- Conflicting ownership or immutable publish state aborts the migration rather
-- than replacing an unrelated private value.
do $$
declare
  v_brief record;
  v_saved_brief_id uuid;
begin
  for v_brief in
    select b.id, b.homeowner_id, b.budget_note, b.publish_payload_fingerprint
    from public.briefs as b
    where b.budget_note is not null
    for update
  loop
    v_saved_brief_id := null;

    insert into public.brief_private_fields as private_fields (
      brief_id,
      homeowner_id,
      budget_note,
      publish_payload_fingerprint
    )
    values (
      v_brief.id,
      v_brief.homeowner_id,
      v_brief.budget_note,
      v_brief.publish_payload_fingerprint
    )
    on conflict (brief_id) do update
      set budget_note = excluded.budget_note,
          updated_at = now()
    where private_fields.homeowner_id = excluded.homeowner_id
      and private_fields.publish_payload_fingerprint
        is not distinct from excluded.publish_payload_fingerprint
      and private_fields.budget_note is not distinct from excluded.budget_note
    returning private_fields.brief_id into v_saved_brief_id;

    if v_saved_brief_id is null then
      raise exception 'legacy brief private-field conflict for brief %', v_brief.id
        using errcode = '23514';
    end if;

    update public.briefs as b
      set budget_note = null
    where b.id = v_brief.id
      and b.budget_note is not null;
  end loop;
end;
$$;

create or replace function public.save_homeowner_brief_private_fields(
  p_brief_id uuid,
  p_budget_note text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_budget_note text := nullif(btrim(p_budget_note), '');
  v_saved_brief_id uuid;
begin
  if v_user_id is null or not exists (
    select 1
    from public.profiles as p
    join public.briefs as b on b.homeowner_id = auth.uid()
    where p.id = auth.uid()
      and p.role = 'homeowner'
      and b.id = p_brief_id
  ) then
    raise exception 'not authorized to update private brief fields'
      using errcode = '42501';
  end if;

  if v_budget_note is not null
     and length(v_budget_note) not between 1 and 120 then
    raise exception 'budget note must be at most 120 characters'
      using errcode = '22023';
  end if;

  insert into public.brief_private_fields as private_fields (
    brief_id,
    homeowner_id,
    budget_note
  )
  values (p_brief_id, v_user_id, v_budget_note)
  on conflict (brief_id) do update
    set budget_note = excluded.budget_note,
        updated_at = now()
  where private_fields.homeowner_id = v_user_id
    and (
      private_fields.publish_payload_fingerprint is null
      or private_fields.budget_note is not distinct from excluded.budget_note
    )
  returning private_fields.brief_id into v_saved_brief_id;

  if v_saved_brief_id is null then
    raise exception 'not authorized to update private brief fields'
      using errcode = '42501';
  end if;

  return v_saved_brief_id;
end;
$$;

revoke all on function public.save_homeowner_brief_private_fields(uuid, text)
  from public, anon, authenticated;
grant execute on function public.save_homeowner_brief_private_fields(uuid, text)
  to authenticated;

create or replace function public.save_homeowner_brief_private_fields_for_publish(
  p_brief_id uuid,
  p_budget_note text,
  p_publish_fingerprint text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_budget_note text := nullif(btrim(p_budget_note), '');
  v_saved_brief_id uuid;
begin
  if v_user_id is null or not exists (
    select 1
    from public.profiles as p
    join public.briefs as b on b.homeowner_id = auth.uid()
    where p.id = auth.uid()
      and p.role = 'homeowner'
      and b.id = p_brief_id
  ) then
    raise exception 'not authorized to update private brief fields'
      using errcode = '42501';
  end if;

  if v_budget_note is null
     or length(v_budget_note) not between 1 and 120
     or p_publish_fingerprint is null
     or p_publish_fingerprint !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid private brief publish fingerprint or note'
      using errcode = '22023';
  end if;

  insert into public.brief_private_fields as private_fields (
    brief_id,
    homeowner_id,
    budget_note,
    publish_payload_fingerprint
  )
  values (
    p_brief_id,
    v_user_id,
    v_budget_note,
    p_publish_fingerprint
  )
  on conflict (brief_id) do update
    set budget_note = excluded.budget_note,
        updated_at = now()
  where private_fields.homeowner_id = v_user_id
    and private_fields.publish_payload_fingerprint
      = excluded.publish_payload_fingerprint
    and private_fields.budget_note is not distinct from excluded.budget_note
  returning private_fields.brief_id into v_saved_brief_id;

  if v_saved_brief_id is null then
    raise exception 'private brief publish payload does not match'
      using errcode = '23514';
  end if;

  return v_saved_brief_id;
end;
$$;

revoke all on function public.save_homeowner_brief_private_fields_for_publish(
  uuid, text, text
) from public, anon, authenticated;
grant execute on function public.save_homeowner_brief_private_fields_for_publish(
  uuid, text, text
) to authenticated;

create or replace function public.get_homeowner_brief_private_fields(
  p_brief_id uuid
)
returns table (brief_id uuid, budget_note text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null or not exists (
    select 1
    from public.profiles as p
    join public.briefs as b on b.homeowner_id = p.id
    where p.id = v_user_id
      and p.role = 'homeowner'
      and b.id = p_brief_id
  ) then
    raise exception 'not authorized to read private brief fields'
      using errcode = '42501';
  end if;

  return query
    select f.brief_id, f.budget_note
    from public.brief_private_fields as f
    where f.brief_id = p_brief_id
      and f.homeowner_id = v_user_id;
end;
$$;

revoke all on function public.get_homeowner_brief_private_fields(uuid)
  from public, anon, authenticated;
grant execute on function public.get_homeowner_brief_private_fields(uuid)
  to authenticated;

-- Pin the RPC definer ownership to the migration role that passed the
-- BYPASSRLS precondition; this also keeps FORCE RLS effective for all callers.
alter function public.save_homeowner_brief_private_fields(uuid, text)
  owner to current_user;
alter function public.save_homeowner_brief_private_fields_for_publish(
  uuid, text, text
) owner to current_user;
alter function public.get_homeowner_brief_private_fields(uuid)
  owner to current_user;

-- Legacy clients still write budget_note on public.briefs. This AFTER trigger
-- moves that value to the private table and clears the public column within
-- the same transaction, so contractor reads can never observe a committed note.
create or replace function public.capture_legacy_homeowner_brief_budget_note()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_saved_brief_id uuid;
begin
  if v_user_id is null
     or new.homeowner_id is distinct from v_user_id
     or not exists (
       select 1
       from public.profiles as p
       where p.id = v_user_id
         and p.role = 'homeowner'
     ) then
    raise exception 'not authorized to write legacy brief private fields'
      using errcode = '42501';
  end if;

  if tg_op = 'UPDATE'
     and old.homeowner_id is distinct from new.homeowner_id then
    raise exception 'brief owner cannot change with a legacy private-field write'
      using errcode = '42501';
  end if;

  insert into public.brief_private_fields as private_fields (
    brief_id,
    homeowner_id,
    budget_note,
    publish_payload_fingerprint
  )
  values (
    new.id,
    v_user_id,
    nullif(btrim(new.budget_note), ''),
    new.publish_payload_fingerprint
  )
  on conflict (brief_id) do update
    set budget_note = excluded.budget_note,
        updated_at = now()
  where private_fields.homeowner_id = excluded.homeowner_id
    and private_fields.publish_payload_fingerprint
      is not distinct from excluded.publish_payload_fingerprint
    and (
      private_fields.publish_payload_fingerprint is null
      or private_fields.budget_note is not distinct from excluded.budget_note
    )
  returning private_fields.brief_id into v_saved_brief_id;

  if v_saved_brief_id is null then
    raise exception 'legacy brief private-field conflict for brief %', new.id
      using errcode = '23514';
  end if;

  -- This UPDATE invokes the trigger's WHEN predicate with a NULL value, so it
  -- terminates without another private write.
  update public.briefs as b
    set budget_note = null
  where b.id = new.id
    and b.budget_note is not null;

  return new;
end;
$$;

-- The migration executor was checked for BYPASSRLS above. Keep this function
-- owned by that controlled migration role so FORCE RLS cannot block its write.
alter function public.capture_legacy_homeowner_brief_budget_note()
  owner to current_user;
revoke all on function public.capture_legacy_homeowner_brief_budget_note()
  from public, anon, authenticated;

drop trigger if exists briefs_capture_legacy_budget_note on public.briefs;
create trigger briefs_capture_legacy_budget_note
  after insert or update of budget_note on public.briefs
  for each row
  when (new.budget_note is not null)
  execute function public.capture_legacy_homeowner_brief_budget_note();

commit;
