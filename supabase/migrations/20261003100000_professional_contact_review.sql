-- Homeowner reported reviews following a successful WhatsApp handoff.
-- This migration is source only; apply it through the reviewed release process.

create table public.professional_contact_episodes (
  id uuid primary key default gen_random_uuid(),
  homeowner_id uuid not null references public.profiles(id) on delete cascade,
  contractor_id uuid not null references public.profiles(id) on delete cascade,
  first_contacted_at timestamptz not null default now(),
  state text not null default 'open'
    check (state in ('open', 'dismissed', 'not_worked_together', 'review_submitted')),
  review_id uuid unique references public.reviews(id) on delete set null,
  constraint professional_contact_episode_participants_differ
    check (homeowner_id <> contractor_id)
);

create unique index professional_contact_episode_one_open_pair_idx
  on public.professional_contact_episodes (homeowner_id, contractor_id)
  where state = 'open';

create index professional_contact_episode_due_idx
  on public.professional_contact_episodes (homeowner_id, first_contacted_at)
  where state = 'open';

alter table public.professional_contact_episodes enable row level security;
revoke all on public.professional_contact_episodes from public, anon, authenticated;

alter table public.reviews alter column brief_id drop not null;
alter table public.reviews add column review_source text;
alter table public.reviews
  add constraint reviews_review_source_check
  check (review_source is null or review_source = 'professional_contact');
alter table public.reviews
  add constraint reviews_review_source_brief_check
  check (
    (review_source is null and brief_id is not null)
    or (review_source = 'professional_contact' and brief_id is null)
  );

