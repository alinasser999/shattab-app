# ADR 0002: Generate Riverpod and Serialization Code During CI

Date: 2026-08-03
Status: accepted

## Context

The Dart source uses Riverpod, router and serialization generators. Generated
`.g.dart` files exist in local worktrees but are intentionally ignored by the
repository, so a clean checkout cannot analyze or build unless generation is
performed first.

## Decision

CI runs `dart run build_runner build` after dependency installation and before
formatting, analysis, tests and release build verification. Local setup keeps
the same command in the runbook.

## Consequences

- Generator and analyzer version changes are visible in CI rather than being
  hidden behind a developer's ignored local outputs.
- A clean checkout remains reproducible without committing generated files.
- Generator output drift is still a concern and must be reviewed when
  `pubspec.lock` or generator packages change.

