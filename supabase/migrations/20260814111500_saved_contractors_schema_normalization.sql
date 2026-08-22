-- The original saved_contractors table used created_at. The live project uses
-- saved_at, so normalize both fresh resets and already-deployed databases
-- before the cursor RPC is introduced.

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'saved_contractors'
      and column_name = 'created_at'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'saved_contractors'
      and column_name = 'saved_at'
  ) then
    alter table public.saved_contractors rename column created_at to saved_at;
  elsif not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'saved_contractors'
      and column_name = 'saved_at'
  ) then
    alter table public.saved_contractors
      add column saved_at timestamptz not null default now();
  end if;
end;
$$;

create index if not exists saved_contractors_homeowner_saved_at_idx
  on public.saved_contractors(homeowner_id, saved_at desc, contractor_id asc);
