# Shattab — Claude Code Context

> **Stale past M3.** This file stops at M3 and its M4 line below is wrong —
> reviews, monetization, verification, moderation, a social feed, push
> notifications, realtime, Arabic search, and a separate admin console have
> all since shipped. **Read [`AI_ONBOARDING.md`](AI_ONBOARDING.md) first** —
> it is the maintained current-state map. Where the two disagree, it is right.

## Quick Summary (for ChatGPT 🤖)
**Shattab (شطب)** — Flutter marketplace for Egyptian home renovation.

**Two user types:**
- **Homeowner** → posts renovation jobs, gets quotes, hires contractors, leaves reviews
- **Contractor** → finds matching jobs, sends quotes, manages portfolio, gets hired

**User flow:**
1. Sign up via phone OTP (+20 Egypt only) → pick role → fill onboarding
2. **Homeowner:** Browse contractors → view profiles → send direct request OR post public job → receive & manage quotes → accept/decline → review contractor
3. **Contractor:** View matched job opportunities → send quotes → manage portfolio (Tab 3) → receive direct requests in inbox (Tab 2) → get hired

**Key rules:** No in-app chat (WhatsApp/Call only). Arabic-first RTL. Flutter 3.41 + Supabase + Riverpod 3.x + go_router 17.

---

## Project
**Shattab (شطب)** — Egyptian contractor hiring marketplace. Homeowners post renovation jobs; contractors quote and get hired.

Repo originally named `batsh` (user changed brand to Shattab in M2). Keep `package:batsh/...` imports — repo was not renamed to avoid churn.

---

## Stack
- Flutter 3.41, Android + iOS only (web/desktop disabled)
- Supabase (auth + postgres + storage) — project ref `ajqdutehxpbbflzdovhw`, region `eu-central-1`
- Riverpod 3.x with codegen (`riverpod_annotation`, `@Riverpod`)
- `go_router` v17 with `StatefulShellRoute.indexedStack`
- Phone OTP auth only (+20 Egypt), role locked at signup (homeowner OR contractor)
- Arabic RTL by default; all copy in `lib/core/l10n/strings.dart`
- Feature-first structure: `lib/features/<name>/{data,domain,presentation}`

## Key constraints
- Use `.value` not `.valueOrNull` (removed in Riverpod 3)
- `riverpod_lint` NOT installed (conflicts with freezed_annotation ^3.x)
- New domain models: hand-written `copyWith` + `fromJson`, NOT freezed (unless 8+ fields or union variants)
- Never use raw hex — reference `BatshColors.*`, `BatshTypography.*`, `BatshSpacing.*`
- Compose `Batsh*` atomic widgets, not bare Material widgets

## Design system
Modern Heritage — terracotta `#9e3d18` (primary), olive (secondary), gold (tertiary), warm cream surface.
Fonts: Noto Serif (headlines) + Plus Jakarta Sans (body) with Arabic fallbacks via google_fonts CDN.
Stitch project: "Shattab: Egyptian Finishing Platform" (id `224640672337163847`)
Design tokens: `docs/design-tokens.md`, theme code: `lib/core/theme/`

---

## Milestone status

### M1 Foundation — ✅ DONE (2026-05-15)
Auth (phone OTP), onboarding flows for both roles, role-aware routing, core theme/widgets.

### M2 Customer Core — ✅ DONE (2026-05-16)
**Homeowner:** discover contractors, filter by specialty/city, view profiles, send direct request (brief), create public post, my posts/requests screen, saved contractors tab.
**Contractor:** "فرص شغل" tab — lists open public posts matched by specialty ∩ service_area with WhatsApp/Call CTA.
**Contact:** all contact via WhatsApp/Call deep links (no in-app chat).
**DB:** `briefs` table + `saved_contractors` + `brief-photos` storage bucket (migration `0004`).

### M3 Contractor Core — ✅ DONE (2026-06-25, code-complete) — see `docs/m3-completion.md`
Quotes (send/receive/accept/decline), contractor inbox (Tab 2), portfolio management (Tab 3), homeowner quote views, flutter_animate motion + shimmer skeletons. Migration `0005_quotes` applied live on Supabase `ajqdutehxpbbflzdovhw` (2026-06-25, via MCP).
### M4 Comm & Polish — see `AI_ONBOARDING.md`, this line is stale
Reviews, monetization, verification, moderation and a social feed shipped
after this file was last updated. Push notifications and realtime shipped
2026-08-07 (see `AI_ONBOARDING.md` §11). In-app chat remains explicitly out
of scope — that part of the old M4 line is still correct.

---

## M3 Design — what to build next

### Overview
Replace two "coming soon" placeholder tabs in the contractor shell + add homeowner-side quote view.

### 1. DB migration `0005_quotes`
New table:
```sql
create table quotes (
  id uuid primary key default gen_random_uuid(),
  brief_id uuid not null references briefs(id) on delete cascade,
  contractor_id uuid not null references profiles(id),
  price_min int4,         -- EGP, optional
  price_max int4,         -- EGP, optional (set equal to min for fixed price)
  duration_text text,     -- e.g. "أسبوعين", "شهر"
  note text not null,
  status text not null default 'sent',  -- sent | accepted | declined | withdrawn
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(brief_id, contractor_id)       -- one quote per contractor per brief
);

-- trigger (reuse existing tg_set_updated_at pattern)
create trigger set_updated_at before update on quotes
  for each row execute function tg_set_updated_at();

-- indexes
create index on quotes(brief_id);
create index on quotes(contractor_id);

-- RLS
alter table quotes enable row level security;
-- contractor: own rows
create policy "contractor_own" on quotes
  using (contractor_id = auth.uid())
  with check (contractor_id = auth.uid());
-- homeowner: read quotes on their briefs; update status only
create policy "homeowner_read" on quotes for select
  using (exists (select 1 from briefs b where b.id = brief_id and b.homeowner_id = auth.uid()));
create policy "homeowner_status" on quotes for update
  using (exists (select 1 from briefs b where b.id = brief_id and b.homeowner_id = auth.uid()))
  with check (status in ('accepted','declined'));
```

