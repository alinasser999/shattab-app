-- 0012_rating_rollup  (DB migration table recorded this as name "0008_rating_rollup",
-- version 20260712150800 — renamed on disk to 0012).
-- Denormalize review rollup onto contractor_profiles so the discover feed reads
-- two ints per card instead of embedding every review row (fanout at scale).

alter table public.contractor_profiles
  add column if not exists rating_avg real not null default 0,
  add column if not exists rating_count int not null default 0;

create or replace function public.tg_reviews_rollup()
returns trigger language plpgsql security definer as $$
declare cid uuid;
begin
  cid := coalesce(new.contractor_id, old.contractor_id);
  update public.contractor_profiles cp
  set rating_count = sub.cnt, rating_avg = sub.avg
  from (
    select count(*)::int as cnt, coalesce(avg(rating), 0)::real as avg
    from public.reviews where contractor_id = cid
  ) sub
  where cp.profile_id = cid;
  return null;
end;
$$;

drop trigger if exists reviews_rollup on public.reviews;
create trigger reviews_rollup
  after insert or update or delete on public.reviews
  for each row execute function public.tg_reviews_rollup();

-- backfill existing contractors
update public.contractor_profiles cp
set rating_count = sub.cnt, rating_avg = sub.avg
from (
  select contractor_id, count(*)::int as cnt, coalesce(avg(rating), 0)::real as avg
  from public.reviews group by contractor_id
) sub
where cp.profile_id = sub.contractor_id;