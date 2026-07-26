-- 0023_account_deletion — in-app account deletion.
--
-- Google Play requires an in-app deletion path for any app that creates
-- accounts in-app. There was none.
--
-- A plain `delete from profiles` does not work here. Six foreign keys into
-- profiles are ON DELETE NO ACTION rather than CASCADE:
--     posts.author_id, post_comments.user_id, post_likes.user_id,
--     post_saves.user_id, reviews.homeowner_id, reviews.contractor_id
-- so the delete raises a foreign-key violation for any user who has ever
-- posted, commented, liked, saved or been reviewed — i.e. essentially every
-- real user. Those rows are removed explicitly below, in dependency order,
-- before the profile row goes.
--
-- What survives: nothing personal. Reviews the user wrote hang off their
-- briefs, and briefs cascade from profiles, so they would be removed by the
-- cascade regardless — anonymising the author would not have preserved them.
-- `reviews_rollup` (0012) fires AFTER DELETE, so every affected contractor's
-- review_avg / review_count is recomputed rather than left inflated.
--
-- Irreversible, and runs server-side in one transaction: a half-deleted account
-- (auth row gone, data left behind) is worse than either outcome.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  -- Must be a signed-in end user. Guards the anon role explicitly rather than
  -- relying on auth.uid() being null, and refuses service_role so an operator
  -- cannot wipe an arbitrary account through this path by accident.
  if v_uid is null then
    raise exception 'not_authorized';
  end if;
  if coalesce(
       nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
       ''
     ) <> 'authenticated' then
    raise exception 'not_authorized';
  end if;

  -- ── NO ACTION foreign keys, cleared by hand ──
  -- Their engagement with other people's content.
  delete from public.post_likes    where user_id = v_uid;
  delete from public.post_saves    where user_id = v_uid;
  delete from public.post_comments where user_id = v_uid;

  -- Their own posts. post_likes / post_saves / post_comments cascade from
  -- posts, so other people's engagement with them goes too.
  delete from public.posts where author_id = v_uid;

  -- Reviews they wrote and reviews written about them. Explicit because both
  -- FKs are NO ACTION; the rollup trigger fixes the contractor totals.
  delete from public.reviews
   where homeowner_id = v_uid or contractor_id = v_uid;

  -- ── Uploaded files ──
  -- Every bucket namespaces objects under the owner's uid as the first path
  -- segment (see the storage policies in 0002 / 0014 / 0015), so this catches
  -- avatars, logos, post media, brief photos, payment proofs and verification
  -- documents without enumerating buckets.
  delete from storage.objects
   where (storage.foldername(name))[1] = v_uid::text;

  -- ── The profile itself ──
  -- Cascades: briefs (and their quotes + reviews), contractor_profiles,
  -- homeowner_profiles, portfolio_projects, quotes, saved_contractors,
  -- payments, payment_requests, verification_requests.
  delete from public.profiles where id = v_uid;

  -- Finally the auth record, so the phone number is free to sign up again.
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
