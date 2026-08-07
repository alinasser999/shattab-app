-- Arabic-aware contractor search.
--
-- Two defects this closes, both in `DiscoveryRepository.fetchContractors`:
--
--   1. Only `contractor_profiles.business_name` was searched. PostgREST cannot
--      OR a base column against an embedded one in a single request, so an
--      individual professional with no business name was unfindable by name.
--
--   2. `ilike '%q%'` is exact-substring, and Egyptians do not type Arabic
--      exactly. `احمد` did not match `أحمد`; `فاطمه` did not match `فاطمة`;
--      `يحيي` did not match `يحيى`. Searching your own name and getting an
--      empty screen reads as "this app has no contractors", not "type a hamza".
--
-- Both are fixed server-side by folding the orthographic variants on each side
-- of the comparison, and by doing the OR in SQL where it is expressible.
--
-- The function is SECURITY INVOKER (the default) on purpose: RLS on `profiles`
-- and `contractor_profiles` continues to apply exactly as it does on the REST
-- path. This migration changes what can be *found*, never what can be *read*.

-- ── normalization ──────────────────────────────────────────────────────────
-- Folds the variants Arabic keyboards produce interchangeably:
--   أ إ آ ٱ → ا      hamza-carrying alef forms
--   ى ئ     → ي      dotless / hamza-carrying ya
--   ؤ       → و
--   ة       → ه      ta marbuta, routinely typed as ha
-- and strips tashkeel (U+064B–U+0652), tatweel (U+0640) and the superscript
-- alef (U+0670), none of which a searcher reliably types.
--
-- IMMUTABLE so it can back an expression index. `search_path = ''` with
-- pg_catalog-qualified calls keeps the body resolvable no matter what schema
-- the caller sits in.
-- `translate` pairs positionally, so `from` and `to` must be the same length —
-- a `to` one character longer silently shifts every mapping past that point.
--   from: أ إ آ ٱ ى ئ ؤ ة   (8)
--   to:   ا ا ا ا ي ي و ه   (8)
--
-- coalesce/least/greatest are SQL constructs rather than pg_catalog functions,
-- so they cannot be schema-qualified even under `search_path = ''`.
create or replace function public.shattab_normalize_ar(p_text text)
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  select pg_catalog.translate(
    pg_catalog.regexp_replace(
      pg_catalog.lower(coalesce(p_text, '')),
      '[ً-ْـٰ]', '', 'g'
    ),
    'أإآٱىئؤة',
    'ااااييوه'
  );
$$;

comment on function public.shattab_normalize_ar(text) is
  'Folds Arabic orthographic variants and strips diacritics so search matches '
  'how people actually type. Applied to both sides of the comparison, so the '
  'client sends the raw query and never needs a matching implementation.';

-- ── indexes on the normalized form ─────────────────────────────────────────
-- The plain-column trigram indexes from 0011 cannot serve a query whose
-- predicate is `normalize(col) like ...`; the expression has to be indexed as
-- written or every search is a sequential scan.
create index if not exists profiles_full_name_norm_trgm_idx
  on public.profiles
  using gin (public.shattab_normalize_ar(full_name) gin_trgm_ops);

create index if not exists contractor_profiles_business_name_norm_trgm_idx
  on public.contractor_profiles
  using gin (public.shattab_normalize_ar(business_name) gin_trgm_ops);

-- ── the search itself ──────────────────────────────────────────────────────
-- Returns rows shaped exactly like the PostgREST embed the client already
-- parses (`ContractorListing.fromJoined`), so the Dart model is untouched:
--   { id, full_name, phone, contractor_profiles: { ... } }
create or replace function public.discover_contractors(
  p_query      text default null,
  p_specialty  text default null,
  p_city       text default null,
  p_limit      int  default 20,
  p_offset     int  default 0
)
returns setof jsonb
language sql
stable
set search_path = ''
as $$
  with needle as (
    -- Escape LIKE metacharacters *after* folding. Without this a user typing a
    -- bare `%` turns the predicate into match-everything, and `_` silently
    -- matches any single character — the same hole `sanitizeLikePattern` closes
    -- on the briefs side, fixed here at the only point that builds the pattern.
    select pg_catalog.replace(
             pg_catalog.replace(
               pg_catalog.replace(
                 public.shattab_normalize_ar(
                   pg_catalog.btrim(coalesce(p_query, ''))
                 ),
                 '\', '\\'
               ),
               '%', '\%'
             ),
             '_', '\_'
           ) as q
  )
  select jsonb_build_object(
    'id',        p.id,
    'full_name', p.full_name,
    'phone',     p.phone,
    'contractor_profiles', jsonb_build_object(
      'business_name',      cp.business_name,
      'bio',                cp.bio,
      'logo_url',           cp.logo_url,
      'cover_photo_url',    cp.cover_photo_url,
      'headline',           cp.headline,
      'specialties',        cp.specialties,
      'service_areas',      cp.service_areas,
      'years_experience',   cp.years_experience,
      'projects_completed', cp.projects_completed,
      'response_rate',      cp.response_rate,
      'rating_avg',         cp.rating_avg,
      'rating_count',       cp.rating_count,
      'verified',           cp.verified,
      'plan',               cp.plan,
      'provider_kind',      cp.provider_kind,
      'created_at',         cp.created_at
    )
  )
  from public.profiles p
  join public.contractor_profiles cp on cp.profile_id = p.id
  cross join needle n
  where p.role = 'contractor'
    and (p_specialty is null or cp.specialties   @> array[p_specialty])
    and (p_city      is null or cp.service_areas @> array[p_city])
    and (
      n.q = '' or
      public.shattab_normalize_ar(cp.business_name) like '%' || n.q || '%' or
      public.shattab_normalize_ar(p.full_name)      like '%' || n.q || '%'
    )
  -- Prefix matches first: someone typing "أح" means the name that starts that
  -- way, not the one that happens to contain it. Then full_name + id so the
  -- ordering is total and pages cannot reshuffle under pagination.
  order by
    case
      when n.q = '' then 1
      when public.shattab_normalize_ar(cp.business_name) like n.q || '%'
        or public.shattab_normalize_ar(p.full_name)      like n.q || '%'
      then 0
      else 1
    end,
    p.full_name,
    p.id
  limit  least(greatest(p_limit, 1), 50)
  offset greatest(p_offset, 0);
$$;

comment on function public.discover_contractors(text, text, text, int, int) is
  'Discovery search across full_name and business_name with Arabic folding. '
  'SECURITY INVOKER: RLS on profiles/contractor_profiles still applies.';

revoke all on function public.discover_contractors(text, text, text, int, int)
  from public, anon;
grant execute on function public.discover_contractors(text, text, text, int, int)
  to authenticated;
