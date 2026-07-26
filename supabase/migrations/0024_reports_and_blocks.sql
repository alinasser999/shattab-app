-- 0024_reports_and_blocks — moderation primitives for user-generated content.
--
-- The app carries posts, comments, photos, briefs and reviews with no way to
-- report anything or to stop seeing a specific person. That is an operational
-- problem before it is a store-policy one: the first abusive account currently
-- has to be handled by hand in the SQL editor, and the person on the receiving
-- end has no action available to them at all.
--
-- Two independent mechanisms:
--   user_blocks     — private, immediate, user-controlled. No review needed.
--   content_reports — queued for the operator. Deliberately does not hide
--                     anything on its own; auto-hiding on report is a
--                     brigading tool.

-- ── blocks ──────────────────────────────────────────────────────────────────
create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint user_blocks_no_self check (blocker_id <> blocked_id)
);

-- The feed filter probes "has either side blocked the other", so both
-- directions need to be cheap. The primary key already covers blocker_id.
create index if not exists user_blocks_blocked_idx
  on public.user_blocks (blocked_id);

alter table public.user_blocks enable row level security;

-- A block list is private: you see only the blocks you created. Deliberately no
-- policy that would let someone discover they have been blocked.
drop policy if exists "blocks_select_own" on public.user_blocks;
create policy "blocks_select_own" on public.user_blocks
  for select using (blocker_id = (select auth.uid()));

drop policy if exists "blocks_insert_own" on public.user_blocks;
create policy "blocks_insert_own" on public.user_blocks
  for insert with check (blocker_id = (select auth.uid()));

drop policy if exists "blocks_delete_own" on public.user_blocks;
create policy "blocks_delete_own" on public.user_blocks
  for delete using (blocker_id = (select auth.uid()));

-- ── reports ─────────────────────────────────────────────────────────────────
create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null
    check (target_type in ('post', 'comment', 'profile', 'brief', 'review')),
  -- Intentionally not a foreign key: one column addresses five different
  -- tables, and a report must survive the reported row being deleted — which is
  -- exactly the case an operator most needs to see.
  target_id uuid not null,
  reason text not null
    check (reason in ('spam', 'scam', 'offensive', 'sexual', 'violence',
                      'impersonation', 'other')),
  note text,
  status text not null default 'pending'
    check (status in ('pending', 'actioned', 'dismissed')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  -- One report per person per item: re-reporting the same post is queue noise,
  -- and the client can treat the conflict as "already reported".
  unique (reporter_id, target_type, target_id)
);

create index if not exists content_reports_status_idx
  on public.content_reports (status, created_at desc);
create index if not exists content_reports_target_idx
  on public.content_reports (target_type, target_id);

alter table public.content_reports enable row level security;

drop policy if exists "reports_insert_own" on public.content_reports;
create policy "reports_insert_own" on public.content_reports
  for insert with check (
    reporter_id = (select auth.uid()) and status = 'pending'
  );

-- Readable by the reporter so the UI can show "already reported". No update or
-- delete from the client: triage is an operator action.
drop policy if exists "reports_select_own" on public.content_reports;
create policy "reports_select_own" on public.content_reports
  for select using (reporter_id = (select auth.uid()));

-- ── feed respects blocks ────────────────────────────────────────────────────
-- Body unchanged from 0017 except for the block filter. Note the added
-- parentheses around the keyset predicate: the original `where A or B` becomes
-- `where (A or B) and not exists (...)`. Without them Postgres reads it as
-- `A or (B and not exists ...)`, and the first page — where p_before_created_at
-- is null, so A is true — would show blocked authors anyway.
--
-- Filtering runs in both directions. Hiding only the people you blocked would
-- leave someone you blocked still seeing and replying to your posts, which is
-- the half of the feature that matters when it is used defensively.
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
set search_path to 'public'
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
    pr.full_name,
    pr.avatar_url,
    case when p.author_role = 'contractor' then pr.phone else null end
  from posts p
  left join profiles pr on pr.id = p.author_id
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