-- Keep the existing completed-brief review gate and prevent direct API writes
-- from forging or changing the contact-origin attribution.
drop policy if exists "reviews_homeowner_insert" on public.reviews;
create policy "reviews_homeowner_insert" on public.reviews
  for insert with check (
    homeowner_id = (select auth.uid())
    and review_source is null
    and exists (
      select 1 from public.briefs b
      where b.id = reviews.brief_id
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

drop policy if exists "reviews_homeowner_update" on public.reviews;
create policy "reviews_homeowner_update" on public.reviews
  for update using (
    homeowner_id = (select auth.uid())
    and review_source is null
  )
  with check (
    homeowner_id = (select auth.uid())
    and review_source is null
  );

create or replace function public.record_professional_whatsapp_contact(
  p_contractor_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_homeowner_id uuid := auth.uid();
  v_episode_id uuid;
begin
  if v_homeowner_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = v_homeowner_id and p.role = 'homeowner'
  ) then
    raise exception 'homeowner account required' using errcode = '42501';
  end if;

  if p_contractor_id is null or not exists (
    select 1 from public.profiles p
    where p.id = p_contractor_id and p.role = 'contractor'
  ) then
    raise exception 'contractor account required' using errcode = '22023';
  end if;

  insert into public.professional_contact_episodes (
    homeowner_id,
    contractor_id
  ) values (
    v_homeowner_id,
    p_contractor_id
  )
  on conflict (homeowner_id, contractor_id) where state = 'open'
  do nothing;

  select e.id into v_episode_id
  from public.professional_contact_episodes e
  where e.homeowner_id = v_homeowner_id
    and e.contractor_id = p_contractor_id
    and e.state = 'open';

  return v_episode_id;
end;
$$;

create or replace function public.get_oldest_due_professional_contact_review()
returns table (
  episode_id uuid,
  contractor_id uuid,
  contractor_name text,
  first_contacted_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_homeowner_id uuid := auth.uid();
begin
  if v_homeowner_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = v_homeowner_id and p.role = 'homeowner'
  ) then
    raise exception 'homeowner account required' using errcode = '42501';
  end if;

  return query
  select e.id,
         e.contractor_id,
         coalesce(nullif(btrim(cp.business_name), ''), nullif(btrim(p.full_name), ''), ''),
         e.first_contacted_at
  from public.professional_contact_episodes e
  join public.profiles p on p.id = e.contractor_id and p.role = 'contractor'
  left join public.contractor_profiles cp on cp.profile_id = p.id
  where e.homeowner_id = v_homeowner_id
    and e.state = 'open'
    and e.first_contacted_at <= now() - interval '30 days'
  order by e.first_contacted_at asc, e.id asc
  limit 1;
end;
$$;

create or replace function public.dismiss_professional_contact_review(
  p_episode_id uuid
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_homeowner_id uuid := auth.uid();
begin
  if v_homeowner_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = v_homeowner_id and p.role = 'homeowner'
  ) then
    raise exception 'homeowner account required' using errcode = '42501';
  end if;

  update public.professional_contact_episodes e
  set state = 'dismissed'
  where e.id = p_episode_id
    and e.homeowner_id = v_homeowner_id
    and e.state = 'open'
    and e.first_contacted_at <= now() - interval '30 days';
end;
$$;

create or replace function public.mark_not_worked_together(
  p_episode_id uuid
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_homeowner_id uuid := auth.uid();
begin
  if v_homeowner_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = v_homeowner_id and p.role = 'homeowner'
  ) then
    raise exception 'homeowner account required' using errcode = '42501';
  end if;

  update public.professional_contact_episodes e
  set state = 'not_worked_together'
  where e.id = p_episode_id
    and e.homeowner_id = v_homeowner_id
    and e.state = 'open'
    and e.first_contacted_at <= now() - interval '30 days';
end;
$$;

create or replace function public.submit_professional_contact_review(
  p_episode_id uuid,
  p_rating smallint,
  p_comment text default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_homeowner_id uuid := auth.uid();
  v_episode public.professional_contact_episodes%rowtype;
  v_review_id uuid;
  v_comment text := nullif(btrim(p_comment), '');
begin
  if v_homeowner_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.profiles p
    where p.id = v_homeowner_id and p.role = 'homeowner'
  ) then
    raise exception 'homeowner account required' using errcode = '42501';
  end if;

  if p_rating is null or p_rating < 1 or p_rating > 5 then
    raise exception 'rating must be between 1 and 5' using errcode = '22023';
  end if;

  if v_comment is not null and char_length(v_comment) > 400 then
    raise exception 'comment is too long' using errcode = '22023';
  end if;

  select e.* into v_episode
  from public.professional_contact_episodes e
  where e.id = p_episode_id and e.homeowner_id = v_homeowner_id
  for update;

  if not found then
    return null;
  end if;

  if v_episode.state = 'review_submitted' then
    return v_episode.review_id;
  end if;

  if v_episode.state <> 'open'
    or v_episode.first_contacted_at > now() - interval '30 days' then
    return null;
  end if;

  insert into public.reviews (
    brief_id,
    contractor_id,
    homeowner_id,
    rating,
    comment,
    review_source
  ) values (
    null,
    v_episode.contractor_id,
    v_homeowner_id,
    p_rating,
    v_comment,
    'professional_contact'
  ) returning id into v_review_id;

  update public.professional_contact_episodes e
  set state = 'review_submitted', review_id = v_review_id
  where e.id = v_episode.id;

  return v_review_id;
end;
$$;

revoke all on function public.record_professional_whatsapp_contact(uuid)
  from public, anon, authenticated;
revoke all on function public.get_oldest_due_professional_contact_review()
  from public, anon, authenticated;
revoke all on function public.dismiss_professional_contact_review(uuid)
  from public, anon, authenticated;
revoke all on function public.mark_not_worked_together(uuid)
  from public, anon, authenticated;
revoke all on function public.submit_professional_contact_review(uuid, smallint, text)
  from public, anon, authenticated;

grant execute on function public.record_professional_whatsapp_contact(uuid)
  to authenticated;
grant execute on function public.get_oldest_due_professional_contact_review()
  to authenticated;
grant execute on function public.dismiss_professional_contact_review(uuid)
  to authenticated;
grant execute on function public.mark_not_worked_together(uuid)
  to authenticated;
grant execute on function public.submit_professional_contact_review(uuid, smallint, text)
  to authenticated;

-- Contact-origin reviews have no brief destination. Preserve the established
-- brief notification while preventing a null-brief notification from entering
-- the inbox/push pipeline.
create or replace function public.tg_notify_new_review()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if new.brief_id is null then
    return new;
  end if;

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

revoke execute on function public.tg_notify_new_review()
  from public, anon, authenticated;
