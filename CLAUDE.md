# Shattab — Coding Agent Context

> **Current starting point:** read [docs/AGENT_HANDOFF.md](docs/AGENT_HANDOFF.md), then [AI_ONBOARDING.md](AI_ONBOARDING.md). Older milestone and OTP-only statements elsewhere in this file were stale and have been removed.

## Repository rules

- Preserve the user's current working tree. Do not reset, clean, or overwrite unrelated edits.
- Read `AGENTS.md` and the engineering team guide before a concrete code change. Follow the task's named file boundary and handoff sequence.
- Keep Shattab Arabic-first and RTL. Add user-facing strings to `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`; follow shared routing, theme, and widget conventions.
- Keep exactly two consumer roles: homeowner and contractor. Do not add user-to-user chat.
- Treat client-side guards as navigation only. Enforce authorization in Supabase RLS and server-side RPCs.
- Do not claim local SQL is live. The prior read-only audit in the handoff is dated and was not refreshed for this snapshot.
- Never print or commit `.env`, local admin environment values, credentials, signing material, or service-role secrets.

## Current source facts

The current Flutter auth source offers phone/password, Google, and conditional Apple sign-in; SMS OTP remains in signup confirmation, password recovery, and the guest write-action flow. Older product guidance called the app OTP-only. The intended auth policy is unresolved, so describe the mismatch and leave the product choice open.

The source branch for this snapshot is `feat/bottom-nav-redesign`. Active work spans Flutter, the admin console, Supabase functions and migrations, tests, docs, and assets. This source presence does not mean those changes are release-ready. For exact status and validation limits, use the canonical handoff.
