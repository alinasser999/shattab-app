---
title: "M2.5 LinkedIn-for-Contractors visual upgrade"
date: 2026-05-16
status: complete
---

# Shattab — LinkedIn-for-Contractors upgrade

Done as an extension of M2 after the user asked the contractor experience to
feel "LinkedIn for contractors" instead of a generic marketplace listing.

## What shipped

### Schema (`0005_portfolio` migration)

- New columns on `contractor_profiles`: `cover_photo_url`, `headline`,
  `projects_completed`, `response_rate`
- New table `portfolio_projects` with photo URLs, category, location, year
- New buckets: `portfolio-photos`, `contractor-covers` (both public read,
  owner-prefix write)
- RLS: portfolio is public-read, owner-only mutate

### Domain + data

- `PortfolioProject` model, `PortfolioRepository`, `portfolioForContractor` +
  `portfolioProject` providers
- `ContractorListing` extended with cover, headline, stats, computed rating

### Visual

- **Rich `ContractorProfileScreen`** with:
  - Wide cover photo hero (240px) with terracotta gradient + fade to bg
  - Big circular avatar with terracotta-ring border, floating across the hero
  - Name + Arabic headline
  - Gold star rating pill (computed from response rate + projects until M4)
  - 3 stat cards in a row: response rate %, projects completed, years exp
  - Big primary CTA "ابعت تفاصيل مشروعك" + WhatsApp + Call row
  - Bio block, specialties + service areas as chips
  - Horizontal portfolio strip with cover thumbnails → "شاهد الكل"
- **`PortfolioGalleryScreen`** (editorial magazine style): vertical scroll of
  large 16:11 cover images with category eyebrow, serif title, description,
  meta row (location, year)
- **`ProjectDetailScreen`** with parallax cover + meta strip + photo gallery
- **Upgraded `ContractorCard`** for discover: cover hero with gradient + save
  heart + peeking avatar + stat chips + specialty pills
- **`FeaturedContractorsStrip`** at top of discover when no filters: top 5
  contractors by computed rating in big landscape tiles
- Discover screen restructured with section headers and edge-to-edge featured

### Seed data

- All 4 contractors got headline + projects_completed + response_rate + cover
- 10 portfolio projects total across the 4 contractors (using Unsplash demo
  images — swap when contractors upload their real work)

## Routes added

- `/h/discover/contractor/:id/portfolio` → PortfolioGalleryScreen
- `/h/discover/contractor/:id/portfolio/:projectId` → ProjectDetailScreen

## What's still placeholder (M4 territory)

- Star rating is computed from response rate + projects, NOT real reviews
- No "endorsements" / recommendations yet
- No "verified" badges (auto-verified in M1 spec)
- Contractor-side portfolio editing screen (so contractors can add their own
  projects via the app) was scoped out of this round — for now portfolio is
  populated via SQL. Editing UI in M3.

## Aesthetic direction

**Modern Heritage editorial** — Mediterranean magazine meets professional
portfolio. Terracotta as the dominant accent. Generous whitespace. Big
imagery. Serif Arabic headlines (Noto Naskh) over sans body (IBM Plex Sans
Arabic). Stat cards are tactile, with subtle warm borders and primary-tinted
shadows. Avatar treatment uses the Stitch "floating card" pattern from the
design system designMd: soft, wide-spread ambient shadow tinted with primary.
