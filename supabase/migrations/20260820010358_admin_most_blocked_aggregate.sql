-- Keep the moderation signal complete and deterministic. The console must not
-- infer a global ranking from an arbitrary REST sample: that silently turns a
-- busy account into an empty result once the first page changes.
create or replace function public.admin_most_blocked(p_limit integer default 10)
returns table (
  blocked_id uuid,
  block_count bigint,
  full_name text
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.admin_require();

  return query
  select
    ub.blocked_id,
    count(*)::bigint as block_count,
    p.full_name
  from public.user_blocks ub
  left join public.profiles p on p.id = ub.blocked_id
  group by ub.blocked_id, p.full_name
  having count(*) >= 2
  order by count(*) desc, ub.blocked_id
  limit greatest(least(coalesce(p_limit, 10), 50), 1);
end;
$$;

revoke execute on function public.admin_most_blocked(integer) from public, anon;
grant execute on function public.admin_most_blocked(integer) to authenticated;
