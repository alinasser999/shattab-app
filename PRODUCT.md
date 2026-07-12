# Shattab (شطب) — Egyptian Contractor Hiring Marketplace

## Register

product

## One-Liner

Mobile marketplace connecting Egyptian homeowners with verified contractors for renovation and finishing jobs. Homeowners post work briefs; contractors quote, get hired, and build portfolios.

## Users

**Homeowners (طالب خدمة):** Egyptian apartment/ villa owners (25–50) who need renovation, finishing, painting, electrical, or plumbing work. They want to discover vetted contractors, compare quotes, check portfolios and reviews, and hire without middlemen. Primary touchpoints: discover screen, brief creation, quote review.

**Contractors (مقاول):** Independent Egyptian finishing contractors, electricians, plumbers, painters (25–55). They want job leads matched to their specialty and service area, a simple quoting flow, an inbox for direct requests, and a portfolio to showcase work. Primary touchpoints: opportunities feed, inbox, portfolio management.

## Product Purpose

Solve the trust and discovery problem in Egypt's fragmented home renovation market. Homeowners don't know who to trust; contractors can't find consistent leads. Shattab bridges both sides with phone OTP auth (no passwords), role-based onboarding, specialty/area matching, WhatsApp/Call contact (no in-app chat), and a quotes system.

## Tech Stack

- **Client:** Flutter 3.41 (Android + iOS, no web/desktop)
- **Backend:** Supabase (Postgres, Auth, Storage, RLS)
- **State:** Riverpod 3.x with codegen (`riverpod_annotation`)
- **Routing:** go_router v17 with `StatefulShellRoute.indexedStack`
- **Auth:** Phone OTP only (+20 Egypt), role locked at signup
- **Contact:** WhatsApp/Call deep links via `url_launcher` (no in-app chat)
- **Design:** Modern Heritage — terracotta (`#9E3D18`), olive, gold, warm cream
- **Fonts:** Cairo & Tajawal (Arabic-first with Latin fallback) via google_fonts

## Database Schema (Supabase, 4 migrations)

| Table | Purpose |
|-------|---------|
| `profiles` | Auth base — role, name, phone, avatar |
| `homeowner_profiles` | Apartment type, city/district, renovation interests |
| `contractor_profiles` | Business name, bio, specialties[], service_areas[], experience |
| `briefs` | Job posts — description, apt type, city, photos, target specialties, homeowner_id, is_post/direct, status |
| `saved_contractors` | Homeowner bookmark list (profile_id + contractor_id) |
| `projects` | Portfolio — title, category, year, location, description, photos[] |
| `quotes` | Price proposals — brief_id, contractor_id, price_min/max, duration, note, status |
| `reviews` | Ratings — 1–5 stars, comment, linked to brief + accepted quote |

## Feature Map

### M1 Foundation (Done)
- Phone OTP auth with role choice (homeowner | contractor)
- Onboarding: collect profile details, specialties, service areas
- Role-aware routing: `/h/*` for homeowner, `/c/*` for contractor
- Core theme: BatshColors, BatshTypography, BatshSpacing, BatshRadius, BatshShadows, BatshMotion
- Atomic widgets: BatshCard, BatshChip, BatshButton, BatshScaffold, BatshTextField, BatshShimmer, BatshEmptyState, BatshError, BatshLoading

### M2 Customer Core (Done)
- Homeowner: discover contractors by specialty/city, view profiles, save/bookmark
- Homeowner: create public brief (post) or send direct request to specific contractor
- Homeowner: my posts & requests screen
- Contractor: "فرص شغل" opportunities feed — open briefs matched by specialty ∩ service_area
- Contact: WhatsApp + Call CTA on every matched brief and quote
- DB: briefs, saved_contractors tables + storage bucket

### M3 Contractor Core (Done)
- Quotes: send/receive/accept/decline (one quote per contractor per brief)
- Contractor inbox (Tab 2): direct requests with quote status badges
- Contractor portfolio (Tab 3): CRUD projects with photos
- Homeowner quote review: accept/decline/rate in brief detail
- Motion: flutter_animate staggered entrances, shimmer skeletons, hero transitions

### M4 (Not started)
- Push notifications, in-app chat, reviews polish, admin tools

## Shell Structure

### Homeowner (`/h/*`) — 4 tabs
1. **اكتشف (Discover)** — Contractor search/filter by specialty/city, featured + trending + all contractors
2. **طلباتي (Requests)** — Own briefs + direct requests, FAB to create new post
3. **المحفوظات (Saved)** — Saved/bookmarked contractors
4. **حسابي (Profile)** — Identity card, stats, dark/motion mode toggles, sign out

### Contractor (`/c/*`) — 4 tabs
1. **فرص شغل (Opportunities)** — Open briefs matched by specialty, filter chips, send quote
2. **الطلبات (Inbox)** — Direct briefs sent to contractor, quote status badges
3. **أعمالي (Portfolio)** — CRUD portfolio projects with photos
4. **حسابي (Profile)** — Contractor showcase, edit profile, sign out

## Design Principles

1. **Trust first** — Terracotta primary anchors warmth and reliability; clear labels, verified contractor badges, transparent pricing
2. **Egyptian Modern Heritage** — Warm cream surfaces, olive secondary (growth/trust), gold tertiary (craft/value), not generic SaaS tones
3. **Arabic-native, not translated** — RTL by default, Arabic-first fonts (Cairo + Tajawal), all copy in `strings.dart`
4. **Contact, not chat** — All connections happen via WhatsApp/Call. No in-app messaging keeps scope focused and trust high
5. **Skeletons before spinners** — Every async surface shows shimmer skeletons, never `CircularProgressIndicator` in the middle of content

## Accessibility & Inclusion

- Arabic RTL throughout — text direction, alignment, nav flow
- Phone OTP only — no email/password barrier in a market where email is not universal
- Minimum touch targets 44×44dp
- Reduced motion respected via `BatshMotion` tokens
- WCAG AA contrast target — terracotta on cream tested via BatshColors

## Key Conventions

- All Arabic copy in `lib/core/l10n/strings.dart` class `S`
- `Batsh*` widgets only — no bare Material widgets outside theme layer
- `package:batsh/...` imports (repo name not changed from original `batsh`)
- `.value` not `.valueOrNull` (removed in Riverpod 3)
- Custom `copyWith` + `fromJson` for domain models (no freezed unless 8+ fields)
- `flutter_animate` for all animations, `Cairo` for display, `Tajawal` for body
