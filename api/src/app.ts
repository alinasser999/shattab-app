import Fastify, { type FastifyInstance, type FastifyRequest } from "fastify";
import type { Writable } from "node:stream";

import type { LogLevel } from "./config.js";
import type { DatabaseHealth } from "./database.js";

export interface AppLifecycle {
  markReady(): void;
  markDraining(): void;
  isReady(): boolean;
}

export interface ShattabApplication {
  readonly server: FastifyInstance;
  readonly lifecycle: AppLifecycle;
}

export interface CreateAppOptions {
  readonly database: DatabaseHealth;
  readonly logLevel?: LogLevel;
  readonly loggerStream?: Writable;
}

const REDACT_PATHS = [
  "req.headers.authorization",
  "req.headers.cookie",
  "req.headers.set-cookie",
  "req.headers.x-api-key",
  "req.headers.api-key",
  "req.headers.x-auth-token",
  "req.headers.x-access-token",
  "req.headers.x-refresh-token",
  "req.headers.x-id-token",
  "req.headers.access-token",
  "req.headers.refresh-token",
  "password",
  "phone",
  "token",
  "secret",
  "*.password",
  "*.phone",
  "*.token",
  "*.secret",
];

export function createApp(options: CreateAppOptions): ShattabApplication {
  let ready = false;
  let draining = false;
  const requestStartedAt = new WeakMap<FastifyRequest, bigint>();

  const server = Fastify({
    logController: new Fastify.LogController({ disableRequestLogging: true }),
    requestIdHeader: false,
    logger: {
      level: options.logLevel ?? "info",
      ...(options.loggerStream === undefined ? {} : { stream: options.loggerStream }),
      redact: {
        paths: REDACT_PATHS,
        censor: "[REDACTED]",
      },
      serializers: {
        req(request: FastifyRequest) {
          return {
            id: request.id,
            method: request.method,
            route: request.routeOptions.url ?? "unmatched",
          };
        },
        res(reply: { statusCode: number }) {
          return { statusCode: reply.statusCode };
        },
      },
    },
  });

  const lifecycle: AppLifecycle = {
    markReady() {
      if (!draining) ready = true;
    },
    markDraining() {
      draining = true;
      ready = false;
    },
    isReady() {
      return ready && !draining;
    },
  };

  server.addHook("onRequest", async (request) => {
    requestStartedAt.set(request, process.hrtime.bigint());
  });

  server.addHook("onResponse", async (request, reply) => {
    const startedAt = requestStartedAt.get(request);
    const durationMs = startedAt === undefined
      ? 0
      : Math.round(Number(process.hrtime.bigint() - startedAt) / 10_000) / 100;

    request.log.info({
      event: "request_completed",
      requestId: request.id,
      method: request.method,
      route: request.routeOptions.url ?? "unmatched",
      statusCode: reply.statusCode,
      durationMs,
    }, "Request completed");
  });

  server.setErrorHandler((error, request, reply) => {
    const candidateStatusCode = typeof error === "object" && error !== null && "statusCode" in error
      ? error.statusCode
      : undefined;
    const statusCode = typeof candidateStatusCode === "number" && candidateStatusCode >= 400 && candidateStatusCode < 600
      ? candidateStatusCode
      : 500;

    request.log.error({
      event: "request_failed",
      requestId: request.id,
      method: request.method,
      route: request.routeOptions.url ?? "unmatched",
      statusCode,
    }, "Request failed");
    reply.status(statusCode).send({ status: "error" });
  });

  server.setNotFoundHandler((_request, reply) => {
    reply.status(404).send({ status: "not_found" });
  });

  server.get("/health/live", async () => ({ status: "ok" }));
  server.get("/health/ready", async (request, reply) => {
    if (!lifecycle.isReady()) {
      reply.status(503);
      return { status: "not_ready" };
    }

    try {
      await options.database.check();
      if (!lifecycle.isReady()) {
        reply.status(503);
        return { status: "not_ready" };
      }
      return { status: "ready" };
    } catch {
      request.log.error({ event: "database_readiness_failed" }, "Database readiness check failed");
      reply.status(503);
      return { status: "not_ready" };
    }
  });

  return { server, lifecycle };
}
