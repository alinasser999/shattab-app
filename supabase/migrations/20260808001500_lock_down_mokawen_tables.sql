-- Close six tables that were reachable by anyone holding the anon key.
--
-- `create_mokawen_tables` (2026-08-03) created scan_misses,
-- user_product_submissions, product_drafts, ingestion_jobs, ingestion_items and
-- ocr_extractions with RLS never enabled and the default PostgREST grants left
-- in place. The Supabase security advisor rates that ERROR, and a direct check
-- confirmed it: anon could both SELECT and INSERT on all six. The anon key ships
-- inside every copy of the mobile app, so this was world-readable and
-- world-writable in practice.
--
-- These tables belong to a different product (OCR / product ingestion), are
-- referenced nowhere in this repo, and were all empty (0 rows, verified before
-- applying). Nothing is dropped here — dropping is irreversible and is the
-- owner's decision, not an inference from context. This is the reversible move:
-- enable RLS with no policies, which denies every non-superuser role by
-- default, and take back the API grants so PostgREST stops exposing them.
--
-- To undo: `alter table ... disable row level security;` and re-grant.
-- To use them properly later: add explicit policies; RLS is already on.

do $$
declare
  t text;
begin
  foreach t in array array[
    'scan_misses',
    'user_product_submissions',
    'product_drafts',
    'ingestion_jobs',
    'ingestion_items',
    'ocr_extractions'
  ]
  loop
    if to_regclass('public.' || t) is not null then
      execute format('alter table public.%I enable row level security', t);
      execute format('revoke all on public.%I from anon, authenticated', t);
    end if;
  end loop;
end
$$;
