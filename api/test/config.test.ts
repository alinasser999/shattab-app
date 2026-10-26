import assert from "node:assert/strict";
import { test } from "node:test";

import { ConfigurationError, LOOPBACK_HOST, parseConfig } from "../src/config.js";

const VALID_DATABASE_SETTINGS = {
  DATABASE_HOST: "postgres.internal",
  DATABASE_NAME: "shattab_test",
  DATABASE_USER: "shattab_app",
  DATABASE_PASSWORD_FILE: "/temporary/test-password",
};

test("uses loopback and safe defaults", () => {
  const env = {
    DATABASE_HOST: "postgres.internal",
    DATABASE_NAME: "shattab_test",
    DATABASE_USER: "shattab_app",
    DATABASE_PASSWORD_FILE: "/temporary/test-password",
  };

  assert.deepEqual(parseConfig(env), {
    host: LOOPBACK_HOST,
    port: 3000,
    logLevel: "info",
    database: {
      host: "postgres.internal",
      name: "shattab_test",
      user: "shattab_app",
      passwordFile: "/temporary/test-password",
      port: 5432,
      poolMax: 4,
    },
  });
});

test("requires each database connection setting without echoing supplied values", () => {
  const valid = {
    DATABASE_HOST: "postgres.internal",
    DATABASE_NAME: "shattab_test",
    DATABASE_USER: "shattab_app",
    DATABASE_PASSWORD_FILE: "/temporary/test-password",
  };

  for (const setting of Object.keys(valid)) {
    const env = { ...valid };
    delete env[setting as keyof typeof env];
    assert.throws(() => parseConfig(env), (error: unknown) => {
      assert.equal(error instanceof ConfigurationError, true);
      if (error instanceof Error) assert.equal(error.message.includes("private-setting-sentinel"), false);
      return true;
    });
  }
});

test("accepts bounded PostgreSQL port and pool settings", () => {
  const base = {
    DATABASE_HOST: "postgres.internal",
    DATABASE_NAME: "shattab_test",
    DATABASE_USER: "shattab_app",
    DATABASE_PASSWORD_FILE: "/temporary/test-password",
  };

  assert.equal(parseConfig({ ...base, DATABASE_PORT: "1", DATABASE_POOL_MAX: "1" }).database.port, 1);
  assert.equal(parseConfig({ ...base, DATABASE_PORT: "65535", DATABASE_POOL_MAX: "8" }).database.poolMax, 8);
});

test("rejects malformed and out-of-range PostgreSQL settings without echoing values", () => {
  const base = {
    DATABASE_HOST: "postgres.internal",
    DATABASE_NAME: "shattab_test",
    DATABASE_USER: "shattab_app",
    DATABASE_PASSWORD_FILE: "/temporary/test-password",
  };
  const invalidSettings = [
    ["DATABASE_PORT", "0"],
    ["DATABASE_PORT", "65536"],
    ["DATABASE_PORT", "1e3"],
    ["DATABASE_PORT", "private-port-sentinel"],
    ["DATABASE_POOL_MAX", "0"],
    ["DATABASE_POOL_MAX", "9"],
    ["DATABASE_POOL_MAX", "2.5"],
    ["DATABASE_POOL_MAX", "private-pool-sentinel"],
  ] as const;

  for (const [setting, value] of invalidSettings) {
    assert.throws(() => parseConfig({ ...base, [setting]: value }), (error: unknown) => {
      assert.equal(error instanceof ConfigurationError, true);
      if (error instanceof Error) assert.equal(error.message.includes(value), false);
      return true;
    });
  }
});

test("rejects inline password, password URL, and protocol-mode overrides without echoing values", () => {
  const base = {
    DATABASE_HOST: "postgres.internal",
    DATABASE_NAME: "shattab_test",
    DATABASE_USER: "shattab_app",
    DATABASE_PASSWORD_FILE: "/temporary/test-password",
  };

  for (const [setting, value] of [
    ["DATABASE_PASSWORD", "synthetic-inline-password-sentinel"],
    ["DATABASE_URL", "postgres://synthetic-url-password-sentinel@invalid"],
    ["PGBINARY", "synthetic-binary-mode-sentinel"],
    ["PGREPLICATION", "synthetic-replication-mode-sentinel"],
  ] as const) {
    assert.throws(() => parseConfig({ ...base, [setting]: value }), (error: unknown) => {
      assert.equal(error instanceof ConfigurationError, true);
      if (error instanceof Error) assert.equal(error.message.includes(value), false);
      return true;
    });
  }
});

test("accepts only the exact supported host addresses", () => {
  assert.equal(parseConfig({ ...VALID_DATABASE_SETTINGS, HOST: "127.0.0.1" }).host, LOOPBACK_HOST);
  assert.equal(parseConfig({ ...VALID_DATABASE_SETTINGS, HOST: "0.0.0.0" }).host, "0.0.0.0");
});

test("rejects unsupported host values without echoing input", () => {
  const invalidHosts = ["localhost", "::", "0.0.0.1", "", "private-host-sentinel"];

  for (const value of invalidHosts) {
    assert.throws(() => parseConfig({ ...VALID_DATABASE_SETTINGS, HOST: value }), (error: unknown) => {
      assert.ok(error instanceof ConfigurationError);
      assert.match(error.message, /Invalid HOST/);
      assert.match(error.message, /expected 127\.0\.0\.1 or 0\.0\.0\.0/);
      if (value.length > 0) assert.equal(error.message.includes(value), false);
      return true;
    });
  }
});

test("accepts port boundaries and supported log levels", () => {
  assert.equal(parseConfig({ ...VALID_DATABASE_SETTINGS, PORT: "1" }).port, 1);
  assert.equal(parseConfig({ ...VALID_DATABASE_SETTINGS, PORT: "65535" }).port, 65_535);
  assert.equal(parseConfig({ ...VALID_DATABASE_SETTINGS, LOG_LEVEL: "silent" }).logLevel, "silent");
});

test("rejects malformed, non-numeric, and out-of-range ports without echoing input", () => {
  const invalidPorts = ["0", "65536", "-1", "3.0", "1e3", "3000abc", "", "private-port-sentinel"];

  for (const value of invalidPorts) {
    assert.throws(() => parseConfig({ ...VALID_DATABASE_SETTINGS, PORT: value }), (error: unknown) => {
      assert.ok(error instanceof ConfigurationError);
      assert.match(error.message, /Invalid PORT/);
      if (value.length > 0) assert.equal(error.message.includes(value), false);
      return true;
    });
  }
});

test("rejects unsupported log levels without echoing input", () => {
  const value = "private-log-level-sentinel";
  assert.throws(() => parseConfig({ ...VALID_DATABASE_SETTINGS, LOG_LEVEL: value }), (error: unknown) => {
    assert.ok(error instanceof ConfigurationError);
    assert.match(error.message, /Invalid LOG_LEVEL/);
    assert.equal(error.message.includes(value), false);
    return true;
  });
});
