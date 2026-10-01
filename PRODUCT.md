# Shattab (شطب) — Product Brief

> This is a product brief, not a release-status report. For the checked-in code map, current authentication behavior, CI commands, migration evidence, and verification limits, see the [maintained agent handoff](docs/AGENT_HANDOFF.md).

## Product purpose

Shattab connects Egyptian homeowners who need renovation or finishing work with contractors and other renovation professionals. Homeowners can discover profiles, publish work briefs, compare quotes, and review completed work. Contractors can find relevant opportunities, respond to direct requests, send quotes, and present portfolio work.

## Users and roles

- **Homeowner (طالب خدمة):** describes a home project, finds professionals, and reviews proposals.
- **Contractor (مقاول):** manages specialties and service areas, follows opportunities, sends quotes, and maintains a portfolio.

The consumer app has these two account roles. Operator-console access is separate and is enforced by the database.

## Product principles

- **Arabic-first and RTL:** Arabic is the primary product language; English is also supported in the app.
- **Trust and clarity:** explain contractor information, verification state, quotes, and payment status without implying more certainty than the evidence supports.
- **Contact without chat:** user-to-user messaging is not part of the product; contact uses phone and WhatsApp handoffs.
- **Database-enforced access:** Supabase RLS and server-side RPCs enforce data access and privileged transitions.

## Authentication status

The product policy needs a decision. The current Flutter login source offers phone/password sign-in and sign-up, Google, and Apple on supported Apple platforms. SMS OTP remains in signup confirmation, password recovery, and the guest write-action flow. Older text in this file described OTP-only access; it is historical and is not a reliable description of the current implementation. Do not change authentication behavior based on this note alone.

## Brand and interface direction

The in-flight brand direction is Shattab Full Brand Identity, including the Arabic roof-line mark, terracotta (`#9E3D18`), olive, gold, and warm cream. The checked-in Flutter fonts include bundled IBM Plex Sans Arabic and Tajawal. The implemented tokens and assets may be in progress; consult `design-system/`, `design-system/shattab/MASTER.md`, and `lib/core/theme/` before making visual claims.

Reference photography, sample people, and sample project-work images are concept assets unless separate evidence establishes identity, affiliation, ownership, or verification. Do not present a reference image as proof that a real contractor completed or verified the depicted work.

## Current implementation areas

The source tree contains Flutter areas for onboarding, role shells, home, discovery, briefs, quotes, inbox, portfolio, reviews, billing, verification, moderation, notifications, and the community feed; a separate Next.js operator console; Supabase functions and migrations; and Cloudflare media-signer source. Their inclusion in the working tree does not establish release readiness or live database/deployment state.

See [docs/AGENT_HANDOFF.md](docs/AGENT_HANDOFF.md) for the maintained architecture map, setup, current snapshot context, and database limitations.