### 2. Inbox tab (contractor) — Tab 2
`lib/features/inbox/`
- `domain/received_request.dart` — join of brief + my quote status
- `data/inbox_repository.dart` — query: `briefs` where `target_contractor_id = me`, with left-join quotes
- `presentation/inbox_screen.dart` — list with status badges (no quote / sent / accepted / declined)
- `presentation/request_detail_screen.dart` — full brief, photos, **[Send quote]** bottom sheet + WhatsApp/Call shortcuts
- `presentation/quote_sheet.dart` — BottomSheet: price_min/max (optional EGP fields), duration, note (required); submit → insert quote; if quote exists → prefill → update
- Wire in `app_router.dart`: replace PlaceholderScreen at `Routes.contractorInbox`

### 3. Quotes on public posts (contractor)
In existing `lib/features/briefs/presentation/contractor/post_detail_screen.dart`:
- Add **[أرسل عرض سعر]** button → same `QuoteSheet` bottom sheet
- Show "عرضك الحالي" card if quote already sent

### 4. Quotes received (homeowner)
In existing `lib/features/briefs/presentation/homeowner/brief_detail_screen.dart`:
- New section "عروض الأسعار" below brief info
- Quote cards: contractor logo + name (tappable → profile), price range, duration, note
- Actions: **[قبول] / [رفض]** buttons + WhatsApp/Call CTA
- Accept → update quote status to `accepted` (via homeowner_status RLS policy)

### 5. Portfolio management (contractor) — Tab 3
`lib/features/portfolio/presentation/` — contractor-facing screens:
- `my_portfolio_screen.dart` — grid of contractor's own projects, FAB [+ أضف عمل], tap → edit, long-press → delete (confirm dialog)
- `project_editor_screen.dart` — form: title, category, year, location, description + PhotoPicker (multi-photo), pick cover photo; reuses `PortfolioRepository`
- Add `update()` method to `PortfolioRepository` (already has `create`, `delete`, `uploadPhoto`, `fetch*`)
- Wire in `app_router.dart`: replace PlaceholderScreen at `Routes.contractorPortfolio` with `MyPortfolioScreen`
- Homeowner-facing gallery (PortfolioGalleryScreen) and project detail already wired — do NOT change

### 6. Motion & polish (flutter_animate)
Add `flutter_animate: ^4.x` to pubspec.yaml
- Staggered fade-slide list entrances on Inbox, Portfolio grid, Quotes section
- Shimmer skeletons instead of plain BatshLoading spinners
- Hero transition: portfolio cover photo gallery → detail
- Animated success checkmark on quote-sent confirmation
- Scale-tap feedback on cards (`.animate().scale()`)
- All via existing BatshColors tokens — no raw hex

---

## Files to know

| Path | What |
|------|------|
| `lib/core/router/app_router.dart` | All routes wired here; contractor tabs at bottom |
| `lib/core/router/routes.dart` | Route path constants |
| `lib/core/l10n/strings.dart` | All Arabic/English copy |
| `lib/core/theme/` | BatshColors, BatshTypography, BatshSpacing, BatshRadius, BatshShadows |
| `lib/core/widgets/` | BatshScaffold, BatshCard, BatshEmptyState, BatshLoading, BatshError, PhotoPicker, PhotoGallery, WhatsAppButton, CallButton |
| `lib/features/shell/presentation/contractor_shell.dart` | Bottom nav (4 tabs) |
| `lib/features/briefs/domain/brief.dart` | Brief domain model — status: open \| cancelled |
| `lib/features/portfolio/data/portfolio_repository.dart` | Already has create/delete/upload/fetch — add update() |
| `lib/features/portfolio/presentation/portfolio_gallery_screen.dart` | Homeowner read-only view — DO NOT change |
| `docs/specs/2026-05-14-m1-foundation-design.md` | M1 full spec |
| `docs/specs/2026-05-16-m2-customer-core-design.md` | M2 full spec |
| `docs/m2-completion.md` | M2 completion + DB changes |
| `SESSION_HANDOFF.md` | Original brainstorm / decisions |

---

## Supabase
- Project ref: `ajqdutehxpbbflzdovhw`
- URL + anon key in `.env` (never committed — see `.env.example`)
- Existing migrations on disk: `0001_init_profiles`, `0002_storage_buckets`
- Migrations `0003_contractors` + `0004_briefs_and_saved` were applied live but NOT on disk — don't re-run
- Next migration to write: `0005_quotes` (schema above)
- **Pending user action:** Enable Phone provider in Supabase dashboard before OTP works end-to-end

## Auth note
Admin invites employees = N/A for Shattab. Role chosen at signup (homeowner vs contractor), no self-service invite system.

---

## What NOT to do
- Don't add `riverpod_lint` or `custom_lint` (breaks freezed_annotation ^3.x)
- Don't use `flutter_animate` GSAP-style for web — this is Flutter mobile; use `flutter_animate` package
- Don't commit `.env`
- Don't change homeowner-facing portfolio screens
- Don't re-run migrations 0003/0004 on Supabase
- Don't add in-app chat (WhatsApp/Call only — the one M4 restriction still in force)
- Reviews, push notifications and realtime are already built — see `AI_ONBOARDING.md`
