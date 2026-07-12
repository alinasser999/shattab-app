-- 0006_reviews — contractor reviews (M4)
-- One review per brief. Homeowner may review only after accepting a quote
-- from that contractor on that brief ("accepted quote = hireable").

create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  brief_id uuid not null references briefs(id) on delete cascade,
  contractor_id uuid not null references profiles(id),
  homeowner_id uuid not null references profiles(id),
  rating int2 not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (brief_id)
);

create index if not exists reviews_contractor_id_idx on reviews (contractor_id);

create trigger set_updated_at before update on reviews
  for each row execute function tg_set_updated_at();

alter table reviews enable row level security;

-- Public read: ratings are visible to everyone.
create policy "reviews_public_read" on reviews
  for select using (true);

-- Homeowner may post a review only for their own brief, and only when an
-- accepted quote from that contractor exists on that brief.
create policy "reviews_homeowner_insert" on reviews
  for insert with check (
    homeowner_id = auth.uid()
    and exists (
      select 1 from briefs b
      where b.id = brief_id and b.homeowner_id = auth.uid()
    )
    and exists (
      select 1 from quotes q
      where q.brief_id = reviews.brief_id
        and q.contractor_id = reviews.contractor_id
        and q.status = 'accepted'
    )
  );

-- Homeowner may edit their own review.
create policy "reviews_homeowner_update" on reviews
  for update using (homeowner_id = auth.uid())
  with check (homeowner_id = auth.uid());
