-- The app uses feed/comment projections for public counts and only needs the
-- current user's own rows to paint an optimistic state. Do not expose every
-- liker UUID through direct PostgREST table reads.

revoke select on public.post_likes from public, anon, authenticated;
grant select on public.post_likes to authenticated;

drop policy if exists "likes_all_read" on public.post_likes;
drop policy if exists "likes_read_own" on public.post_likes;
create policy "likes_read_own" on public.post_likes
  for select to authenticated
  using ((select auth.uid()) = user_id);

revoke select on public.post_comment_likes from public, anon, authenticated;
grant select on public.post_comment_likes to authenticated;

drop policy if exists "comment_likes_read_all" on public.post_comment_likes;
drop policy if exists "comment_likes_read_own" on public.post_comment_likes;
create policy "comment_likes_read_own" on public.post_comment_likes
  for select to authenticated
  using ((select auth.uid()) = user_id);
