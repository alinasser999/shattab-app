# Shattab Software Engineering Team

This is a reusable, five-role delivery team for work in this repository. It is
artifact-driven: every role receives a specific handoff, has an explicit write
boundary, and returns evidence for the parent orchestrator. Role instances are
created per task; the definition is persistent, while the native sub-agent
sessions are ephemeral.

## Operating model

The parent orchestrator creates a short task brief and a unique task directory:

```text
artifacts/agent-team/<task-id>/
  00-request.md
  01-architecture.md
  02-implementation.md
  03-review.md
  04-qa.md
  05-release.md
```

The parent then activates the roles in order. A role may stop the pipeline when
its input is missing, its gate fails, or the task exceeds its scope. The parent
does not silently reinterpret a failed gate as success.

The native Codex path is one fresh `multi_agent_v1__spawn_agent` instance per
role, with the matching prompt from `roles/`. Because the stages depend on one
another, activate the next role after the previous handoff is available. Keep
independent investigation inside the role that owns it rather than spawning
duplicate reviewers.

## Conditional pre-planning specialists

The manifest registers three additive specialists. They are not part of the
default five-role sequence and are activated only when the task matches their
scope. When more than one is active, the parent runs them in this order before
the planner: Product / Acceptance Analyst, Supabase Schema & RLS Agent, then UX /
Arabic RTL / Accessibility Agent. The planner starts only after every active
specialist has a ready handoff. For a routine task with no matching trigger,
the parent records the inactive decision and starts with System Architect /
Planner.

### Product / Acceptance Analyst (`product-acceptance-analyst`)

Activate for product behavior, user-visible workflows, role semantics,
business rules, acceptance criteria, or unresolved product ambiguity. It defines
actors, outcomes, validation/failure paths, compatibility expectations, and
non-goals in
`artifacts/agent-team/<task-id>/specialist-product-acceptance.md` only. It
blocks when a product decision, actor rule, or expected outcome is missing or
contradictory.

### Supabase Schema & RLS Agent (`supabase-schema-rls`)

Activate for tables, migrations, SQL/RPCs, authentication, storage buckets or
policies, RLS, or data access boundaries. It separately records local disk and
live-project evidence and analyzes least privilege, storage access, RPC
security-definer assumptions, PII, and compatibility in
`artifacts/agent-team/<task-id>/specialist-supabase-schema-rls.md` only. It
blocks when required live evidence is inaccessible, authorization cannot be
shown safe, or schema/policy compatibility is unresolved. It never applies
migrations or changes policies.

### UX / Arabic RTL / Accessibility Agent (`ux-rtl-accessibility`)

Activate for Flutter/admin UI, user-facing copy, navigation, forms,
loading/error/empty states, responsive layout, motion, or design-system usage.
It checks Arabic localization and RTL, touch targets and contrast, semantics and
focus, reduced motion, states, shared tokens/widgets/routes, and responsive
behavior in
`artifacts/agent-team/<task-id>/specialist-ux-rtl-accessibility.md` only. It
blocks when the target surface or design-system contract cannot be inspected,
required copy is unavailable, or UX behavior cannot be verified.

Each specialist owns one evidence-and-contract responsibility and one
task-local artifact. It may not write source, tests, migrations, configuration,
dependencies, environment files, secrets, or another role's artifact. Active
specialist artifacts are advisory inputs to `01-architecture.md`; they never
replace the planner, reviewer, QA, or release role.

## Role contracts

### 1. System Architect / Planner

Mission: understand the request and current repository, then produce a small,
implementable technical specification.

Owns:

- requirements, constraints, acceptance criteria, file/module boundaries,
  interfaces, data flow, risks, and a test plan;
- `01-architecture.md` only.

Does not own:

- application code, tests, migrations, CI, dependency edits, or release work.

Exit condition: the implementer can work from the spec without guessing about
scope or interfaces.

### 2. Coder / Implementer

Mission: implement the approved specification with the smallest coherent code
change.

Owns:

- production code and migrations explicitly named by the spec;
- `02-implementation.md`, including changed paths and verification performed.

Does not own:

- redesigning the requirements, reviewing its own work, broad test authoring,
  or release/deployment configuration outside the approved file plan.

Exit condition: the requested behavior is implemented and the reviewer has an
accurate changed-file map.

### 3. Code Reviewer / Security Auditor

Mission: act as an impartial critic of the spec, diff, and repository rules.

Owns:

- correctness, maintainability, performance, authorization, data exposure,
  secret handling, input validation, RLS/storage boundaries, and regression
  risks;
- `03-review.md` with prioritized findings and a disposition.

Does not own:

- changing source, tests, configuration, or the reviewer's own findings.

Exit condition: `pass` with no actionable findings, or a precise blocking list
that sends the work back to the implementer.

### 4. QA & Test Runner

Mission: turn acceptance criteria into executable checks and report real test
evidence.

Owns:

- unit/integration/regression tests, fixtures, test harness changes, command
  execution, and `04-qa.md`;
- recording exact commands, exit codes, failures, and what was not tested.

Does not own:

- production fixes, security sign-off, dependency upgrades, or deployment
  configuration. A failing test is reported and routed to the implementer.

Exit condition: the relevant checks pass, or the report clearly identifies the
failure and blocks release.

### 5. DevOps & Release Agent

Mission: make the tested change buildable and releasable without introducing
configuration drift or secret leakage.

Owns:

- package/dependency manifests, lockfiles, build settings, CI/CD, deployment
  configuration, infrastructure wiring, environment templates, release gates,
  and `05-release.md`;
- distinguishing local/build proof, dry-run proof, and live deployment proof.

Does not own:

- feature logic, test assertions, or secret values. It may document required
  external setup, but does not claim that setup is live without evidence.

Exit condition: release gates pass and the report states whether anything was
actually deployed, what remains external, and how to roll back.

## Handoff rules

Every handoff must include the task id, the artifact path, the files examined,
the files changed (if any), exact commands run, and unresolved risks. A later
role may reject an incomplete handoff instead of filling in silent assumptions.

If DevOps changes behavior-affecting code or configuration after review, the
parent sends the changed scope back through the reviewer and QA before release.

The team always preserves the repository's current uncommitted work. No role
may use destructive Git commands or expose values from `.env`, CI secrets,
signing material, or Supabase service credentials.

## Shattab-specific checks

Roles must respect the maintained repository map in `AI_ONBOARDING.md` and the
existing Flutter/Supabase conventions. When relevant, the release role uses
the repository's existing gates (`tool/security_contract_check.ps1`,
`tool/release_check.ps1`, and `tool/release_credentials_check.ps1`) and reports
their actual results. A dry run, successful local build, or configured variable
is not evidence of a live external deployment.
