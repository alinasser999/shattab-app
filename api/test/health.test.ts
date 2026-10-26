import assert from "node:assert/strict";
import { test } from "node:test";

import { createApp } from "../src/app.js";
import { fakeDatabaseHealth, LogCapture } from "./helpers.js";

test("liveness stays available and readiness follows startup/draining state", async () => {
  let checkCalls = 0;
  const application = createApp({
    logLevel: "silent",
    database: fakeDatabaseHealth(async () => { checkCalls += 1; }),
  });
  const { server, lifecycle } = application;

  try {
    await server.ready();

    const starting = await server.inject({ method: "GET", url: "/health/ready" });
    assert.equal(starting.statusCode, 503);
    assert.deepEqual(starting.json(), { status: "not_ready" });
    assert.equal(checkCalls, 0);

    const liveBeforeReady = await server.inject({ method: "GET", url: "/health/live" });
    assert.equal(liveBeforeReady.statusCode, 200);
    assert.deepEqual(liveBeforeReady.json(), { status: "ok" });

    lifecycle.markReady();
    const ready = await server.inject({ method: "GET", url: "/health/ready" });
    assert.equal(ready.statusCode, 200);
    assert.deepEqual(ready.json(), { status: "ready" });
    assert.equal(checkCalls, 1);

    lifecycle.markDraining();
    const draining = await server.inject({ method: "GET", url: "/health/ready" });
    assert.equal(draining.statusCode, 503);
    assert.deepEqual(draining.json(), { status: "not_ready" });
    assert.equal(checkCalls, 1);

    const liveWhileDraining = await server.inject({ method: "GET", url: "/health/live" });
    assert.equal(liveWhileDraining.statusCode, 200);
    assert.deepEqual(liveWhileDraining.json(), { status: "ok" });
  } finally {
    await server.close();
  }
});

test("readiness reports a database outage generically, stays live, and recovers", async () => {
  const capture = new LogCapture();
  let databaseUnavailable = true;
  let checkCalls = 0;
  const application = createApp({
    logLevel: "error",
    loggerStream: capture,
    database: fakeDatabaseHealth(async () => {
      checkCalls += 1;
      if (databaseUnavailable) throw new Error("synthetic-database-outage-secret-sentinel");
    }),
  });
  const { server, lifecycle } = application;

  try {
    await server.ready();
    lifecycle.markReady();

    const unavailable = await server.inject({ method: "GET", url: "/health/ready" });
    assert.equal(unavailable.statusCode, 503);
    assert.deepEqual(unavailable.json(), { status: "not_ready" });
    assert.equal(unavailable.body.includes("synthetic-database-outage-secret-sentinel"), false);

    const liveDuringOutage = await server.inject({ method: "GET", url: "/health/live" });
    assert.equal(liveDuringOutage.statusCode, 200);
    assert.deepEqual(liveDuringOutage.json(), { status: "ok" });

    databaseUnavailable = false;
    const recovered = await server.inject({ method: "GET", url: "/health/ready" });
    assert.equal(recovered.statusCode, 200);
    assert.deepEqual(recovered.json(), { status: "ready" });
    assert.equal(checkCalls, 2);
    assert.equal(capture.text.includes("synthetic-database-outage-secret-sentinel"), false);
  } finally {
    await server.close();
    capture.end();
  }
});

test("readiness remains not ready if draining begins while the database probe is pending", async () => {
  let releaseProbe!: () => void;
  const probeGate = new Promise<void>((resolve) => { releaseProbe = resolve; });
  const application = createApp({
    logLevel: "silent",
    database: fakeDatabaseHealth(async () => probeGate),
  });
  const { server, lifecycle } = application;

  try {
    await server.ready();
    lifecycle.markReady();
    const pendingResponse = server.inject({ method: "GET", url: "/health/ready" });
    await new Promise<void>((resolve) => setImmediate(resolve));
    lifecycle.markDraining();
    releaseProbe();

    const response = await pendingResponse;
    assert.equal(response.statusCode, 503);
    assert.deepEqual(response.json(), { status: "not_ready" });
  } finally {
    releaseProbe();
    await server.close();
  }
});

test("returns a generic response for unknown routes", async () => {
  const { server } = createApp({ logLevel: "silent", database: fakeDatabaseHealth() });
  try {
    const response = await server.inject({ method: "GET", url: "/unconfigured?private=query-sentinel" });
    assert.equal(response.statusCode, 404);
    assert.deepEqual(response.json(), { status: "not_found" });
    assert.equal(response.body.includes("query-sentinel"), false);
  } finally {
    await server.close();
  }
});
