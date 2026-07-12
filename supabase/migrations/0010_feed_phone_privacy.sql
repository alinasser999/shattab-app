-- 0010_feed_phone_privacy — stop leaking homeowners' phone numbers.
--
-- 0008's get_for_you_feed returned author_phone for every post to every caller
-- (including anonymous guests). Contractors publish their number as a lead
-- channel, but homeowners do not — their numbers were scrapeable at feed scale.
-- Only contractor-authored posts now expose a phone.
--
-- Signature unchanged, so no client change is needed.

create or replace function get_for_you_feed(
  p_user_id uuid,
  p_limit int default 10,
  p_offset int default 0
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
  order by p.created_at desc
  limit p_limit
  offset p_offset;
$$;
