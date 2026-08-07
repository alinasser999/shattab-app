-- Community notifications and comment interactions.
--
-- Notification rows are database-owned. Comment edits/deletes and comment
-- likes remain subject to the caller's auth.uid() through RLS.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  kind text not null,
  title_key text not null,
  body_key text not null,
  entity_type text,
  entity_id uuid,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  dedupe_key text,
  unique (recipient_id, dedupe_key)
);

alter table public.notifications
  drop constraint if exists notifications_kind_check;
alter table public.notifications
  add constraint notifications_kind_check check (kind in (
    'new_quote',
    'quote_accepted',
    'quote_declined',
    'completion_requested',
    'job_completed',
    'new_review',
    'verification_approved',
    'verification_rejected',
    'payment_approved',
    'payment_rejected',
    'post_liked',
    'post_commented',
    'comment_replied',
    'comment_liked'
  ));

create index if not exists notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);
create index if not exists notifications_unread_idx
  on public.notifications (recipient_id, created_at desc)
  where read_at is null;

alter table public.notifications enable row level security;
revoke all on public.notifications from public, anon, authenticated;
grant select, update, delete on public.notifications to authenticated;

drop policy if exists "notifications_read_own" on public.notifications;
create policy "notifications_read_own" on public.notifications
  for select to authenticated
  using ((select auth.uid()) = recipient_id);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
  for update to authenticated
  using ((select auth.uid()) = recipient_id)
  with check ((select auth.uid()) = recipient_id);

drop policy if exists "notifications_delete_own" on public.notifications;
create policy "notifications_delete_own" on public.notifications
  for delete to authenticated
  using ((select auth.uid()) = recipient_id);

-- Replies stay attached to the same post and survive deletion of the parent.
alter table public.post_comments
  add column if not exists parent_comment_id uuid
  references public.post_comments(id) on delete set null;
alter table public.post_comments
  add column if not exists updated_at timestamptz not null default now();

create index if not exists post_comments_parent_idx
  on public.post_comments (parent_comment_id, created_at asc);

create or replace function public.tg_validate_post_comment_parent()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.parent_comment_id is null then
    return new;
  end if;

  if new.parent_comment_id = new.id
     or not exists (
       select 1
       from public.post_comments parent
       where parent.id = new.parent_comment_id
         and parent.post_id = new.post_id
     ) then
    raise exception 'invalid_comment_parent';
  end if;
  return new;
end;
$$;

drop trigger if exists validate_post_comment_parent on public.post_comments;
create trigger validate_post_comment_parent
  before insert or update of post_id, parent_comment_id on public.post_comments
  for each row execute function public.tg_validate_post_comment_parent();

drop trigger if exists set_post_comment_updated_at on public.post_comments;
create trigger set_post_comment_updated_at
  before update on public.post_comments
  for each row execute function public.tg_set_updated_at();

