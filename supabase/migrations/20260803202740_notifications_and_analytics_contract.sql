-- Notifications and privacy-safe product events.
--
-- The client never writes notification rows directly. Trusted database
-- triggers create them when a meaningful marketplace state changes. Storing
-- localization keys instead of rendered copy keeps Arabic and English views
-- consistent and leaves a clean seam for future push delivery.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  kind text not null check (kind in (
    'new_quote',
    'quote_accepted',
    'quote_declined',
    'completion_requested',
    'job_completed',
    'new_review',
    'verification_approved',
    'verification_rejected',
    'payment_approved',
    'payment_rejected'
  )),
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

-- Only the database triggers below may create notification rows.
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
  if p_recipient_id is null then
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

create or replace function public.tg_notify_quote_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_homeowner uuid;
begin
  if new.status = 'sent' then
    select homeowner_id into v_homeowner
    from public.briefs where id = new.brief_id;
    perform public.create_notification(
      v_homeowner,
      new.contractor_id,
      'new_quote',
      'notificationNewQuoteTitle',
      'notificationNewQuoteBody',
      'brief',
      new.brief_id,
      '{}'::jsonb,
      'new_quote:' || new.id::text
    );
  end if;
  return new;
end;
$$;

create or replace function public.tg_notify_quote_status()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_kind text;
  v_body_key text;
begin
  if old.status = new.status or new.status not in ('accepted', 'declined') then
    return new;
  end if;

  v_kind := case when new.status = 'accepted'
    then 'quote_accepted' else 'quote_declined' end;
  v_body_key := case when new.status = 'accepted'
    then 'notificationQuoteAcceptedBody'
    else 'notificationQuoteDeclinedBody' end;

  perform public.create_notification(
    new.contractor_id,
    null,
    v_kind,
    'notificationQuoteDecisionTitle',
    v_body_key,
    'brief',
    new.brief_id,
    '{}'::jsonb,
    v_kind || ':' || new.id::text
  );
  return new;
end;
$$;

drop trigger if exists notify_quote_created on public.quotes;
create trigger notify_quote_created
  after insert on public.quotes
  for each row execute function public.tg_notify_quote_created();

drop trigger if exists notify_quote_status on public.quotes;
create trigger notify_quote_status
  after update of status on public.quotes
  for each row execute function public.tg_notify_quote_status();

create or replace function public.tg_notify_brief_lifecycle()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_contractor uuid;
begin
  select contractor_id into v_contractor
  from public.quotes
  where brief_id = new.id and status = 'accepted'
  limit 1;

  if old.completion_requested_at is null
     and new.completion_requested_at is not null then
    perform public.create_notification(
      new.homeowner_id,
      v_contractor,
      'completion_requested',
      'notificationCompletionTitle',
      'notificationCompletionRequestedBody',
      'brief',
      new.id,
      '{}'::jsonb,
      'completion_requested:' || new.id::text
    );
  end if;

  if old.completed_at is null and new.completed_at is not null then
    perform public.create_notification(
      v_contractor,
      new.homeowner_id,
      'job_completed',
      'notificationCompletionTitle',
      'notificationJobCompletedBody',
      'brief',
      new.id,
      '{}'::jsonb,
      'job_completed:' || new.id::text
    );
  end if;
  return new;
end;
$$;

drop trigger if exists notify_brief_lifecycle on public.briefs;
create trigger notify_brief_lifecycle
  after update of completion_requested_at, completed_at on public.briefs
  for each row execute function public.tg_notify_brief_lifecycle();

create or replace function public.tg_notify_new_review()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.create_notification(
    new.contractor_id,
    new.homeowner_id,
    'new_review',
    'notificationNewReviewTitle',
    'notificationNewReviewBody',
    'brief',
    new.brief_id,
    jsonb_build_object('rating', new.rating),
    'new_review:' || new.id::text
  );
  return new;
end;
$$;

drop trigger if exists notify_new_review on public.reviews;
create trigger notify_new_review
  after insert on public.reviews
  for each row execute function public.tg_notify_new_review();

create or replace function public.tg_notify_verification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status = new.status or new.status not in ('approved', 'rejected') then
    return new;
  end if;
  perform public.create_notification(
    new.contractor_id,
    null,
    case when new.status = 'approved'
      then 'verification_approved' else 'verification_rejected' end,
    'notificationVerificationTitle',
    case when new.status = 'approved'
      then 'notificationVerificationApprovedBody'
      else 'notificationVerificationRejectedBody' end,
    'verification_request',
    new.id,
    '{}'::jsonb,
    'verification:' || new.id::text || ':' || new.status
  );
  return new;
end;
$$;

drop trigger if exists notify_verification on public.verification_requests;
create trigger notify_verification
  after update of status on public.verification_requests
  for each row execute function public.tg_notify_verification();

create or replace function public.tg_notify_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status = new.status or new.status not in ('approved', 'rejected') then
    return new;
  end if;
  perform public.create_notification(
    new.contractor_id,
    null,
    case when new.status = 'approved'
      then 'payment_approved' else 'payment_rejected' end,
    'notificationPaymentTitle',
    case when new.status = 'approved'
      then 'notificationPaymentApprovedBody'
      else 'notificationPaymentRejectedBody' end,
    'payment_request',
    new.id,
    '{}'::jsonb,
    'payment:' || new.id::text || ':' || new.status
  );
  return new;
end;
$$;

drop trigger if exists notify_payment on public.payment_requests;
create trigger notify_payment
  after update of status on public.payment_requests
  for each row execute function public.tg_notify_payment();

revoke all on function public.tg_notify_quote_created() from public, anon, authenticated;
revoke all on function public.tg_notify_quote_status() from public, anon, authenticated;
revoke all on function public.tg_notify_brief_lifecycle() from public, anon, authenticated;
revoke all on function public.tg_notify_new_review() from public, anon, authenticated;
revoke all on function public.tg_notify_verification() from public, anon, authenticated;
revoke all on function public.tg_notify_payment() from public, anon, authenticated;

create table if not exists public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  event_name text not null check (event_name ~ '^[a-z0-9_]{1,80}$'),
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists analytics_events_user_created_idx
  on public.analytics_events (user_id, created_at desc);
create index if not exists analytics_events_name_created_idx
  on public.analytics_events (event_name, created_at desc);

alter table public.analytics_events enable row level security;
revoke all on public.analytics_events from public, anon, authenticated;
grant insert on public.analytics_events to authenticated;

drop policy if exists "analytics_insert_own" on public.analytics_events;
create policy "analytics_insert_own" on public.analytics_events
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

-- No client read policy: analytics is an operations/admin concern.
