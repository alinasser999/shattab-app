-- 0022_rls_initplan — stop re-evaluating auth.uid() once per row.
--
-- `auth.uid()` is STABLE, not IMMUTABLE, so Postgres calls it for every row a
-- policy is checked against. Wrapping it as `(select auth.uid())` turns it into
-- an InitPlan: evaluated once per statement, then compared as a constant.
--
-- Invisible at today's 14 briefs. At 50k rows a single feed scan makes 50k
-- function calls before it returns anything. This is the standard Supabase
-- scaling cliff and the highest-leverage database change available here.
--
-- 0007_rls_perf_hardening already did this for `briefs` and `profiles`. These 20
-- policies were added afterwards (0008 posts, 0009 quotes, 0013 monetization,
-- 0014 payments, 0015 verification, 0019 reviews) and missed the pattern.
--
-- Every predicate below is copied from the live policy definition with only the
-- auth.uid() call wrapped. No semantic change — same rows, same permissions.

-- ── posts ───────────────────────────────────────────────────────────────────
drop policy if exists "posts_insert_own" on public.posts;
create policy "posts_insert_own" on public.posts
  for insert with check (author_id = (select auth.uid()));

drop policy if exists "posts_update_own" on public.posts;
create policy "posts_update_own" on public.posts
  for update using (author_id = (select auth.uid()));

drop policy if exists "posts_delete_own" on public.posts;
create policy "posts_delete_own" on public.posts
  for delete using (author_id = (select auth.uid()));

-- ── post_likes ──────────────────────────────────────────────────────────────
drop policy if exists "likes_insert_own" on public.post_likes;
create policy "likes_insert_own" on public.post_likes
  for insert with check (user_id = (select auth.uid()));

drop policy if exists "likes_delete_own" on public.post_likes;
create policy "likes_delete_own" on public.post_likes
  for delete using (user_id = (select auth.uid()));

-- ── post_saves ──────────────────────────────────────────────────────────────
drop policy if exists "saves_read_own" on public.post_saves;
create policy "saves_read_own" on public.post_saves
  for select using (user_id = (select auth.uid()));

drop policy if exists "saves_insert_own" on public.post_saves;
create policy "saves_insert_own" on public.post_saves
  for insert with check (user_id = (select auth.uid()));

drop policy if exists "saves_delete_own" on public.post_saves;
create policy "saves_delete_own" on public.post_saves
  for delete using (user_id = (select auth.uid()));

-- ── post_comments ───────────────────────────────────────────────────────────
-- The rate limit (10 comments/minute) is preserved exactly; both the ownership
-- check and the one inside the counting subquery are hoisted.
drop policy if exists "comments_insert_own" on public.post_comments;
create policy "comments_insert_own" on public.post_comments
  for insert with check (
    user_id = (select auth.uid())
    and (
      select count(*) from public.post_comments pc
      where pc.user_id = (select auth.uid())
        and pc.created_at > (now() - interval '1 minute')
    ) < 10
  );

drop policy if exists "comments_delete_own" on public.post_comments;
create policy "comments_delete_own" on public.post_comments
  for delete using (user_id = (select auth.uid()));

-- ── quotes ──────────────────────────────────────────────────────────────────
drop policy if exists "contractor_select_own" on public.quotes;
create policy "contractor_select_own" on public.quotes
  for select using (contractor_id = (select auth.uid()));

-- Preserves the Pro-plan gate on sending quotes (0013_monetization).
drop policy if exists "contractor_insert_own" on public.quotes;
create policy "contractor_insert_own" on public.quotes
  for insert with check (
    contractor_id = (select auth.uid())
    and status = 'sent'
    and exists (
      select 1 from public.contractor_profiles cp
      where cp.profile_id = (select auth.uid())
        and cp.plan = 'pro'
        and cp.plan_expires_at > now()
    )
  );

drop policy if exists "contractor_update_own" on public.quotes;
create policy "contractor_update_own" on public.quotes
  for update
  using (contractor_id = (select auth.uid()))
  with check (
    contractor_id = (select auth.uid())
    and status = any (array['sent', 'withdrawn'])
  );

drop policy if exists "contractor_delete_own" on public.quotes;
create policy "contractor_delete_own" on public.quotes
  for delete using (contractor_id = (select auth.uid()));

-- ── reviews ─────────────────────────────────────────────────────────────────
-- Same predicate as 0019, including the completed_at gate.
drop policy if exists "reviews_homeowner_insert" on public.reviews;
create policy "reviews_homeowner_insert" on public.reviews
  for insert with check (
    homeowner_id = (select auth.uid())
    and exists (
      select 1 from public.briefs b
      where b.id = brief_id
        and b.homeowner_id = (select auth.uid())
        and b.completed_at is not null
    )
    and exists (
      select 1 from public.quotes q
      where q.brief_id = reviews.brief_id
        and q.contractor_id = reviews.contractor_id
        and q.status = 'accepted'
    )
  );

-- ── payments / payment_requests ─────────────────────────────────────────────
drop policy if exists "contractor_read_own_payments" on public.payments;
create policy "contractor_read_own_payments" on public.payments
  for select using (contractor_id = (select auth.uid()));

drop policy if exists "pr_read_own" on public.payment_requests;
create policy "pr_read_own" on public.payment_requests
  for select using (contractor_id = (select auth.uid()));

drop policy if exists "pr_insert_own" on public.payment_requests;
create policy "pr_insert_own" on public.payment_requests
  for insert with check (
    contractor_id = (select auth.uid()) and status = 'pending'
  );

-- ── verification_requests ───────────────────────────────────────────────────
drop policy if exists "vr_read_own" on public.verification_requests;
create policy "vr_read_own" on public.verification_requests
  for select using (contractor_id = (select auth.uid()));

drop policy if exists "vr_insert_own" on public.verification_requests;
create policy "vr_insert_own" on public.verification_requests
  for insert with check (
    contractor_id = (select auth.uid()) and status = 'pending'
  );

-- Not touched: `quotes.homeowner_status` already wraps its auth.uid(), and the
-- three permissive SELECT policies on `briefs` are a separate finding. Merging
-- those into one OR'd policy is a further speedup, but access-control
-- consolidation is where a subtle mistake becomes a data leak, so it wants its
-- own change with its own tests rather than riding along here.
