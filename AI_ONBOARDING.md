# Shattab — Maintained Engineering Map

Use this guide for a repository map before implementation. The [GitHub agent handoff](docs/AGENT_HANDOFF.md) is the concise starting point for a new reader and records this snapshot's setup, CI commands, database evidence, and verification limits.

This checkout is on `feat/bottom-nav-redesign`. The source and working tree contain active changes; this guide does not certify them as released or ready to ship. No tests, builds, app runtime checks, or database migrations were run for the combined snapshot described by this handoff.

## Product and authorization invariants

Shattab is an Arabic-first, RTL marketplace for Egyptian home renovation. The app has two user roles: homeowner and contractor. The contractor identity catalog contains provider kinds, but those are not additional account roles. The separate operator console has its own admin authorization model.

- There is no user-to-user chat. Homeowners and contractors coordinate through phone or WhatsApp handoffs.
- Client routes and role guards provide navigation behavior, not data authorization. Supabase RLS and reviewed server-side RPCs must enforce data access and privileged transitions.
- A newly authenticated user selects a role in the first onboarding step; the server-side role-selection RPC locks that choice. Do not describe it as necessarily chosen at account creation.
- **Authentication policy is unresolved.** The current login source offers Egyptian phone/password sign-in and sign-up, Google, and Apple on supported Apple platforms. SMS OTP is still used for phone sign-up confirmation, password recovery, and the guest write-action gate. Older OTP-only product text does not match the current source. Do not choose a new product policy as a documentation edit.
- Keep `.env`, admin local environment files, credentials, and signing material local. Never print or commit their values.

## Technology and source map

| Area | Source |
|---|---|
| Flutter entry and app setup | `lib/main.dart`, `lib/app.dart` |
| Shared app infrastructure | `lib/core/`: environment, routing and role guards, Supabase providers, localization, theme, analytics, media, cache, notifications, shared widgets, and utilities |
| Localized copy | `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`; generated `AppLocalizations` classes live in `lib/l10n/`. Locale state and the BuildContext extension are in `lib/core/l10n/`. Do not add new UI strings to the old `strings.dart` catalog. |
| Flutter features | `lib/features/`: auth, onboarding, shell/home, discovery, explore, briefs, inbox, quotes, portfolio, profile, saved items, reviews, billing, verification, moderation, notifications, and assistant |
| Supabase server code | `supabase/functions/`: shared function helpers, `assistant-chat`, and `send-push` |
| Database source | `supabase/migrations/` and `supabase/tests/`; local SQL is source, not proof of live application |
| Operator console | `admin/`: Next.js 16.3.1 App Router, API routes, users, contractors, moderation, payments, and activity |
| Public-media signer | `infra/media-signer/`: Cloudflare Worker source for Supabase-token-verified R2 presigning; its README records external setup requirements |

Feature code is generally organized into data, domain, and presentation layers. Reuse route constants from `lib/core/router/routes.dart`, shared theme tokens and widgets, and repository patterns for data access.

The operator console is separate from the consumer roles. Its checked-in README describes an anon-key client, database-enforced `is_admin()` access, and audited privileged RPCs; do not introduce a service-role key into a client.

## Domain notes from checked-in source

- Homeowners publish renovation briefs and can receive contractor quotes; contractors browse matching opportunities, respond to direct requests, manage work portfolios, and quote briefs.
- The feed in `lib/features/explore/` is distinct from work briefs.
- `ProviderKind` includes `specialized_provider`; its database check must be reconciled with the migration history before any live schema action.
- The local pricing source, `lib/features/billing/pricing.dart`, describes a limit of five quotes in a rolling 30-day window for free contractors. Treat local code as the source for current implementation details and verify it before changing product claims.
- Contact and payment flows can expose personal or financial information. Keep those decisions and authorization checks server-side.

## Localization and design

Arabic is the source language, RTL is the default experience, and English is also represented in ARB files. Add user-facing copy to the ARBs and regenerate through the Flutter localization workflow. Keep design changes on the shared tokens and components in `lib/core/theme/` and `lib/core/widgets/`.

## Working tree and evidence limits

The current branch snapshot includes in-flight work across Flutter auth/onboarding, home and discovery, brief and quote flows, navigation and shared UI, billing, media, assistant, localization, the admin console, Edge Function source, migrations, tests, docs, and assets. Treat those areas as work in progress until the relevant review, QA, runtime, and release gates have passed.

The exact local migration additions and the previous read-only Supabase audit are summarized in [docs/AGENT_HANDOFF.md](docs/AGENT_HANDOFF.md). That audit is dated prior evidence; no live state was refreshed for this documentation handoff. Do not infer live schema, RLS, function, storage, or deployment state from file presence.

## Further reading

- [Canonical agent handoff](docs/AGENT_HANDOFF.md)
- [Admin console setup and security boundaries](admin/README.md)
- [Media signer setup and limitations](infra/media-signer/README.md)
- [Shipping guide](docs/SHIPPING.md)
- [Go-live checklist](docs/go-live-checklist.md) — review its scope and date before relying on operational statements
