-- 0017_feed_keyset — replace offset pagination with keyset (cursor) pagination.
--
-- Bug (production audit): get_for_you_feed used LIMIT/OFFSET ordered by
-- created_at only. As posts are inserted while a user scrolls, OFFSET drifts →
-- a post seen on page 1 reappears on page 2 (duplicate), or a post is skipped.
-- Ties on created_at (same-second posts) also ordered arbitrarily across pages.
--
-- Fix: keyset pagination on the stable (created_at, id) tuple. The client passes
-- the last row it has; the query returns strictly older rows. Deterministic,
-- drift-free, and index-friendly.

-- Old offset overload must go, else it lingers as a separate signature.
drop function if exists get_for_you_feed(uuid, int, int);

create or replace function get_for_you_feed(
  p_user_id uuid,
  p_limit int default 10,
  p_before_created_at timestamptz default null,
  p_before_id uuid default null
)
returns table (
  id uuid,
  author_id uuid,
  author_role text,
  post_type text,
  caption text,
  media_urls text[],
  category text,
  governorate text,
  city text,
  portfolio_project_id uuid,
  created_at timestamptz,
  like_count bigint,
  comment_count bigint,
  is_liked boolean,
  is_saved boolean,
  author_name text,
  author_avatar_url text,
  author_phone text
)
language sql stable
as $$
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
    pr.full_name,
    pr.avatar_url,
    case when p.author_role = 'contractor' then pr.phone else null end
  from posts p
  left join profiles pr on pr.id = p.author_id
  left join lateral (select count(*) as cnt from post_likes pl where pl.post_id = p.id) lc on true
  left join lateral (select count(*) as cnt from post_comments pc where pc.post_id = p.id) cc on true
  where p_before_created_at is null
     or (p.created_at, p.id) < (p_before_created_at, p_before_id)
  order by p.created_at desc, p.id desc
  limit p_limit;
$$;
