import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmod, mkdtemp, mkdir, readFile, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import type { PoolConfig } from "pg";

import type { DatabaseConfig } from "../src/config.js";
import {
  createDatabaseHealth,
  DatabaseCheckError,
  DatabaseInitializationError,
} from "../src/database.js";

const TEST_PASSWORD = "synthetic-db-password-for-tests";

const databaseConfig = (passwordFile: string): DatabaseConfig => ({
  host: "postgres.test.internal",
  port: 55432,
  name: "shattab_test",
  user: "shattab_app_test",
  passwordFile,
  poolMax: 3,
});

async function withTemporaryDirectory<T>(run: (directory: string) => Promise<T>): Promise<T> {
  const directory = await mkdtemp(join(tmpdir(), "shattab-api-database-test-"));
  try {
    return await run(directory);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

async function assertGenericInitializationFailure(operation: Promise<unknown>, path?: string): Promise<void> {
  const error = await operation.then(() => undefined, (failure: unknown) => failure);
  assert.equal(error instanceof DatabaseInitializationError, true);
  if (error instanceof Error) {
    assert.equal(error.message, "Database initialization failed.");
    assert.equal(error.message.includes(TEST_PASSWORD), false);
    assert.equal((error.stack ?? "").includes(TEST_PASSWORD), false);
    if (path !== undefined) assert.equal(error.message.includes(path), false);
  }
}

async function createHealthAndCapturePassword(
  passwordFile: string,
): Promise<{ readonly passwordMatches: boolean; readonly health: Awaited<ReturnType<typeof createDatabaseHealth>> }> {
  let configuredPassword: string | undefined;
  const health = await createDatabaseHealth(databaseConfig(passwordFile), {
    createPool: (config: PoolConfig) => {
      configuredPassword = config.password;
      return {
        query: async () => undefined,
        end: async () => undefined,
        on: () => undefined,
      };
    },
  });
  return { passwordMatches: configuredPassword === TEST_PASSWORD, health };
}

async function withoutProtocolOverrides<T>(run: () => Promise<T>): Promise<T> {
  const names = ["PGBINARY", "PGREPLICATION"] as const;
  const original = new Map(names.map((name) => [name, process.env[name]]));
  for (const name of names) delete process.env[name];
  try {
    return await run();
  } finally {
    for (const name of names) {
      const value = original.get(name);
      if (value === undefined) delete process.env[name];
      else process.env[name] = value;
    }
  }
}

test("reads LF and CRLF secret files while preserving the exact password characters", async () => {
  await withoutProtocolOverrides(() => withTemporaryDirectory(async (directory) => {
    for (const newline of ["\n", "\r\n"]) {
      const path = join(directory, newline === "\n" ? "password-lf" : "password-crlf");
      await writeFile(path, `${TEST_PASSWORD}${newline}`, { mode: 0o600 });
      const result = await createHealthAndCapturePassword(path);
      try {
        assert.equal(result.passwordMatches, true);
      } finally {
        await result.health.close();
      }
    }

    const preservedPath = join(directory, "password-with-internal-newline");
    const preservedPassword = `${TEST_PASSWORD}\nsecond-line`;
    await writeFile(preservedPath, `${preservedPassword}\n`, { mode: 0o600 });
    let receivedPassword: string | undefined;
    const health = await createDatabaseHealth(databaseConfig(preservedPath), {
      createPool: (config) => {
        receivedPassword = config.password;
        return { query: async () => undefined, end: async () => undefined, on: () => undefined };
      },
    });
    try {
      assert.equal(receivedPassword === preservedPassword, true);
    } finally {
      await health.close();
    }

    const bomPath = join(directory, "password-leading-bom");
    await writeFile(bomPath, Buffer.concat([Buffer.from([0xef, 0xbb, 0xbf]), Buffer.from(TEST_PASSWORD)]), { mode: 0o600 });
    let bomPreserved = false;
    const bomHealth = await createDatabaseHealth(databaseConfig(bomPath), {
      createPool: (config) => {
        bomPreserved = config.password === `\uFEFF${TEST_PASSWORD}`;
        return { query: async () => undefined, end: async () => undefined, on: () => undefined };
      },
    });
    try {
      assert.equal(bomPreserved, true);
    } finally {
      await bomHealth.close();
    }
  }));
});

test("uses explicit bounded pool settings, probes only SELECT 1, and closes once", async () => {
  await withoutProtocolOverrides(() => withTemporaryDirectory(async (directory) => {
    const passwordFile = join(directory, "password");
    await writeFile(passwordFile, TEST_PASSWORD, { mode: 0o600 });

    let receivedConfig: PoolConfig | undefined;
    const queries: string[] = [];
    let endCalls = 0;
    const health = await createDatabaseHealth(databaseConfig(passwordFile), {
      createPool: (config) => {
        receivedConfig = config;
        return {
          query: async (queryText: string) => { queries.push(queryText); },
          end: async () => { endCalls += 1; },
          on: () => undefined,
        };
      },
    });

    try {
      assert.ok(receivedConfig);
      const { password, ...withoutPassword } = receivedConfig;
      assert.deepEqual(withoutPassword, {
        host: "postgres.test.internal",
        port: 55432,
        database: "shattab_test",
        user: "shattab_app_test",
        max: 3,
        connectionTimeoutMillis: 2_000,
        idleTimeoutMillis: 10_000,
        query_timeout: 2_000,
        statement_timeout: 2_000,
        application_name: "shattab-api",
        client_encoding: "UTF8",
        options: "-c client_encoding=UTF8",
        sslnegotiation: "postgres",
        ssl: false,
      });
      assert.equal(password === TEST_PASSWORD, true);
      assert.equal(Number.isFinite(receivedConfig.connectionTimeoutMillis), true);
      assert.equal(Number.isFinite(receivedConfig.idleTimeoutMillis), true);

      await health.check();
      assert.deepEqual(queries, ["SELECT 1"]);
      await Promise.all([health.close(), health.close()]);
      assert.equal(endCalls, 1);
    } finally {
      await health.close();
    }
  }));
});

test("rejects forbidden protocol overrides in injected and process environments", async () => {
  await withoutProtocolOverrides(async () => {
    const missingPasswordPath = "synthetic-missing-secret-path";
    let poolCreated = false;
    for (const setting of ["PGBINARY", "PGREPLICATION"] as const) {
      await assertGenericInitializationFailure(createDatabaseHealth(databaseConfig(missingPasswordPath), {
        environment: { [setting]: "synthetic-protocol-override" },
        createPool: () => {
          poolCreated = true;
          return { query: async () => undefined, end: async () => undefined, on: () => undefined };
        },
      }), missingPasswordPath);

      process.env[setting] = "synthetic-process-protocol-override";
      try {
        await assertGenericInitializationFailure(createDatabaseHealth(databaseConfig(missingPasswordPath)), missingPasswordPath);
      } finally {
        delete process.env[setting];
      }
    }
    assert.equal(poolCreated, false);
  });
});

test("replaces raw PostgreSQL probe failures with a generic error", async () => {
  await withoutProtocolOverrides(() => withTemporaryDirectory(async (directory) => {
    const passwordFile = join(directory, "password");
    await writeFile(passwordFile, TEST_PASSWORD, { mode: 0o600 });
    const health = await createDatabaseHealth(databaseConfig(passwordFile), {
      createPool: () => ({
        query: async () => { throw new Error("synthetic-postgres-error-sentinel"); },
        end: async () => undefined,
        on: () => undefined,
      }),
    });
    try {
      const error = await health.check().then(() => undefined, (failure: unknown) => failure);
      assert.equal(error instanceof DatabaseCheckError, true);
      if (error instanceof Error) {
        assert.equal(error.message, "Database health check failed.");
        assert.equal(error.message.includes("synthetic-postgres-error-sentinel"), false);
        assert.equal((error.stack ?? "").includes("synthetic-postgres-error-sentinel"), false);
      }
    } finally {
      await health.close();
    }
  }));
});

test("rejects missing, empty, oversized, NUL-containing, and invalid UTF-8 secret files generically", async () => {
  await withoutProtocolOverrides(() => withTemporaryDirectory(async (directory) => {
    const missingPath = join(directory, "synthetic-missing-password-path");
    await assertGenericInitializationFailure(createDatabaseHealth(databaseConfig(missingPath)), missingPath);

    const invalidFiles: Array<{ name: string; contents: Buffer | string }> = [
      { name: "empty", contents: "" },
      { name: "oversized", contents: Buffer.alloc(4 * 1024 + 1, 0x61) },
      { name: "nul", contents: Buffer.from([0x61, 0x00, 0x62]) },
      { name: "invalid-utf8", contents: Buffer.from([0xc3, 0x28]) },
    ];

    for (const file of invalidFiles) {
      const path = join(directory, file.name);
      await writeFile(path, file.contents, { mode: 0o600 });
      const contentsBefore = await readFile(path);
      await assertGenericInitializationFailure(createDatabaseHealth(databaseConfig(path)), path);
      assert.deepEqual(await readFile(path), contentsBefore);
    }
  }));
});

test("rejects directories and, where supported, symlinks as secret paths", async (t) => {
  await withoutProtocolOverrides(() => withTemporaryDirectory(async (directory) => {
    const directoryPath = join(directory, "directory-secret-path");
    await mkdir(directoryPath);
    await assertGenericInitializationFailure(createDatabaseHealth(databaseConfig(directoryPath)), directoryPath);

    const targetPath = join(directory, "regular-target");
    const linkPath = join(directory, "secret-symlink");
    await writeFile(targetPath, TEST_PASSWORD, { mode: 0o600 });
    try {
      await symlink(targetPath, linkPath, "file");
    } catch {
      t.skip("Creating filesystem symlinks is unavailable for this test user or platform.");
      return;
    }
    await assertGenericInitializationFailure(createDatabaseHealth(databaseConfig(linkPath)), linkPath);
  }));
});

test("rejects a FIFO secret path without opening or blocking on it where supported", async (t) => {
  if (process.platform === "win32") {
    t.skip("Windows does not provide POSIX FIFOs.");
    return;
  }

  await withoutProtocolOverrides(() => withTemporaryDirectory(async (directory) => {
    const fifoPath = join(directory, "secret-fifo");
    const result = spawnSync("mkfifo", [fifoPath], { encoding: "utf8" });
    if (result.error !== undefined || result.status !== 0) {
      t.skip("The mkfifo utility is unavailable in this environment.");
      return;
    }
    await assertGenericInitializationFailure(createDatabaseHealth(databaseConfig(fifoPath)), fifoPath);
  }));
});

test("rejects unreadable secret files where the current OS account can enforce permissions", async (t) => {
  if (process.platform === "win32" || process.getuid?.() === 0) {
    t.skip("The current platform or privileged test account cannot verify POSIX read denial reliably.");
    return;
  }

  await withoutProtocolOverrides(() => withTemporaryDirectory(async (directory) => {
    const path = join(directory, "unreadable-password");
    await writeFile(path, TEST_PASSWORD, { mode: 0o600 });
    await chmod(path, 0o000);
    try {
      await assertGenericInitializationFailure(createDatabaseHealth(databaseConfig(path)), path);
    } finally {
      await chmod(path, 0o600);
    }
  }));
});
