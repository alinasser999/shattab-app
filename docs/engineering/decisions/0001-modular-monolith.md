# ADR 0001: Keep A Feature-Oriented Modular Monolith

Date: 2026-08-03
Status: accepted

## Context

Shattab is a Flutter client backed by one Supabase project. The repository has
feature folders, Riverpod providers, repositories and versioned migrations,
but it does not have measured traffic or independent deployment requirements
that justify multiple services.

## Decision

Keep one application and one Supabase project with explicit feature boundaries.
Use repositories and providers as extraction seams. Enforce ownership in RLS or
trusted RPCs. Add external infrastructure only after a measured bottleneck,
clear data ownership and an operational owner exist.

## Alternatives Considered

- Microservices now: rejected because it adds deployment, tracing, data
  consistency and on-call cost without evidence of independent scaling needs.
- A generic repository/service framework: rejected because it would hide
  feature-specific query and authorization rules behind abstractions with no
  second implementation.
- One giant featureless app folder: rejected because current feature boundaries
  already provide useful ownership and test seams.

## Consequences

- Refactors must stay incremental and keep route/provider contracts stable.
- Database and storage policies remain a first-class part of feature ownership.
- A future service can be extracted behind an existing repository boundary if a
  measured trigger is reached.

