# Shattab Architecture

Date: 2026-08-03

## Decision

Keep Shattab as a feature-oriented modular monolith. Flutter owns presentation
and client state; Supabase owns authentication, Postgres data, storage and
trusted authorization policies. New infrastructure is introduced only when a
measured bottleneck justifies it.

## Dependency Direction

```text
presentation -> providers/controllers -> repository interface -> data source
       |                    |                    |
       +--> domain models --+                    +--> Supabase client
       +--> core widgets/theme/l10n              +--> storage/auth
```

Rules:

- Widgets do not construct Supabase queries or storage paths.
- Repositories do not import presentation widgets or localization contexts.
- Domain models do not depend on Supabase response types.
- Providers own async state, refresh and invalidation; widgets render states
  and emit user intent.
- Shared code belongs in `core` only when it has more than one real feature
  consumer and has no feature-specific business meaning.
- Authenticated ownership and role checks are enforced by RLS or trusted RPCs,
  not only by route guards or disabled buttons.

## Feature Boundary Contract

Each feature should converge on:

```text
feature/
  data/          Supabase DTO mapping and repository implementation
  domain/        entities, enums and pure business rules
  presentation/  screens, widgets and providers/controllers
```

Existing feature names remain stable. Splitting a large file must not create a
second state-management pattern or duplicate repository. Extract pure widgets
first, then move orchestration only when the provider boundary is explicit.

## Runtime Flow

1. `main.dart` loads public client configuration and initializes Supabase.
2. Auth state refreshes the Riverpod/go_router graph.
3. `roleGuard` selects the correct role shell and protects feature routes.
4. Feature providers call repositories, which map Supabase rows to domain
   models.
5. Presentation renders loading, success, empty, refreshing and recoverable
   error states.
6. Mutations are validated by the database and then invalidate the owning
   provider; optimistic state is used only where rollback is defined.

## Data and Scale Boundaries

- Every collection query has a bounded page size.
- Rapidly changing collections use keyset pagination with stable tie-breakers.
- Counts used for identity or quota come from database rollups/RPCs rather than
  downloading a whole table.
- Realtime subscriptions, when added, must be scoped to the current user or
  resource and disposed with the provider.
- Images are uploaded to user-owned paths and displayed through validated,
  optionally transformed URLs.
- A cache may be added behind a repository only with a documented key, TTL,
  invalidation rule and privacy boundary.

## Error Boundary

Repositories may throw infrastructure exceptions internally, but presentation
receives a safe application message through `ErrorMapper` and shared error
widgets. Technical context is logged through `AppLogger`; secrets, tokens and
personal fields are redacted before logging.

## What We Are Not Building Yet

- No microservices until independent deployment or scaling is demonstrated.
- No global realtime feed subscription.
- No speculative event bus or generic repository framework.
- No external cache before query latency/read volume justifies its operational
  cost.
- No load-test claim beyond the workload actually executed against a safe
  environment.

