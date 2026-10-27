import { constants } from "node:fs";
import { lstat, open, type FileHandle } from "node:fs/promises";

import { Pool, type PoolConfig } from "pg";

import type { DatabaseConfig } from "./config.js";

const MAX_PASSWORD_FILE_BYTES = 4 * 1024;
const DATABASE_PROBE = "SELECT 1";

/** Only the operations required by startup and health checks are exposed to the app. */
export interface DatabaseHealth {
  check(): Promise<void>;
  close(): Promise<void>;
}

interface DatabasePool {
  query(queryText: string): Promise<unknown>;
  end(): Promise<void>;
  on(event: "error", listener: (error: Error) => void): unknown;
}

export type DatabasePoolFactory = (config: PoolConfig) => DatabasePool;

export interface DatabaseHealthOptions {
  readonly createPool?: DatabasePoolFactory;
  readonly onBackgroundError?: () => void;
  /** Optional environment snapshot for callers that do not use process.env directly. */
  readonly environment?: Record<string, string | undefined>;
}

export class DatabaseInitializationError extends Error {
  constructor() {
    super("Database initialization failed.");
    this.name = "DatabaseInitializationError";
  }
}

export class DatabaseCheckError extends Error {
  constructor() {
    super("Database health check failed.");
    this.name = "DatabaseCheckError";
  }
}

export class DatabaseCleanupError extends Error {
  constructor() {
    super("Database cleanup failed.");
    this.name = "DatabaseCleanupError";
  }
}

async function readPassword(passwordFile: string): Promise<string> {
  let fileHandle: FileHandle | undefined;
  try {
    const pathMetadata = await lstat(passwordFile);
    if (!pathMetadata.isFile() || pathMetadata.size > MAX_PASSWORD_FILE_BYTES) {
      throw new DatabaseInitializationError();
    }

    let flags = constants.O_RDONLY;
    const isLinux = process.platform === "linux";
    if (isLinux) {
      flags |= constants.O_NONBLOCK | constants.O_NOFOLLOW;
    }

    fileHandle = await open(passwordFile, flags);
    const metadata = await fileHandle.stat();
    const replacedDuringOpen = isLinux
      && (metadata.dev !== pathMetadata.dev || metadata.ino !== pathMetadata.ino);
    if (!metadata.isFile() || metadata.size > MAX_PASSWORD_FILE_BYTES || replacedDuringOpen) {
      throw new DatabaseInitializationError();
    }

    // Read one byte beyond the limit so a file that grows after stat is still rejected.
    const buffer = Buffer.alloc(MAX_PASSWORD_FILE_BYTES + 1);
    const { bytesRead } = await fileHandle.read(buffer, 0, buffer.length, 0);
    if (bytesRead > MAX_PASSWORD_FILE_BYTES) {
      throw new DatabaseInitializationError();
    }
    const contents = buffer.subarray(0, bytesRead);
    if (contents.length === 0 || contents.includes(0)) {
      throw new DatabaseInitializationError();
    }

    let password = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(contents);
    if (password.endsWith("\r\n")) {
      password = password.slice(0, -2);
    } else if (password.endsWith("\n")) {
      password = password.slice(0, -1);
    }

    if (password.length === 0 || password.includes("\0")) {
      throw new DatabaseInitializationError();
    }
    return password;
  } catch {
    // Filesystem errors include the supplied path. Keep all secret-file failures generic.
    throw new DatabaseInitializationError();
  } finally {
    if (fileHandle !== undefined) {
      try {
        await fileHandle.close();
      } catch {
        throw new DatabaseInitializationError();
      }
    }
  }
}

function createPgPool(config: PoolConfig): DatabasePool {
  return new Pool(config);
}

export async function createDatabaseHealth(
  config: DatabaseConfig,
  options: DatabaseHealthOptions = {},
): Promise<DatabaseHealth> {
  if (hasForbiddenPgEnvironment(process.env) ||
      (options.environment !== undefined && hasForbiddenPgEnvironment(options.environment))) {
    throw new DatabaseInitializationError();
  }

  const password = await readPassword(config.passwordFile);
  const poolConfig: PoolConfig = {
    host: config.host,
    port: config.port,
    database: config.name,
    user: config.user,
    password,
    max: config.poolMax,
    connectionTimeoutMillis: 2_000,
    idleTimeoutMillis: 10_000,
    query_timeout: 2_000,
    statement_timeout: 2_000,
    application_name: "shattab-api",
    client_encoding: "UTF8",
    options: "-c client_encoding=UTF8",
    sslnegotiation: "postgres",
    // The API and PostgreSQL are designed to share a private host network.
    // Keep this explicit so PGSSLMODE cannot silently change connection behavior.
    ssl: false,
  };

  let pool: DatabasePool;
  try {
    pool = (options.createPool ?? createPgPool)(poolConfig);
    pool.on("error", () => {
      try {
        options.onBackgroundError?.();
      } catch {
        // A logging callback must not turn a handled pool event into an uncaught error.
      }
    });
  } catch {
    throw new DatabaseInitializationError();
  }

  let closePromise: Promise<void> | undefined;
  return {
    async check(): Promise<void> {
      try {
        await pool.query(DATABASE_PROBE);
      } catch {
        // Never expose PostgreSQL details, SQL state, or connection metadata to callers.
        throw new DatabaseCheckError();
      }
    },
    close(): Promise<void> {
      closePromise ??= Promise.resolve()
        .then(() => pool.end())
        .catch(() => {
          throw new DatabaseCleanupError();
        });
      return closePromise;
    },
  };
}

function hasForbiddenPgEnvironment(environment: Record<string, string | undefined>): boolean {
  return environment["PGBINARY"] !== undefined || environment["PGREPLICATION"] !== undefined;
}
