-- Consumer self-service account deletion.
--
-- This is intentionally separate from the Admin console. The function only
-- accepts the currently authenticated user's identity and removes the
-- dependent rows before deleting the profile and Auth user.

create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_claim_role text := coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    ''
  );
begin
  if v_uid is null or v_claim_role <> 'authenticated' then
    raise exception 'not_authorized';
  end if;

  -- These relationships intentionally use NO ACTION, so clear them before
  -- removing the account's own content.
  delete from public.post_likes where user_id = v_uid;
  delete from public.post_saves where user_id = v_uid;
  delete from public.post_comments where user_id = v_uid;
  delete from public.posts where author_id = v_uid;
  delete from public.reviews
   where homeowner_id = v_uid or contractor_id = v_uid;

  -- User-owned media is namespaced by uid as the first storage path segment.
  delete from storage.objects
   where (storage.foldername(name))[1] = v_uid::text;

  -- Profiles cascade to the role-specific and marketplace records.
  delete from public.profiles where id = v_uid;

  -- The client signs out immediately after this RPC completes.
  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
