# Shattab engineering agent team

This repository uses the reusable team definition in
`.agents/teams/software-engineering/`. Read its `TEAM.md` before coordinating a
feature, refactor, security fix, test change, or release task.

## Repository guardrails

- Treat the existing working tree as user-owned. Preserve unrelated changes;
  never reset, clean, or check out over them.
- Read `AI_ONBOARDING.md` for the maintained product and architecture map
  before changing application code.
- Keep secrets local. Never print, commit, or copy values from `.env`, CI
  secrets, signing files, or service-role credentials. Use `.env.example` for
  documented placeholders only.
- Preserve Shattab product rules: Arabic-first/RTL, no in-app chat, and the
  existing design-system, routing, Supabase RLS, and release gates.

## Team entry point

For a concrete task, the parent orchestrator creates a task brief under
`artifacts/agent-team/<task-id>/`, then activates the roles in the sequence
defined by `.agents/teams/software-engineering/team.yaml`:

1. System Architect / Planner
2. Coder / Implementer
3. Code Reviewer / Security Auditor
4. QA & Test Runner
5. DevOps & Release Agent

Each role owns one responsibility and hands off a named artifact. The parent
orchestrator is responsible for sequencing, resolving blockers, and the final
user-facing result; it does not bypass a failed review, QA run, or release gate.

## Conditional pre-planning specialists

Before System Architect / Planner, the parent evaluates the task against the
three additive specialists in this order:

1. `product-acceptance-analyst` for product behavior, user-visible workflows,
   role semantics, business rules, acceptance criteria, or unresolved product
   ambiguity.
2. `supabase-schema-rls` for database tables, migrations, SQL/RPCs, auth,
   storage buckets or policies, RLS, or data access boundaries. Its handoff must
   separate local disk evidence from live Supabase evidence.
3. `ux-rtl-accessibility` for Flutter/admin UI, user-facing copy, navigation,
   forms, loading/error/empty states, responsive layout, motion, or design-system
   usage.

Only matching specialists are activated. Every active specialist writes only its
own task-local artifact and must produce a ready handoff before planning; a
missing required decision, live authorization evidence, or verifiable UX
contract blocks the affected scope. If none match, the parent records that
decision and uses the unchanged five-role default sequence above. Specialists
are additive and never replace the planner, implementer, reviewer, QA, or
release role.
