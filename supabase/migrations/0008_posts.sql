-- 0008_posts — Explore feed (M4)
-- LinkedIn-style professional posts: project showcases, tips, milestones, renovation updates.
-- Single-level comments (no threading), likes, saves, share (deep link).

create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references profiles(id),
  author_role text not null check (author_role in ('homeowner', 'contractor')),
  post_type text not null check (post_type in (
    'project_showcase', 'tip', 'milestone', 'renovation_update'
  )),
  caption text not null check (char_length(caption) <= 2000),
  media_urls text[] not null default '{}',
  category text,
  governorate text,
  city text,
  portfolio_project_id uuid references portfolio_projects(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_created_at_idx on posts (created_at desc);
create index if not exists posts_author_id_idx on posts (author_id);
create index if not exists posts_post_type_idx on posts (post_type);

create trigger set_updated_at before update on posts
  for each row execute function tg_set_updated_at();

-- Likes (unique per user per post)
create table if not exists post_likes (
  post_id uuid not null references posts(id) on delete cascade,
  user_id uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index if not exists post_likes_user_id_idx on post_likes (user_id);

-- Saved posts (bookmarks)
create table if not exists post_saves (
  post_id uuid not null references posts(id) on delete cascade,
  user_id uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index if not exists post_saves_user_id_idx on post_saves (user_id);

-- Comments (single-level, no threading)
create table if not exists post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references posts(id) on delete cascade,
  user_id uuid not null references profiles(id),
  content text not null check (char_length(content) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index if not exists post_comments_post_id_idx on post_comments (post_id, created_at asc);

-- Rate-limit guard: max 10 comments per user per minute
-- Thrown by the application layer; DB-level as safety net.
create or replace function check_comment_rate_limit(p_user_id uuid)
returns void as $$
declare
  recent_count int;
begin
  select count(*) into recent_count
  from post_comments
  where user_id = p_user_id
    and created_at > now() - interval '1 minute';
  if recent_count >= 10 then
    raise exception 'comment_rate_limit: max 10 comments per minute';
  end if;
end;
$$ language plpgsql security definer;

-- Feed function: returns posts with user interaction state
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
    pr.phone
  from posts p
  left join profiles pr on pr.id = p.author_id
  left join lateral (select count(*) as cnt from post_likes pl where pl.post_id = p.id) lc on true
  left join lateral (select count(*) as cnt from post_comments pc where pc.post_id = p.id) cc on true
  order by p.created_at desc
  limit p_limit
  offset p_offset;
$$;

-- RLS
alter table posts enable row level security;
alter table post_likes enable row level security;
alter table post_saves enable row level security;
alter table post_comments enable row level security;

-- Posts: everyone can read; authors manage own
create policy "posts_read_all" on posts for select using (true);
create policy "posts_insert_own" on posts for insert
  with check (author_id = auth.uid());
create policy "posts_update_own" on posts for update
  using (author_id = auth.uid());
create policy "posts_delete_own" on posts for delete
  using (author_id = auth.uid());

-- Likes: toggle
create policy "likes_all_read" on post_likes for select using (true);
create policy "likes_insert_own" on post_likes for insert
  with check (user_id = auth.uid());
create policy "likes_delete_own" on post_likes for delete
  using (user_id = auth.uid());

-- Saves: toggle
create policy "saves_read_own" on post_saves for select
  using (user_id = auth.uid());
create policy "saves_insert_own" on post_saves for insert
  with check (user_id = auth.uid());
create policy "saves_delete_own" on post_saves for delete
  using (user_id = auth.uid());

-- Comments: read all, insert own, rate-limited
create policy "comments_read_all" on post_comments for select using (true);
create policy "comments_insert_own" on post_comments for insert
  with check (
    user_id = auth.uid()
    and (
      select count(*) from post_comments pc
      where pc.user_id = auth.uid()
        and pc.created_at > now() - interval '1 minute'
    ) < 10
  );
create policy "comments_delete_own" on post_comments for delete
  using (user_id = auth.uid());

-- Storage bucket for post media
insert into storage.buckets (id, name, public)
values ('post-media', 'post-media', true)
on conflict (id) do nothing;

create policy "post_media_insert_own" on storage.objects for insert
  with check (
    bucket_id = 'post-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "post_media_select_all" on storage.objects for select
  using (bucket_id = 'post-media');
