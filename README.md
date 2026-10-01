# شطب (Shattab)

Shattab is an Arabic-first marketplace that helps Egyptian homeowners find renovation professionals, publish work briefs, compare quotes, and coordinate directly by phone or WhatsApp.

> **Start here:** [docs/AGENT_HANDOFF.md](docs/AGENT_HANDOFF.md) is the maintained GitHub guide to the architecture, local setup, CI commands, current source snapshot, and database/release limits. For the detailed engineering map, see [AI_ONBOARDING.md](AI_ONBOARDING.md).

## Product rules

- The consumer app has two roles: homeowner and contractor.
- Arabic is the primary language and the app uses RTL layouts.
- There is no user-to-user chat. Contact uses phone and WhatsApp handoffs.
- Database authorization belongs in Supabase RLS and reviewed server-side RPCs; client routing is not an authorization boundary.
- The intended authentication policy is unresolved. The current source offers phone/password, Google, and conditional Apple sign-in, with SMS OTP in confirmation, recovery, and the guest write-action flow.

## Repository

- Flutter app: `lib/`
- Supabase Edge Functions and migrations: `supabase/`
- Next.js operator console: `admin/`
- Cloudflare R2 media signer source: `infra/media-signer/`
- Current source branch: `feat/bottom-nav-redesign`

The checked-out snapshot includes work in progress. Its presence in source does not mean each feature, migration, admin surface, or media path is release-ready. The guide records what was and was not verified for this handoff.