drop policy if exists "comments_update_own" on public.post_comments;
create policy "comments_update_own" on public.post_comments
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create table if not exists public.post_comment_likes (
  comment_id uuid not null references public.post_comments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

create index if not exists post_comment_likes_user_idx
  on public.post_comment_likes (user_id, created_at desc);

alter table public.post_comment_likes enable row level security;
revoke all on public.post_comment_likes from public, anon, authenticated;
grant select, insert, delete on public.post_comment_likes to authenticated;

drop policy if exists "comment_likes_read_all" on public.post_comment_likes;
create policy "comment_likes_read_all" on public.post_comment_likes
  for select to authenticated
  using (true);

drop policy if exists "comment_likes_insert_own" on public.post_comment_likes;
create policy "comment_likes_insert_own" on public.post_comment_likes
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "comment_likes_delete_own" on public.post_comment_likes;
create policy "comment_likes_delete_own" on public.post_comment_likes
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Public comment reads use this narrow projection instead of exposing the
-- private profiles relation through PostgREST. Phone numbers are not returned.
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
set search_path = public
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
  order by c.created_at asc, c.id asc;
$$;

revoke all on function public.get_post_comments(uuid) from public, anon, authenticated;
grant execute on function public.get_post_comments(uuid) to anon, authenticated;

create or replace function public.create_notification(
  p_recipient_id uuid,
  p_actor_id uuid,
  p_kind text,
  p_title_key text,
  p_body_key text,
  p_entity_type text,
  p_entity_id uuid,
  p_payload jsonb,
  p_dedupe_key text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_recipient_id is null or p_recipient_id = p_actor_id then
    return;
  end if;

  insert into public.notifications (
    recipient_id,
    actor_id,
    kind,
    title_key,
    body_key,
    entity_type,
    entity_id,
    payload,
    dedupe_key
  ) values (
    p_recipient_id,
    p_actor_id,
    p_kind,
    p_title_key,
    p_body_key,
    p_entity_type,
    p_entity_id,
    coalesce(p_payload, '{}'::jsonb),
    p_dedupe_key
  ) on conflict (recipient_id, dedupe_key) do nothing;
end;
$$;

revoke all on function public.create_notification(
  uuid, uuid, text, text, text, text, uuid, jsonb, text
) from public, anon, authenticated;

create or replace function public.tg_notify_post_liked()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient uuid;
begin
  select author_id into v_recipient from public.posts where id = new.post_id;
  perform public.create_notification(
    v_recipient,
    new.user_id,
    'post_liked',
    'notificationCommunityTitle',
    'notificationPostLikedBody',
    'post',
    new.post_id,
    jsonb_build_object('post_id', new.post_id),
    'post_liked:' || new.post_id::text || ':' || new.user_id::text
  );
  return new;
end;
$$;

drop trigger if exists notify_post_liked on public.post_likes;
create trigger notify_post_liked
  after insert on public.post_likes
  for each row execute function public.tg_notify_post_liked();

create or replace function public.tg_notify_post_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post_author uuid;
  v_parent_author uuid;
begin
  select author_id into v_post_author from public.posts where id = new.post_id;
  if new.parent_comment_id is null then
    perform public.create_notification(
      v_post_author,
      new.user_id,
      'post_commented',
      'notificationCommunityTitle',
      'notificationPostCommentedBody',
      'post',
      new.post_id,
      jsonb_build_object('comment_id', new.id),
      'post_commented:' || new.id::text
    );
  else
    select user_id into v_parent_author
    from public.post_comments
    where id = new.parent_comment_id;

    perform public.create_notification(
      v_post_author,
      new.user_id,
      'post_commented',
      'notificationCommunityTitle',
      'notificationPostCommentedBody',
      'post',
      new.post_id,
      jsonb_build_object('comment_id', new.id),
      'post_commented:' || new.id::text
    );
    perform public.create_notification(
      v_parent_author,
      new.user_id,
      'comment_replied',
      'notificationCommunityTitle',
      'notificationCommentRepliedBody',
      'post',
      new.post_id,
      jsonb_build_object(
        'comment_id', new.id,
        'parent_comment_id', new.parent_comment_id
      ),
      'comment_replied:' || new.id::text
    );
  end if;
  return new;
end;
$$;

drop trigger if exists notify_post_comment on public.post_comments;
create trigger notify_post_comment
  after insert on public.post_comments
  for each row execute function public.tg_notify_post_comment();

create or replace function public.tg_notify_comment_liked()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recipient uuid;
  v_post_id uuid;
begin
  select user_id, post_id into v_recipient, v_post_id
  from public.post_comments
  where id = new.comment_id;
  perform public.create_notification(
    v_recipient,
    new.user_id,
    'comment_liked',
    'notificationCommunityTitle',
    'notificationCommentLikedBody',
    'post',
    v_post_id,
    jsonb_build_object('comment_id', new.comment_id),
    'comment_liked:' || new.comment_id::text || ':' || new.user_id::text
  );
  return new;
end;
$$;

drop trigger if exists notify_comment_liked on public.post_comment_likes;
create trigger notify_comment_liked
  after insert on public.post_comment_likes
  for each row execute function public.tg_notify_comment_liked();

revoke all on function public.tg_validate_post_comment_parent() from public, anon, authenticated;
revoke all on function public.tg_notify_post_liked() from public, anon, authenticated;
revoke all on function public.tg_notify_post_comment() from public, anon, authenticated;
revoke all on function public.tg_notify_comment_liked() from public, anon, authenticated;
