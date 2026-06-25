---
title: "Shattab — M2 Customer Core Design"
date: 2026-05-16
status: approved-architecture
milestone: M2
---

# Shattab (شطب) — M2 Customer Core

## 1. Goal

Make the homeowner side functionally real: discover contractors, save them,
send a project brief either to a specific contractor or as a public post.
Add the minimum contractor-side surface needed to close the loop on public
posts ("جوب opportunities" tab listing matched posts).

Contact happens externally via WhatsApp / phone — chat stays deferred to M4.

## 2. Locked decisions (carried from brainstorming 2026-05-16)

| # | Decision | Rationale |
|---|---|---|
| 1 | External contact only (WhatsApp / Call) | Egyptians live on WhatsApp; in-app chat half-broken without push (M4) |
| 2 | Unified `briefs` table with optional `target_contractor_id` | Direct request and public post share ~95% of fields |
| 3 | Photos: up to 5 per brief, public bucket | Renovation work is visual; same storage pattern as M1 |
| 4 | No budget field | Per user — keeps form short, avoids price anchoring |
| 5 | No "interested" tracking, no quote system | Defers to M3; status is just `open / cancelled` |
| 6 | Saved contractors built in M2 | Closes the M1 placeholder tab |
| 7 | Contractor M2 surface = one tab "فرص شغل" only | Don't bleed M3 contractor dashboard into M2 |
| 8 | Phone numbers always shared in briefs | Required for the contact mechanism to work; surfaced in UI copy |

## 3. Screens

### Homeowner (8 new + 4 placeholders activated)

| Route | Screen | Notes |
|---|---|---|
| `/h/discover` | `DiscoverScreen` | Search bar (by name) + filter chips (specialty + city) + scrollable list of contractor cards |
| `/h/discover/contractor/:id` | `ContractorProfileScreen` | Hero with logo + name + bio + chips. Top-right heart toggles save. Bottom CTAs: WhatsApp (primary), Call, "ابعت تفاصيل مشروعك" |
| `/h/discover/contractor/:id/brief` | `SendBriefScreen` | Form: apartment context (auto-filled, editable) + work description + photo picker (≤5) |
| `/h/discover/contractor/:id/brief/sent` | `BriefSentConfirmationScreen` | "تم — المقاول هيتواصل" + WhatsApp shortcut |
| `/h/requests` | `MyBriefsScreen` | Two sections: "بوستات مفتوحة" + "طلبات مباشرة". FAB → CreatePostScreen |
| `/h/requests/new-post` | `CreatePostScreen` | Same form + multi-select "بدور على مين؟" (target_specialties) |
| `/h/requests/:id` | `BriefDetailScreen` | View what you sent. Cancel button (sets status=cancelled) |
| `/h/saved` | `SavedContractorsScreen` | List of saved contractors, same card style |
| `/h/profile` | (existing) | unchanged from M1 |

### Contractor (1 new + 1 placeholder activated)

| Route | Screen | Notes |
|---|---|---|
| `/c/dashboard` (relabel "فرص شغل") | `JobOpportunitiesScreen` | Posts matching contractor's specialties ∩ service_areas, newest first |
| `/c/dashboard/post/:id` | `PostDetailScreen` | Full brief view + photos + WhatsApp/Call to homeowner |
| `/c/inbox`, `/c/portfolio` | (placeholders) | Stay as M3 placeholders |
| `/c/profile` | (existing) | unchanged from M1 |

## 4. Data model

### 4.1 New tables

```sql
create table public.briefs (
  id uuid primary key default gen_random_uuid(),
  homeowner_id uuid not null references public.profiles(id) on delete cascade,
  target_contractor_id uuid references public.profiles(id) on delete set null,
  -- target set: direct request (only that contractor sees it)
  -- target null: public post (all matching contractors see it)

  apartment_type text not null check (apartment_type in (
    'studio', 'one_bedroom', 'two_bedroom', 'three_bedroom_plus',
    'duplex', 'villa', 'penthouse'
  )),
  city text not null,
  district text,
  work_description text not null check (length(work_description) between 10 and 2000),
  photo_urls text[] not null default '{}' check (array_length(photo_urls, 1) <= 5),
  target_specialties text[] not null default '{}',
  -- only meaningful when target_contractor_id is null

  status text not null default 'open' check (status in ('open', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index briefs_homeowner_idx on public.briefs(homeowner_id);
create index briefs_target_contractor_idx on public.briefs(target_contractor_id);
create index briefs_target_specialties_idx on public.briefs using gin (target_specialties);
create index briefs_open_posts_idx on public.briefs(status, created_at desc)
  where target_contractor_id is null and status = 'open';

create table public.saved_contractors (
  homeowner_id uuid not null references public.profiles(id) on delete cascade,
  contractor_id uuid not null references public.profiles(id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (homeowner_id, contractor_id)
);

create index saved_contractors_homeowner_idx on public.saved_contractors(homeowner_id);
```

### 4.2 RLS policies

```sql
alter table public.briefs enable row level security;

-- Homeowner full access to own briefs
create policy "homeowner own briefs"
  on public.briefs for all
  using (auth.uid() = homeowner_id)
  with check (auth.uid() = homeowner_id);

-- Contractor reads briefs targeted at them
create policy "contractor read direct briefs"
  on public.briefs for select
  using (auth.uid() = target_contractor_id);

-- Contractor reads open public posts that match their specialties + service areas
create policy "contractor read matched open posts"
  on public.briefs for select
  using (
    target_contractor_id is null
    and status = 'open'
    and exists (
      select 1 from public.contractor_profiles cp
      where cp.profile_id = auth.uid()
        and (target_specialties && cp.specialties)
        and (briefs.city = ANY(cp.service_areas))
    )
  );

alter table public.saved_contractors enable row level security;

create policy "owner full access saved contractors"
  on public.saved_contractors for all
  using (auth.uid() = homeowner_id)
  with check (auth.uid() = homeowner_id);
```

### 4.3 Storage

New bucket `brief-photos` — public read; owner-prefix write (path:
`{homeowner_id}/{brief_id}/{n}.jpg`).

### 4.4 Trigger

`updated_at` maintenance trigger on `briefs` (reuse existing `tg_set_updated_at`).

## 5. Notable widgets to add

- `ContractorCard` — used in DiscoverScreen + SavedContractorsScreen
- `BriefCard` — used in MyBriefsScreen + JobOpportunitiesScreen
- `PhotoPicker` — wraps image_picker, manages a list of File or Url, shows thumbnails with remove buttons
- `WhatsAppButton`, `CallButton` — open `whatsapp://send?phone=...` and `tel:` deep links
- `EmptyState` — generic empty list placeholder, used in 3 screens

## 6. Out of scope (defer)

- Contractor inbox of direct requests received → M3
- Quote / response system → M3
- Reviews / ratings → M4
- In-app chat → M4
- Push notifications → M4
- Featured / boosted contractors → post-MVP
- Map view of contractors → post-MVP
- Multi-language (only Arabic for now) → post-MVP

## 7. Definition of M2 complete

- [ ] Migration `0004_briefs_and_saved` applied; advisors clean
- [ ] `brief-photos` storage bucket created with policies
- [ ] All 8 homeowner screens render and round-trip data
- [ ] All 2 contractor screens render
- [ ] Heart toggle on contractor card persists
- [ ] WhatsApp deep link opens external app with the right number
- [ ] Photo upload (web + mobile) works for ≤5 photos per brief
- [ ] Demo data: at least 3 more contractors seeded for a usable discover feed
- [ ] `flutter analyze` clean, `flutter test` green
- [ ] Wiki log updated
