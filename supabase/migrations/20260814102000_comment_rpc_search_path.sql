-- Keep the intentionally public comment projection hardened like the other
-- public browse RPCs. `pg_temp` prevents a caller-controlled temporary object
-- from shadowing a name while the SECURITY DEFINER function runs.
create or replace function public.get_post_comments(p_post_id uuid)
returns table (
  id uuid,
  post_id uuid,
  user_id uuid,
  parent_comment_id uuid,
  content text,
  created_at timestamptz,
  updated_at timestamptz,
  like_count bigint,
  is_liked boolean,
  user_name text,
  user_avatar_url text,
  user_role text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    c.id,
    c.post_id,
    c.user_id,
    c.parent_comment_id,
    c.content,
    c.created_at,
    c.updated_at,
    count(cl.comment_id)::bigint,
    exists (
      select 1
      from public.post_comment_likes own_like
      where own_like.comment_id = c.id
        and own_like.user_id = auth.uid()
    ),
    p.full_name,
    p.avatar_url,
    p.role
  from public.post_comments c
  left join public.profiles p on p.id = c.user_id
  left join public.post_comment_likes cl on cl.comment_id = c.id
  where c.post_id = p_post_id
  group by
    c.id,
    c.post_id,
    c.user_id,
    c.parent_comment_id,
    c.content,
    c.created_at,
    c.updated_at,
    p.full_name,
    p.avatar_url,
    p.role
  order by c.created_at asc, c.id asc
  limit 200;
$$;

revoke all on function public.get_post_comments(uuid)
  from public, anon, authenticated;
grant execute on function public.get_post_comments(uuid)
  to anon, authenticated;
