import assert from "node:assert/strict";
import { test } from "node:test";

import { createApp } from "../src/app.js";
import { registerShutdownHandlers, type ShutdownSignal, type ShutdownSignalSource } from "../src/server.js";
import { fakeDatabaseHealth } from "./helpers.js";

type SignalListener = () => void;

class TestSignalSource implements ShutdownSignalSource {
  private readonly listeners = new Map<ShutdownSignal, Set<SignalListener>>();

  on(signal: ShutdownSignal, listener: SignalListener): this {
    const listeners = this.listeners.get(signal) ?? new Set<SignalListener>();
    listeners.add(listener);
    this.listeners.set(signal, listeners);
    return this;
  }

  off(signal: ShutdownSignal, listener: SignalListener): this {
    this.listeners.get(signal)?.delete(listener);
    return this;
  }

  emit(signal: ShutdownSignal): void {
    for (const listener of this.listeners.get(signal) ?? []) listener();
  }

  listenerCount(): number {
    let total = 0;
    for (const listeners of this.listeners.values()) total += listeners.size;
    return total;
  }
}

test("SIGTERM marks unready and gracefully closes Fastify once", async () => {
  const events: string[] = [];
  let poolCloseCalls = 0;
  const database = fakeDatabaseHealth(async () => undefined, async () => {
    poolCloseCalls += 1;
    events.push("pool_close");
  });
  const application = createApp({ logLevel: "silent", database });
  const { server, lifecycle } = application;
  const signals = new TestSignalSource();
  let releaseDrain!: () => void;
  let markDrainStarted!: () => void;
  const drainGate = new Promise<void>((resolve) => { releaseDrain = resolve; });
  const drainStarted = new Promise<void>((resolve) => { markDrainStarted = resolve; });
  server.addHook("preClose", async () => {
    events.push("drain_started");
    markDrainStarted();
    await drainGate;
    events.push("drain_finished");
  });
  server.addHook("onClose", async () => {
    events.push("pool_cleanup_started");
    await database.close();
    events.push("pool_cleanup_finished");
  });

  try {
    await server.ready();
    lifecycle.markReady();
    assert.equal(lifecycle.isReady(), true);

    const shutdown = registerShutdownHandlers({ lifecycle, server, signalSource: signals });
    assert.equal(signals.listenerCount(), 2);

    signals.emit("SIGTERM");
    assert.equal(lifecycle.isReady(), false);
    signals.emit("SIGINT");

    await drainStarted;
    assert.equal(poolCloseCalls, 0);
    assert.deepEqual(events, ["drain_started"]);
    releaseDrain();
    await shutdown.waitForShutdown();

    assert.equal(poolCloseCalls, 1);
    assert.deepEqual(events, ["drain_started", "drain_finished", "pool_cleanup_started", "pool_close", "pool_cleanup_finished"]);
    assert.equal(signals.listenerCount(), 0);
  } finally {
    releaseDrain();
    await server.close().catch(() => undefined);
  }
});
