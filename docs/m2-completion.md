---
title: "M2 Completion Report"
date: 2026-05-16
status: complete
---

# Shattab M2 — Customer Core, complete

## What shipped

**Homeowner-side full discovery + request loop:**
- Discover screen with search bar + specialty filter chips + city filter chips
- Contractor profile with WhatsApp / Call / Save / "send my project" CTAs
- Send direct request flow (form + photos ≤5) → confirmation screen
- "My posts" (طلباتي) screen with sections for posts vs direct requests, FAB → new post
- Create-post flow (public to all matching contractors)
- Brief detail view with cancel option
- Saved contractors tab with heart toggle

**Contractor-side (lightweight):**
- "فرص شغل" tab (replaced dashboard placeholder) showing open posts matched by
  specialty ∩ service_area
- Post detail with photos + WhatsApp/Call to homeowner

**Contact:** All contact is external — `https://wa.me/<phone>` and `tel:<phone>` deep links.

## Database additions (migration `0004_briefs_and_saved`)

- `briefs` table — unified direct requests + public posts
- `saved_contractors` table — homeowner ↔ contractor join
- 4 RLS policies + indexes (gin on target_specialties, partial on open posts)
- `brief-photos` storage bucket + owner-prefix policies
- `tg_set_updated_at` trigger on briefs

`get_advisors security` returns zero structural lints. One auth lint
(`auth_leaked_password_protection`) is a dashboard setting unrelated to schema.

## Demo data

3 new contractor seeds:
- محمد سامي — مؤسسة سامي للتشطيبات (paint/design/flooring, 15y, القاهرة الجديدة/مدينة نصر/٦ أكتوبر)
- مينا عاطف — بيت كرافت (kitchen/carpentry/design, 8y, الجيزة/المهندسين/الإسكندرية)
- كريم الفولي — الفولي للسباكة والكهرباء (plumbing/electrical/bathroom, 20y, 4 cities)

3 sample briefs:
- 1 direct (homeowner → شركة بناء الحياة)
- 2 public posts targeting different specialties

All demo contractors have email/password set so the debug login still works.

## Stack changes

- New direct dep: `url_launcher: ^6.3.2`
- New feature directories: `lib/features/{discovery,briefs,saved}/`
- 11 new screens (8 homeowner + 2 contractor + 1 saved tab)
- 5 new reusable widgets (`ContractorCard`, `BriefCard`, `PhotoPicker`,
  `PhotoGallery`, `WhatsAppButton`, `CallButton`, `BatshEmptyState`)
- 3 repositories + 3 provider files

## Deviations from spec

- No structural deviations. Followed the design doc directly.

## Pending follow-ups (NOT in M2 scope)

- Enable Supabase Phone provider in dashboard (still needed before real OTP works)
- The blank-page web rendering issue noticed during M1 smoke test — re-evaluate
  after this M2 rebuild; may have been caused by the previous role_guard bug
- Rotate the Stitch API key (carried from M1)

## What's NOT in M2 (deferred per spec)

- Contractor inbox of direct requests received → M3
- Quote / response system → M3
- Reviews / ratings → M4
- In-app chat → M4
- Push notifications → M4
