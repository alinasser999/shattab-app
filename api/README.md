# Shattab API foundation — Oracle stage health service, NOT PRODUCTION

This package is a Node.js service skeleton for the future Shattab backend. As
verified on 2026-10-27, its health-only container is running on the Oracle
staging server on an internal Docker network. It exposes liveness and readiness
checks and verifies a PostgreSQL connection before opening its HTTP listener.
It has no Shattab feature routes and is not connected to the mobile app, admin
console, Supabase, an identity provider, object storage, or push notifications.
It is not a production deployment and is not production-ready.

## Requirements

- Node.js `>=24.22.1 <25` (the pinned container image uses the official
  `24.22.1-bookworm-slim` image digest). The package engine declaration and
  lockfile metadata use the same minimum patch release.
- npm, included with Node.js.
- A reachable, private PostgreSQL database and a password file readable by the
  Node process. This repository does not create the database, role, or secret.

Do not use the PostgreSQL stage administrator, a database owner/migrator, or a
Supabase `service_role` credential for the API. The Oracle stage has a distinct
least-privilege `shattab_api` login for the constant `SELECT 1` health probe;
it has no Shattab application-data grants and is not a production application
role. The API does not query Shattab tables, establish end-user identity, or
preserve/test the existing Supabase RLS behavior.

## Configuration

No `.env` file is loaded. Configure the following environment variables in the
process supervisor or deployment environment. The password must be supplied by
file only; it must never appear in an environment variable, command-line
argument, source file, or log.

| Setting | Required | Default / accepted values | Purpose |
| --- | --- | --- | --- |
| `HOST` | No | `127.0.0.1` or `0.0.0.0`; default `127.0.0.1` | HTTP bind address. Use `0.0.0.0` only inside a container network namespace. |
| `PORT` | No | Decimal integer `1`–`65535`; default `3000` | HTTP listener port. |
| `LOG_LEVEL` | No | `fatal`, `error`, `warn`, `info`, `debug`, `trace`, or `silent`; default `info` | Fastify/Pino log level. |
| `DATABASE_HOST` | Yes | Non-empty host without surrounding whitespace or control characters | PostgreSQL host on the private application network. |
| `DATABASE_PORT` | No | Decimal integer `1`–`65535`; default `5432` | PostgreSQL port. |
| `DATABASE_NAME` | Yes | Non-empty database name without surrounding whitespace or control characters | Database the API will connect to. |
| `DATABASE_USER` | Yes | Non-empty runtime role without surrounding whitespace or control characters | PostgreSQL role used by the API. It must be least-privilege. |
| `DATABASE_PASSWORD_FILE` | Yes | Non-empty filesystem path without surrounding whitespace or control characters | Path to the secret file containing the runtime-role password. The path is never logged. |
| `DATABASE_POOL_MAX` | No | Integer `1`–`8`; default `4` | Maximum connections in this API process's pool. Recalculate the total across every API replica and other database clients before scaling. |

