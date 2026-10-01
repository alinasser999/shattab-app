-- Homeowner Professionals publish flow fields.
-- Nullable additions keep historical briefs and older clients readable.

alter table public.briefs
  add column if not exists project_title text,
  add column if not exists estimated_area integer,
  add column if not exists budget_note text,
  add column if not exists start_timing text,
  add column if not exists publish_key text;

alter table public.briefs
  drop constraint if exists briefs_project_title_check,
  add constraint briefs_project_title_check
    check (project_title is null or (length(trim(project_title)) between 2 and 120)),
  drop constraint if exists briefs_estimated_area_check,
  add constraint briefs_estimated_area_check
    check (estimated_area is null or estimated_area between 1 and 100000),
  drop constraint if exists briefs_budget_note_check,
  add constraint briefs_budget_note_check
    check (budget_note is null or length(trim(budget_note)) between 1 and 120),
  drop constraint if exists briefs_start_timing_check,
  add constraint briefs_start_timing_check
    check (start_timing is null or start_timing in ('flexible', 'within_3_months', 'within_month'));

create unique index if not exists briefs_homeowner_publish_key_idx
  on public.briefs (homeowner_id, publish_key)
  where publish_key is not null;

comment on column public.briefs.publish_key is
  'Client-generated idempotency key for the homeowner publish flow.';
