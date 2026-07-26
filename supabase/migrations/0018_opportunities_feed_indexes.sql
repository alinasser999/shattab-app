-- 0018_opportunities_feed_indexes — support the contractor opportunities feed.
--
-- Context: the feed query used to be unbounded (`select ... order by created_at`
-- with no limit), so a contractor downloaded every matching open brief and the
-- client filtered and searched in memory. It is now server-side: keyset
-- pagination on the (created_at, id) tuple plus an ILIKE over work_description.
--
-- These indexes are PERFORMANCE ONLY. The application is correct without them,
-- so this migration is safe to apply at any time and nothing breaks if it is
-- applied late.

-- Keyset pagination sorts by (created_at desc, id desc) and always constrains
-- to open, untargeted, unhired briefs. A partial index on exactly that
-- predicate keeps the scan proportional to the live feed rather than to the
-- full table history.
create index if not exists briefs_open_feed_keyset_idx
  on public.briefs (created_at desc, id desc)
  where target_contractor_id is null
    and hired_at is null
    and status = 'open';

-- `city in (...)` and `target_specialties && (...)` narrow the same feed.
-- The GIN index for the overlap test already exists as
-- `briefs_target_specialties_idx` (0011_scale_indexes). An earlier draft of this
-- migration added a second, byte-identical one under a different name, which
-- cost double on every brief write and gave the planner nothing. Only the city
-- btree is new here.
create index if not exists briefs_city_idx
  on public.briefs (city);

-- Trigram index so `work_description ilike '%...%'` does not force a sequential
-- scan. A leading-wildcard LIKE cannot use a btree index at all; pg_trgm is what
-- makes substring search on this column viable.
create extension if not exists pg_trgm;

create index if not exists briefs_work_description_trgm_idx
  on public.briefs using gin (work_description gin_trgm_ops);

-- Note on Arabic full-text search: Postgres has no built-in `arabic` text search
-- configuration, so to_tsvector('arabic', ...) is not available without an
-- extension. Trigram substring matching behaves well for Arabic here because it
-- is character-based and needs no stemmer. Revisit only if ranking (rather than
-- filtering) becomes a requirement.
