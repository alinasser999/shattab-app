# Shattab Scaling Roadmap

The phrase "one million users" is not a capacity result. Capacity depends on
registered users, monthly and daily active users, concurrent sessions, requests
per second, database transactions per second, upload volume and bandwidth.

## Current Stage

- Modular Flutter client with Supabase Auth/Postgres/Storage.
- Feature-level repositories and bounded reads in several domains.
- Keyset migrations exist for feed/opportunity-style collections.
- No safe staging load-test result is recorded in this repository.

## Measure Before Scaling

Track for each important journey:

- p50, p95 and p99 latency.
- Error and timeout rate.
- Database CPU, connections, locks and slow queries.
- Storage egress and image payload size.
- Realtime connection count and event rate.
- App startup and screen rendering time.

## Triggers and Actions

| Trigger | First response |
| --- | --- |
| Repeated unbounded/list-cap hits | Finish cursor pagination and expose a load-more contract |
| p95 read latency rises with stable query plans | Add evidence-backed indexes or a repository cache |
| Image egress dominates cost | Add resized variants, upload limits and CDN/cache policy |
| Notification fan-out affects request latency | Move it to an idempotent background job |
| Search scans become slow | Add Postgres search/indexing before considering a separate service |
| Database connections saturate | Tune pooling/query lifetimes and reduce duplicate requests |
| One feature needs independent deployment or isolation | Write an extraction ADR before creating a service |
| Recovery objective cannot be met | Test restore/PITR and formalize incident ownership |

## Load-Test Assumptions To Record

Before claiming readiness for a larger user population, record:

- registered-user count and active-user percentage;
- peak concurrent sessions;
- requests per session and read/write ratio;
- average and p95 payload size;
- upload objects per active user;
- realtime subscriptions per session;
- safe tested throughput and observed failure point.

Only load-test a staging or explicitly approved test environment. The current
repository has no evidence to claim one million concurrent users.

