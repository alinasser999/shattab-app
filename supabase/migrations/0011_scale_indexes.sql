-- 0011_scale_indexes  (DB migration table recorded this as name "0007_scale_indexes",
-- version 20260712150737 — renamed on disk to 0011 to sit after the existing 0010).
-- Discover-feed scale: cheap pagination+sort and real search.

-- (1) composite index so discover's order('full_name')+range pages cheaply
create index if not exists profiles_role_fullname_idx
  on public.profiles (role, full_name);

-- (3) trigram search — kills the ilike '%q%' seq-scan
create extension if not exists pg_trgm;
create index if not exists profiles_fullname_trgm_idx
  on public.profiles using gin (full_name gin_trgm_ops);
create index if not exists contractor_business_trgm_idx
  on public.contractor_profiles using gin (business_name gin_trgm_ops);