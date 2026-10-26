import type { AppLifecycle } from "./app.js";
import { createApp, type CreateAppOptions, type ShattabApplication } from "./app.js";
import { ConfigurationError, parseConfig, type AppConfig, type DatabaseConfig } from "./config.js";
import {
  createDatabaseHealth,
  type DatabaseHealth,
  type DatabaseHealthOptions,
} from "./database.js";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export type ShutdownSignal = "SIGINT" | "SIGTERM";

export interface ShutdownSignalSource {
  on(signal: ShutdownSignal, listener: () => void): unknown;
  off(signal: ShutdownSignal, listener: () => void): unknown;
}

export interface ShutdownController {
  waitForShutdown(): Promise<void>;
  isShutdownStarted(): boolean;
  removeListeners(): void;
}

interface ShutdownOptions {
  readonly lifecycle: AppLifecycle;
  readonly server: ReturnType<typeof createApp>["server"];
  readonly signalSource?: ShutdownSignalSource;
  readonly setExitCode?: (code: number) => void;
}

export function registerShutdownHandlers(options: ShutdownOptions): ShutdownController {
  const signalSource = options.signalSource ?? process;
  const setExitCode = options.setExitCode ?? ((code: number) => { process.exitCode = code; });
  let shutdownPromise: Promise<void> | undefined;

  const removeListeners = () => {
    signalSource.off("SIGTERM", onSignal);
    signalSource.off("SIGINT", onSignal);
  };

  const beginShutdown = (): Promise<void> => {
    if (shutdownPromise !== undefined) return shutdownPromise;

    options.lifecycle.markDraining();
    options.server.log.info({ event: "shutdown_started" }, "Graceful shutdown started");

    shutdownPromise = Promise.resolve()
      .then(() => options.server.close())
      .then(() => {
        options.server.log.info({ event: "shutdown_completed" }, "Graceful shutdown completed");
      })
      .catch(() => {
        setExitCode(1);
        options.server.log.error({ event: "shutdown_failed" }, "Graceful shutdown failed");
      })
      .finally(removeListeners);

    return shutdownPromise;
  };

  const onSignal = () => {
    void beginShutdown();
  };

  signalSource.on("SIGTERM", onSignal);
  signalSource.on("SIGINT", onSignal);

  return {
    waitForShutdown() {
      return shutdownPromise ?? Promise.resolve();
    },
    isShutdownStarted() {
      return shutdownPromise !== undefined;
    },
    removeListeners,
  };
}

type DatabaseHealthFactory = (
  config: DatabaseConfig,
  options: DatabaseHealthOptions,
) => Promise<DatabaseHealth>;

export interface StartServerDependencies {
  readonly createDatabase?: DatabaseHealthFactory;
  readonly createApplication?: (options: CreateAppOptions) => ShattabApplication;
  readonly setExitCode?: (code: number) => void;
  readonly writeErrorLine?: (line: string) => void;
}

function writeSafeError(event: string, message: string, writeErrorLine: (line: string) => void): void {
  writeErrorLine(`${JSON.stringify({ level: "error", event, message })}\n`);
}

function writeSafeConfigurationError(
  error: unknown,
  writeErrorLine: (line: string) => void,
): void {
  const message = error instanceof ConfigurationError
    ? error.message
    : "Invalid API configuration.";
  writeSafeError("configuration_invalid", message, writeErrorLine);
}

async function closeAfterStartupFailure(
  server: ReturnType<typeof createApp>["server"],
): Promise<void> {
  try {
    await server.close();
  } catch {
    server.log.error({ event: "startup_cleanup_failed" }, "Startup cleanup failed");
  }
}

export async function startServer(
  env: Record<string, string | undefined> = process.env,
  signalSource: ShutdownSignalSource = process,
  dependencies: StartServerDependencies = {},
): Promise<void> {
  const setExitCode = dependencies.setExitCode ?? ((code: number) => { process.exitCode = code; });
  const writeErrorLine = dependencies.writeErrorLine ?? ((line: string) => process.stderr.write(line));
  let config: AppConfig;
  try {
    config = parseConfig(env);
  } catch (error) {
    writeSafeConfigurationError(error, writeErrorLine);
    setExitCode(1);
    return;
  }

  let database: DatabaseHealth | undefined;
  let application: ShattabApplication | undefined;
  let shutdown: ShutdownController | undefined;

  try {
    database = await (dependencies.createDatabase ?? createDatabaseHealth)(config.database, {
      onBackgroundError: () => {
        application?.server.log.error(
          { event: "database_pool_idle_error" },
          "Database connection error",
        );
      },
    });
    application = (dependencies.createApplication ?? createApp)({
      database,
      logLevel: config.logLevel,
    });
    const { server, lifecycle } = application;
    server.addHook("onClose", async () => {
      await database?.close();
    });
    shutdown = registerShutdownHandlers({ lifecycle, server, signalSource, setExitCode });

    // Initialize Fastify hooks before probing; close() then owns pool cleanup even if
    // the initial probe fails and the listener never opens.
    await server.ready();
    await database.check();
    if (shutdown.isShutdownStarted()) {
      await shutdown.waitForShutdown();
      return;
    }

    await server.listen({ host: config.host, port: config.port });
    if (shutdown.isShutdownStarted()) {
      await shutdown.waitForShutdown();
      return;
    }
    lifecycle.markReady();
    server.log.info({
      event: "server_ready",
      host: config.host,
      port: config.port,
    }, "Shattab API is listening");
  } catch {
    if (shutdown?.isShutdownStarted()) {
      await shutdown.waitForShutdown();
      return;
    }

    if (application !== undefined) {
      application.lifecycle.markDraining();
      application.server.log.error({ event: "startup_failed" }, "Failed to start API server");
      setExitCode(1);
      await closeAfterStartupFailure(application.server);
    } else {
      if (database !== undefined) await closeDatabaseAfterStartupFailure(database);
      writeSafeError("startup_failed", "Failed to initialize API server.", writeErrorLine);
      setExitCode(1);
    }

    shutdown?.removeListeners();
  }
}

async function closeDatabaseAfterStartupFailure(database: DatabaseHealth): Promise<void> {
  try {
    await database.close();
  } catch {
    // Database cleanup errors are deliberately not serialized or logged.
  }
}

function isEntrypoint(): boolean {
  const entrypoint = process.argv[1];
  return entrypoint !== undefined && fileURLToPath(import.meta.url).toLowerCase() === resolve(entrypoint).toLowerCase();
}

if (isEntrypoint()) {
  void startServer();
}
