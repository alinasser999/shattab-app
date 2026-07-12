# M3 — Contractor Core: Completion Notes

Status: code-complete (2026-06-25). Builds clean: `flutter pub get` + `dart run build_runner build` + `flutter analyze` => 0 code issues (only the expected git-ignored `.env` asset warning).

## What shipped

### 1. Quotes (new feature: `lib/features/quotes/`)
- `domain/quote.dart` — hand-written `Quote` model + `QuoteStatus` enum (sent | accepted | declined | withdrawn).
- `data/quotes_repository.dart` — fetchForBrief / fetchMine / fetchMineForBrief / submit (upsert, one per brief+contractor) / setStatus.
- `presentation/providers/quotes_providers.dart` — quotesForBrief, myQuoteForBrief, myQuotes + `QuotesController` (submit / setStatus with targeted invalidation).
- UI: `quote_sheet.dart` (price min/max + duration + note bottom sheet, animated success checkmark), `quote_format.dart` (intl price label), `widgets/quote_status_badge.dart`, `widgets/contractor_quote_cta.dart`, `widgets/quotes_received_section.dart`.

### 2. Inbox (new feature: `lib/features/inbox/`) — contractor Tab 2
- `domain/received_request.dart` (brief + my quote status join).
- `presentation/providers/inbox_providers.dart` (joins direct briefs with my quotes).
- `inbox_screen.dart` (status-badged list, shimmer skeleton loading, staggered entrance), `request_detail_screen.dart` (full brief + quote CTA + WhatsApp/Call).

### 3. Portfolio management — contractor Tab 3
- `PortfolioRepository.update()` added (mirrors create()).
- `presentation/providers/my_portfolio_providers.dart` — myPortfolio (own, by session id) + `PortfolioController` (save = create/update with photo upload, remove).
- `my_portfolio_screen.dart` (2-col cover grid, FAB add, tap edit, long-press delete confirm, grid skeleton loading, staggered entrance).
- `project_editor_screen.dart` (title/category/year/location/description form + multi-photo PhotoPicker; first photo = cover; hydrates on edit).

### 4. Quotes on existing screens
- Contractor `post_detail_screen.dart` — `ContractorQuoteCta` (send / view-current-quote) above contact buttons.
- Homeowner `brief_detail_screen.dart` — `QuotesReceivedSection` (accept/decline + contact when accepted) below brief info.

### 5. Motion & polish (flutter_animate ^4.5.0)
- Staggered fade+slide entrances: inbox list, portfolio grid, quotes-received list.
- `BatshShimmerBox` / `BatshGridSkeleton` / `BatshListSkeleton` (`lib/core/widgets/batsh_shimmer.dart`) replacing plain spinners on inbox + portfolio.
- Animated success checkmark on quote submit.
- Hero on portfolio cover -> detail was intentionally SKIPPED to honor the "do not change homeowner-facing portfolio screens" constraint.

### 6. Routing & strings
- `routes.dart`: `contractorRequestDetailPath`, `contractorPortfolioNew`, `contractorPortfolioEditPath`.
- `app_router.dart`: replaced both contractor "coming soon" placeholders; nested inbox `:id` and portfolio `new` / `:id/edit` routes.
- `strings.dart`: full M3 copy block (quotes / inbox / portfolio / common actions).

## DB
- Migration written on disk: `supabase/migrations/0005_quotes.sql` (quotes table + RLS: contractor_own, homeowner_read, homeowner_status).
- All migrations on disk: `0001_init_profiles`, `0002_storage_buckets`, `0003_contractors` (extended fields: cover_photo_url, headline, projects_completed, response_rate), `0004_briefs_and_saved`, `0005_quotes`.
- PENDING (external, needs Supabase credentials): apply `0003_contractors` + `0005_quotes` live on project `ajqdutehxpbbflzdovhw`. The app code references these columns and will fail on missing schema.
- Reminder still open from M2: enable the Phone auth provider in the Supabase dashboard.

## Toolchain note
- Flutter upgraded to 3.44.4 (Dart 3.12) earlier this session so the `^3.11.5` SDK constraint resolves. `flutter` binary lives at `C:\flutter\bin` (not on PATH by default in a fresh shell).