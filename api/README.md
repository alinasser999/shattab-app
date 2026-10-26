# Shattab API foundation — local only, NOT DEPLOYED

This package is a local-only Node.js service skeleton for the future Shattab
backend. It currently exposes liveness and readiness checks and verifies a
PostgreSQL connection before opening its HTTP listener. It has no Shattab
feature routes and is not connected to the mobile app, admin console, Supabase,
an identity provider, object storage, or push notifications. It is not deployed
and is not production-ready.

## Requirements

- Node.js `>=24.22.1 <25` (the pinned container image uses the official
  `24.22.1-bookworm-slim` image digest). The package engine declaration and
  lockfile metadata use the same minimum patch release.
- npm, included with Node.js.
- A reachable, private PostgreSQL database and a password file readable by the
  Node process. This repository does not create the database, role, or secret.

Do not use the PostgreSQL stage administrator, a database owner/migrator, or a
Supabase `service_role` credential for the API. A dedicated least-privilege
application role has not yet been provisioned. The API performs only a constant
`SELECT 1` probe; it does not query Shattab tables, establish end-user identity,
or preserve/test the existing Supabase RLS behavior.

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

The container image runs as the non-root `node` user. The PostgreSQL 18 stage
Compose configuration declares a separate file-backed `api_password` mount,
but the file has not been created and no container has been started. On Linux,
file-backed Compose secrets use bind mounts: Compose does not remap host
ownership or mode from `uid`, `gid`, or `mode` options. The staging runbook
therefore requires the actual host file to remain protected by its parent
directory and to be readable by the pinned image's actual `node` UID/GID. It
also requires checking the live mount metadata for read-only status and testing
readability as the non-root process without printing file contents.

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
`infra/postgres18-stage/compose.yaml` is local/planned staging configuration;
it has not been copied to Oracle, built, or run there.

The planned integration lives only in `infra/postgres18-stage/compose.yaml`.
Its API joins the existing internal `db_internal` network, waits for the
PostgreSQL healthcheck, and runs with bounded resources, a read-only root
filesystem, no Linux capabilities, and no host port mapping. The endpoint binds
to `0.0.0.0` only inside that private container network; this does not publish
port 3000 on the VPS. The API remains health-only and its only database query
is still `SELECT 1`.

The local Docker Engine was unavailable during the task audit at
`npipe:////./pipe/dockerDesktopLinuxEngine` (`The system cannot find the file
specified.`). The Oracle PostgreSQL 18.6 staging database was observed stopped
and its current catalog/grants remain unknown. No API role or API secret has
been created, no API image has been built, and no stage service has been
started. The API role is not an application-data role and this wiring does not
replace Supabase or make Shattab deployable end to end. Use the approval-gated
staging runbook in `infra/postgres18-stage/README.md` only after its local
review and the user's explicit approval.

This is a local foundation only; it is **NOT DEPLOYED** and does not replace
Supabase or make Shattab deployable end to end.
