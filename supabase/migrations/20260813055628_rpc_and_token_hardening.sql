-- Community cards are intentionally browseable before sign-in. Keep these
-- narrow projections callable by guests, but the function body must never
-- return a contractor phone to an anonymous caller.
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
    case
      when p_author_role = 'contractor' and auth.uid() is not null
        then pr.phone
      else null
    end
  from public.profiles pr
  where pr.id = p_author_id
    and pr.role = p_author_role
    and p_author_role in ('homeowner', 'contractor');
$function$;

revoke all on function public.get_community_author_identity(uuid, text)
  from public, anon, authenticated;
grant execute on function public.get_community_author_identity(uuid, text)
  to anon, authenticated;

revoke all on function public.get_post_comments(uuid)
  from public, anon, authenticated;
grant execute on function public.get_post_comments(uuid)
  to anon, authenticated;

-- A device token can only be updated while it belongs to the caller. Device
-- hand-off is handled by PushService.unregister followed by a fresh insert.
drop policy if exists "device_tokens_update_own" on public.device_tokens;
create policy "device_tokens_update_own" on public.device_tokens
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
