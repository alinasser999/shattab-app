import assert from "node:assert/strict";
import { test } from "node:test";

import { createApp, type ShattabApplication } from "../src/app.js";
import type { DatabaseHealth } from "../src/database.js";
import {
  startServer,
  type ShutdownSignal,
  type ShutdownSignalSource,
} from "../src/server.js";
import { fakeDatabaseHealth, LogCapture } from "./helpers.js";

class TestSignalSource implements ShutdownSignalSource {
  private readonly listeners = new Map<ShutdownSignal, Set<() => void>>();

  on(signal: ShutdownSignal, listener: () => void): this {
    const listeners = this.listeners.get(signal) ?? new Set<() => void>();
    listeners.add(listener);
    this.listeners.set(signal, listeners);
    return this;
  }

  off(signal: ShutdownSignal, listener: () => void): this {
    this.listeners.get(signal)?.delete(listener);
    return this;
  }

  listenerCount(): number {
    let count = 0;
    for (const listeners of this.listeners.values()) count += listeners.size;
    return count;
  }
}

function validEnvironment(): Record<string, string> {
  return {
    HOST: "127.0.0.1",
    PORT: "3000",
    LOG_LEVEL: "info",
    DATABASE_HOST: "postgres.test.internal",
    DATABASE_NAME: "shattab_test",
    DATABASE_USER: "shattab_app_test",
    DATABASE_PASSWORD_FILE: "/synthetic/test-password-file",
  };
}

test("configuration failure sets nonzero status without constructing database or application", async () => {
  const signals = new TestSignalSource();
  const errors: string[] = [];
  const exitCodes: number[] = [];
  let databaseCreated = false;
  let applicationCreated = false;

  await startServer({ ...validEnvironment(), DATABASE_POOL_MAX: "private-pool-sentinel" }, signals, {
    createDatabase: async () => {
      databaseCreated = true;
      return fakeDatabaseHealth();
    },
    createApplication: () => {
      applicationCreated = true;
      throw new Error("synthetic-application-sentinel");
    },
    setExitCode: (code) => { exitCodes.push(code); },
    writeErrorLine: (line) => { errors.push(line); },
  });

  assert.deepEqual(exitCodes, [1]);
  assert.equal(databaseCreated, false);
  assert.equal(applicationCreated, false);
  assert.equal(signals.listenerCount(), 0);
  assert.equal(errors.join("").includes("private-pool-sentinel"), false);
});

test("database initialization failure sets nonzero status before creating or listening to the app", async () => {
  const signals = new TestSignalSource();
  const errors: string[] = [];
  const exitCodes: number[] = [];
  let applicationCreated = false;

  await startServer(validEnvironment(), signals, {
    createDatabase: async () => { throw new Error("synthetic-secret-file-path-or-driver-error-sentinel"); },
    createApplication: () => {
      applicationCreated = true;
      throw new Error("synthetic-application-sentinel");
    },
    setExitCode: (code) => { exitCodes.push(code); },
    writeErrorLine: (line) => { errors.push(line); },
  });

  assert.deepEqual(exitCodes, [1]);
  assert.equal(applicationCreated, false);
  assert.equal(signals.listenerCount(), 0);
  const output = errors.join("");
  assert.equal(output.includes("synthetic-secret-file-path-or-driver-error-sentinel"), false);
  assert.equal(output.includes("/synthetic/test-password-file"), false);
});

test("failed initial database probe closes resources once and never invokes listen", async () => {
  const signals = new TestSignalSource();
  const capture = new LogCapture();
  const exitCodes: number[] = [];
  let checkCalls = 0;
  let closeCalls = 0;
  let listenCalls = 0;
  let application: ShattabApplication | undefined;
  const database: DatabaseHealth = fakeDatabaseHealth(async () => {
    checkCalls += 1;
    throw new Error("synthetic-postgres-startup-error-sentinel");
  }, async () => { closeCalls += 1; });

  await startServer(validEnvironment(), signals, {
    createDatabase: async () => database,
    createApplication: (options) => {
      application = createApp({ ...options, logLevel: "error", loggerStream: capture });
      const noNetworkServer = application.server as unknown as {
        listen: (...args: unknown[]) => Promise<unknown>;
      };
      noNetworkServer.listen = async () => {
        listenCalls += 1;
        throw new Error("Synthetic listener must not be invoked when startup probe fails.");
      };
      return application;
    },
    setExitCode: (code) => { exitCodes.push(code); },
    writeErrorLine: (line) => { capture.write(line); },
  });

  try {
    assert.deepEqual(exitCodes, [1]);
    assert.equal(checkCalls, 1);
    assert.equal(closeCalls, 1);
    assert.equal(listenCalls, 0);
    assert.equal(application?.server.server.address(), null);
    assert.equal(signals.listenerCount(), 0);
    assert.equal(capture.text.includes("synthetic-postgres-startup-error-sentinel"), false);
    assert.equal(capture.text.includes("synthetic-listener-must-not-be-invoked"), false);
  } finally {
    await application?.server.close().catch(() => undefined);
    capture.end();
  }
});
