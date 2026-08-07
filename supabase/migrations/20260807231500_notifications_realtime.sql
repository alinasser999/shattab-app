-- Realtime delivery for notifications.
--
-- The triggers in 20260803202740 already write a notification row the moment a
-- quote arrives, a job completes or a payment clears. Until now the client only
-- ever saw those rows on a cold `select` when the user happened to open the
-- bell, so the marketplace's core latency — quote sent to homeowner informed —
-- was bounded by how often someone reopened the app.
--
-- Adding the table to the `supabase_realtime` publication lets the client hold
-- an open subscription instead. No new policy is needed and none is wanted:
-- Realtime evaluates the existing `notifications_read_own` SELECT policy per
-- subscriber, so a socket can only ever carry rows the same user could already
-- have read over REST. Publishing the table widens delivery, not access.

do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end
$$;

-- The stream filters on recipient_id and orders by created_at. Both are already
-- covered by notifications_recipient_created_idx from 20260803202740; this is a
-- note that the index is load-bearing for the subscription, not just the list.
