-- Keep community post identity public without making the private profiles table
-- publicly readable. The feed needs a poster name and avatar, but homeowner
-- phone numbers must never cross this boundary.
create or replace function public.get_community_author_identity(
  p_author_id uuid,
  p_author_role text
)
returns table(
  full_name text,
  avatar_url text,
  phone text
)
language sql
stable
security definer
set search_path = public
as $function$
  select
    pr.full_name,
    pr.avatar_url,
    case when p_author_role = 'contractor' then pr.phone else null end
  from public.profiles pr
  where pr.id = p_author_id
    and pr.role = p_author_role;
$function$;

revoke all on function public.get_community_author_identity(uuid, text)
  from public, anon, authenticated;
grant execute on function public.get_community_author_identity(uuid, text)
  to anon, authenticated;

-- The feed remains an invoker function, so its post visibility and block
-- filtering continue to follow the caller's RLS context. Only the small,
-- explicitly selected identity projection above bypasses profile RLS.
create or replace function public.get_for_you_feed(
  p_user_id uuid,
  p_limit integer default 10,
  p_before_created_at timestamptz default null,
  p_before_id uuid default null
)
returns table(
  id uuid, author_id uuid, author_role text, post_type text, caption text,
  media_urls text[], category text, governorate text, city text,
  portfolio_project_id uuid, created_at timestamptz, like_count bigint,
  comment_count bigint, is_liked boolean, is_saved boolean, author_name text,
  author_avatar_url text, author_phone text
)
language sql
stable
set search_path = public
as $function$
  select
    p.id,
    p.author_id,
    p.author_role,
    p.post_type,
    p.caption,
    p.media_urls,
    p.category,
    p.governorate,
    p.city,
    p.portfolio_project_id,
    p.created_at,
    coalesce(lc.cnt, 0),
    coalesce(cc.cnt, 0),
    exists(select 1 from post_likes pl where pl.post_id = p.id and pl.user_id = p_user_id),
    exists(select 1 from post_saves ps where ps.post_id = p.id and ps.user_id = p_user_id),
    author_identity.full_name,
    author_identity.avatar_url,
    author_identity.phone
  from posts p
  left join lateral public.get_community_author_identity(
    p.author_id,
    p.author_role
  ) author_identity on true
  left join lateral (select count(*) as cnt from post_likes pl where pl.post_id = p.id) lc on true
  left join lateral (select count(*) as cnt from post_comments pc where pc.post_id = p.id) cc on true
  where (
      p_before_created_at is null
      or (p.created_at, p.id) < (p_before_created_at, p_before_id)
    )
    and (
      p_user_id is null
      or not exists (
        select 1 from user_blocks ub
        where (ub.blocker_id = p_user_id and ub.blocked_id = p.author_id)
           or (ub.blocker_id = p.author_id and ub.blocked_id = p_user_id)
      )
    )
  order by p.created_at desc, p.id desc
  limit p_limit;
$function$;
