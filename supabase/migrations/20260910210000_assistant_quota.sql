-- Aggregate daily quota for the in-app assistant.
-- No prompt, completion, or message content is stored.

create table if not exists public.assistant_daily_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_date date not null default current_date,
  request_count int not null default 1,
  updated_at timestamptz not null default now(),
  primary key (user_id, usage_date)
);

alter table public.assistant_daily_usage enable row level security;

drop policy if exists "assistant_usage_select_own" on public.assistant_daily_usage;
create policy "assistant_usage_select_own"
  on public.assistant_daily_usage
  for select
  using (auth.uid() = user_id);

-- Remove the old parameterized shape if a preview migration was applied. The
-- caller must never be able to choose which user is charged or raise the cap.
drop function if exists public.check_and_increment_assistant_quota(uuid, int);

create or replace function public.check_and_increment_assistant_quota()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_count int;
begin
  if v_user_id is null then
    return false;
  end if;

  insert into public.assistant_daily_usage (user_id, usage_date, request_count, updated_at)
  values (v_user_id, current_date, 1, now())
  on conflict (user_id, usage_date)
  do update set
    request_count = assistant_daily_usage.request_count + 1,
    updated_at = now()
  returning request_count into v_count;

  return v_count <= 50;
end;
$$;

revoke all on table public.assistant_daily_usage from public, anon, authenticated;
grant select on table public.assistant_daily_usage to authenticated;
revoke all on function public.check_and_increment_assistant_quota() from public, anon, authenticated;
grant execute on function public.check_and_increment_assistant_quota() to authenticated;
