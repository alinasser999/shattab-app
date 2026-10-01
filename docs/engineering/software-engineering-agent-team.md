# Software Engineering Agent Team

The repository now has a reusable five-role engineering team. The operational
manifest is [`.agents/teams/software-engineering/team.yaml`](../../.agents/teams/software-engineering/team.yaml), the full operating contract is
[`TEAM.md`](../../.agents/teams/software-engineering/TEAM.md), and the role
prompts live beside it in `roles/`.

## Team sequence

1. **System Architect / Planner** — turns a request into a scoped technical
   specification and file plan; does not write code.
2. **Coder / Implementer** — implements the approved production change; does
   not own review or broad test authoring.
3. **Code Reviewer / Security Auditor** — reviews the diff for correctness,
   performance, authorization, data exposure, and vulnerabilities; never edits.
4. **QA & Test Runner** — writes and runs the relevant tests, recording exact
   evidence; does not fix production logic.
5. **DevOps & Release Agent** — manages dependencies, build/CI/infrastructure,
   environment templates, and release gates without handling secret values.

## Conditional pre-planning specialists

These specialists are optional, additive checks. The parent activates only the
ones whose criteria match, runs them before System Architect / Planner, and
waits for every active handoff before planning. The order is Product /
Acceptance, Supabase Schema & RLS, then UX / Arabic RTL / Accessibility. A task
with no matching trigger records that no specialist was activated and follows
the unchanged five-role sequence above.

- **Product / Acceptance Analyst** (`product-acceptance-analyst`) runs for
  product behavior, user-visible workflows, role semantics, business rules,
  acceptance criteria, or unresolved product ambiguity. It writes only the
  product acceptance artifact and blocks on missing or contradictory product
  decisions.
- **Supabase Schema & RLS Agent** (`supabase-schema-rls`) runs for tables,
  migrations, SQL/RPCs, auth, storage, RLS, or data boundaries. It writes only
  the schema/RLS artifact, keeps disk and live-project evidence separate, and
  blocks when required live or authorization evidence is unavailable. It never
  applies migrations or policies.
- **UX / Arabic RTL / Accessibility Agent** (`ux-rtl-accessibility`) runs for
  Flutter/admin UI, copy, navigation, forms, loading/error/empty states,
  responsive layout, motion, or design-system usage. It writes only the UX
  artifact and blocks when the surface, copy, or UX behavior cannot be verified.

Each specialist has one responsibility, an artifact-only write boundary, and a
ready/blocked disposition. Their artifacts advise the planner; they do not
replace the core planner, implementation, review, QA, or release stages.

## How a task moves through the team

The parent orchestrator creates `artifacts/agent-team/<task-id>/` and records the
request in `00-request.md`. Each role writes one handoff artifact:

```text
01-architecture.md -> 02-implementation.md -> 03-review.md -> 04-qa.md -> 05-release.md
```

The next role starts only after the previous handoff is ready. A blocking review,
failed QA run, or failed release gate stops the pipeline. Any behavior-affecting
change made after review returns through review and QA before release.

In Codex, the parent can instantiate each role with the native
`multi_agent_v1__spawn_agent` tool and the corresponding prompt file. The role
sessions are per-task; this repository definition is the durable team.