`DATABASE_PASSWORD` and `DATABASE_URL` are rejected. Required host, database,
user, and password-file settings are validated before startup. The driver
receives each connection field explicitly, so it does not fall back to
`PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, or `PGPASSWORD`. `PGBINARY` and
`PGREPLICATION` are also rejected when set because node-postgres otherwise may
use them to change connection protocol behavior. The rejection message never
includes the configured value. The connection is configured without TLS for
the planned same-host private database network; if the database moves outside
that private network, add and verify explicit TLS configuration before
connecting.

### Password-file contract

The API checks that the configured path is a regular file before opening it.
On Linux it uses a nonblocking, no-follow open and verifies the opened file is
the same file inspected before the open. It accepts a non-empty UTF-8 password
up to 4 KiB, removes at most one final LF or CRLF line ending, and preserves
all other characters, including a leading UTF-8 BOM. Missing, non-regular,
unreadable, empty, invalid UTF-8, NUL-containing, or oversized files stop
startup. The API never logs the password, file path, or raw
filesystem/database errors.

The container image runs as the non-root `node` user. On 2026-10-27, the Oracle
stage secret was created at `/root/shattab-pg18-stage-tools/secrets/api_password`
with owner `root`, group `1000`, and mode `0440`; Compose mounts it at
`/run/secrets/api_password` as read-only. The API container was observed
`running` and `healthy`, both health endpoints returned HTTP `200`, and the
database showed one idle `shattab_api` session. The container has no published
host port. On Linux, file-backed Compose secrets use bind mounts: Compose does
not remap host ownership or mode from `uid`, `gid`, or `mode` options. The
staging runbook records the required host permissions and safe metadata checks;
never print the secret file contents.

## Startup and health checks

Startup validates configuration, reads the password file, creates the bounded
connection pool, and runs `SELECT 1` before opening the HTTP listener. If any of
those steps fails, the listener stays closed, acquired resources are closed,
and the process exits with a nonzero status using a sanitized error. The
database probe proves connectivity only; it says nothing about Shattab schema,
authorization, RLS, user data, or workflows.

| Request | Response | Meaning |
| --- | --- | --- |
| `GET /health/live` | `200` with `{"status":"ok"}` | The process can answer; PostgreSQL availability does not affect liveness. |
| `GET /health/ready` before readiness or during shutdown | `503` with `{"status":"not_ready"}` | Do not send application work to this process. |
| `GET /health/ready` when PostgreSQL answers `SELECT 1` | `200` with `{"status":"ready"}` | Lifecycle is ready and the database answered a fresh probe. |
| `GET /health/ready` when the database probe fails | `503` with `{"status":"not_ready"}` | The response and log contain no database error details. A later successful probe restores readiness. |

Each readiness request makes one small constant database probe. The client
`query_timeout` and PostgreSQL `statement_timeout` are both set to 2,000 ms so
the probe has a finite client-side and server-side execution bound. These
settings currently apply to the pool, whose only exposed query is the health
probe; review them before adding feature queries. During `SIGINT` or `SIGTERM`,
the API first marks itself unready, then Fastify drains in-flight HTTP work; its
close hook ends the pool afterward.

## Local package checks

From the `api/` directory, the checks that do not require a real PostgreSQL
connection are:

```powershell
npm run typecheck
npm test
npm run build
```

Running `npm run dev` or `npm start` now requires all required database settings
and a real password file. Do not put the password in a PowerShell command or
environment variable. The tests should use an injected fake health adapter and
temporary generated files rather than any cloud database or credential.

`npm run build` writes JavaScript under `dist/`. Passing local checks does not
prove a PostgreSQL connection, migration, deployment, production availability,
or release readiness for Shattab.

## Stage-only container and database verification

`api/compose.smoke.yaml` is an older API-only smoke definition. It has no
PostgreSQL service or password secret, and the API now correctly refuses to
listen without them. Its previous `up` and HTTP health-check commands are no
longer a valid smoke path; do not use them to claim the database-backed API is
healthy. The Dockerfile and package engine metadata were updated for the pinned
Node 24.22.1 runtime. The old smoke Compose file remains stale. The separate
`infra/postgres18-stage/compose.yaml` remains local/planned staging configuration;
it has not been copied to Oracle, built, or run there. A
protected, root-owned Compose snapshot derived from that checked-in source and
the ARM64 API image are currently running on Oracle stage; the exact host
checks and limits are recorded in `infra/postgres18-stage/README.md`.

The stage API joins the internal `db_internal` network, waits for the
PostgreSQL healthcheck, and runs with bounded resources, a read-only root
filesystem, no Linux capabilities, and no host port mapping. The endpoint binds
to `0.0.0.0` only inside that private container network; this does not publish
port 3000 on the VPS. The API remains health-only and its only database query
is still `SELECT 1`.

The stage health checks prove only that the process is alive and can run its
constant `SELECT 1` probe using the dedicated `shattab_api` role. They do not
prove business API behavior, user authentication, Shattab data authorization,
migrations, backups, public reachability, or production availability. The API
role is not an application-data role and this wiring does not replace Supabase
or make Shattab deployable end to end. See the approval-gated operational
details in `infra/postgres18-stage/README.md`.

This is an **internal Oracle stage health service only**; it does not replace
Supabase or make Shattab deployable end to end.
