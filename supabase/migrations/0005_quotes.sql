-- Batsh M3 — quotes: contractors price/timeline proposals on briefs.
-- One quote per contractor per brief; homeowner can accept/decline.
-- Reuses public.tg_set_updated_at() from migration 0001.

-- ── Table ───────────────────────────────────────────────────────────────────

create table if not exists public.quotes (
  id uuid primary key default gen_random_uuid(),
  brief_id uuid not null references public.briefs(id) on delete cascade,
  contractor_id uuid not null references public.profiles(id) on delete cascade,
  price_min int4,          -- EGP, optional
  price_max int4,          -- EGP, optional (equal to min for a fixed price)
  duration_text text,      -- e.g. "أسبوعين", "شهر"
  note text not null,
  status text not null default 'sent'
    check (status in ('sent', 'accepted', 'declined', 'withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (brief_id, contractor_id)
);

create index if not exists quotes_brief_idx on public.quotes(brief_id);
create index if not exists quotes_contractor_idx on public.quotes(contractor_id);

-- ── Triggers ────────────────────────────────────────────────────────────────

drop trigger if exists set_quotes_updated_at on public.quotes;
create trigger set_quotes_updated_at before update on public.quotes
  for each row execute procedure public.tg_set_updated_at();

-- ── RLS ─────────────────────────────────────────────────────────────────────

alter table public.quotes enable row level security;

-- Contractor: full control over their own quotes.
drop policy if exists "contractor_own" on public.quotes;
create policy "contractor_own"
  on public.quotes for all
  using (contractor_id = auth.uid())
  with check (contractor_id = auth.uid());

-- Homeowner: read quotes left on their own briefs.
drop policy if exists "homeowner_read" on public.quotes;
create policy "homeowner_read"
  on public.quotes for select
  using (
    exists (
      select 1 from public.briefs b
      where b.id = brief_id and b.homeowner_id = auth.uid()
    )
  );

-- Homeowner: may only move status to accepted/declined on their own briefs.
drop policy if exists "homeowner_status" on public.quotes;
create policy "homeowner_status"
  on public.quotes for update
  using (
    exists (
      select 1 from public.briefs b
      where b.id = brief_id and b.homeowner_id = auth.uid()
    )
  )
  with check (status in ('accepted', 'declined'));
