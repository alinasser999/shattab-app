import assert from "node:assert/strict";
import { test } from "node:test";

import { createApp } from "../src/app.js";
import { fakeDatabaseHealth, LogCapture } from "./helpers.js";

test("request logs allowlist metadata and redact sensitive fields and headers", async () => {
  const capture = new LogCapture();
  const { server } = createApp({ logLevel: "info", loggerStream: capture, database: fakeDatabaseHealth() });
  const sentinels = [
    "authorization-value-sentinel",
    "cookie-value-sentinel",
    "set-cookie-value-sentinel",
    "api-key-value-sentinel",
    "auth-token-value-sentinel",
    "request-id-value-sentinel",
    "password-value-sentinel",
    "phone-value-sentinel",
    "token-value-sentinel",
    "secret-value-sentinel",
    "body-value-sentinel",
    "query-value-sentinel",
  ];

  try {
    await server.ready();
    server.log.info({
      password: sentinels[6],
      phone: sentinels[7],
      token: sentinels[8],
      secret: sentinels[9],
      profile: { password: "nested-password-value-sentinel" },
    }, "synthetic redaction probe");

    const response = await server.inject({
      method: "POST",
      url: `/health/live?private=${sentinels[11]}`,
      headers: {
        authorization: sentinels[0],
        cookie: sentinels[1],
        "set-cookie": sentinels[2],
        "x-api-key": sentinels[3],
        "x-auth-token": sentinels[4],
        "request-id": sentinels[5],
      },
      body: { private: sentinels[10] },
    });
    assert.equal(response.statusCode, 404);

    const output = capture.text;
    for (const sentinel of [...sentinels, "nested-password-value-sentinel"]) {
      assert.equal(output.includes(sentinel), false, `log output exposed ${sentinel}`);
    }

    const records = output.trim().split(/\r?\n/).map((line) => JSON.parse(line) as Record<string, unknown>);
    const probe = records.find((record) => record.msg === "synthetic redaction probe");
    assert.ok(probe);
    assert.equal(probe.password, "[REDACTED]");
    assert.equal(probe.phone, "[REDACTED]");
    assert.equal(probe.token, "[REDACTED]");
    assert.equal(probe.secret, "[REDACTED]");

    const requestRecord = records.find((record) => record.event === "request_completed");
    assert.ok(requestRecord);
    assert.equal(requestRecord.method, "POST");
    assert.equal(requestRecord.route, "unmatched");
    assert.equal(requestRecord.statusCode, 404);
    assert.equal("body" in requestRecord, false);
    assert.equal("query" in requestRecord, false);
  } finally {
    await server.close();
    capture.end();
  }
});
