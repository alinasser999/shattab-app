import assert from "node:assert/strict";
import { createSign, generateKeyPairSync } from "node:crypto";
import { test } from "node:test";

import { CognitoJwtVerifier } from "aws-jwt-verify";
import { FetchError } from "aws-jwt-verify/error";
import type { Fetcher } from "aws-jwt-verify/https";
import { SimpleJwksCache } from "aws-jwt-verify/jwk";

import {
  createCognitoAccessTokenPreHandler,
  createCognitoAccessTokenVerifier,
  decorateConsumerSub,
  type CognitoAccessTokenVerifier,
} from "../src/auth/cognito.js";
import { createApp } from "../src/app.js";
import { fakeDatabaseHealth, LogCapture } from "./helpers.js";

const USER_POOL_ID = "us-west-2_ShattabQaPool123";
const CLIENT_ID = "shattab-qa-client";
const KID = "shattab-local-qa-key";
const ISSUER = `https://cognito-idp.us-west-2.amazonaws.com/${USER_POOL_ID}`;
const SUBJECT = "cognito-qa-subject-7a1f";

const localSigningKeyPair = generateKeyPairSync("rsa", { modulusLength: 2048 });
const wrongSigningKeyPair = generateKeyPairSync("rsa", { modulusLength: 2048 });
const publicJwk = localSigningKeyPair.publicKey.export({ format: "jwk" });
const localJwks = {
  keys: [{
    kty: "RSA",
    n: publicJwk.n!,
    e: publicJwk.e!,
    kid: KID,
    alg: "RS256",
    use: "sig",
  }],
};

function encodeBase64Url(value: string): string {
  return Buffer.from(value, "utf8").toString("base64url");
}

function createToken(
  claims: Record<string, unknown> = {},
  signingKey = localSigningKeyPair.privateKey,
  kid = KID,
): string {
  const now = Math.floor(Date.now() / 1000);
  const header = encodeBase64Url(JSON.stringify({ alg: "RS256", kid }));
  const payload = encodeBase64Url(JSON.stringify({
    iss: ISSUER,
    sub: SUBJECT,
    client_id: CLIENT_ID,
    token_use: "access",
    iat: now,
    exp: now + 300,
    ...claims,
  }));
  const signingInput = `${header}.${payload}`;
  const signer = createSign("RSA-SHA256");
  signer.update(signingInput);
  signer.end();
  return `${signingInput}.${signer.sign(signingKey).toString("base64url")}`;
}

function asArrayBuffer(value: string): ArrayBuffer {
  const bytes = new TextEncoder().encode(value);
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
}

function localJwksFetcher(
  jwks: unknown = localJwks,
  requestedUris: string[] = [],
): Fetcher {
  return {
    async fetch(uri: string): Promise<ArrayBuffer> {
      requestedUris.push(uri);
      return asArrayBuffer(JSON.stringify(jwks));
    },
  };
}

function createVerifierWithLocalFetcher(fetcher: Fetcher): CognitoAccessTokenVerifier {
  // aws-jwt-verify documents a second create() argument for a custom JwksCache.
  // Supply it only while the production factory constructs its verifier, then restore the SDK method.
  const mutableCognitoVerifier = CognitoJwtVerifier as unknown as {
    create: (...args: any[]) => any;
  };
  const originalCreate = mutableCognitoVerifier.create;
  mutableCognitoVerifier.create = function (properties: unknown): unknown {
    return originalCreate.call(CognitoJwtVerifier, properties, {
      jwksCache: new SimpleJwksCache({ fetcher }),
    });
  };

  try {
    return createCognitoAccessTokenVerifier({ userPoolId: USER_POOL_ID, clientId: CLIENT_ID });
  } finally {
    mutableCognitoVerifier.create = originalCreate;
  }
}

function createTestServer(verifier: CognitoAccessTokenVerifier) {
  const capture = new LogCapture();
  const application = createApp({
    database: fakeDatabaseHealth(),
    logLevel: "error",
    loggerStream: capture,
  });
  const { server } = application;

  decorateConsumerSub(server);
  const preHandler = createCognitoAccessTokenPreHandler(verifier);
  server.get("/protected", { preHandler }, async (request) => ({ sub: request.consumerSub }));
  server.get("/snapshot", async (request) => ({ sub: request.consumerSub }));

  return { server, lifecycle: application.lifecycle, capture };
}

function assertNoLeak(body: string, logs: string, ...sensitiveValues: string[]): void {
  for (const value of sensitiveValues) {
    assert.equal(body.includes(value), false, `response exposed sensitive value ${value}`);
    assert.equal(logs.includes(value), false, `logs exposed sensitive value ${value}`);
  }
}

function assertEventLogged(logs: string, eventName: string): void {
  const records = logs.trim().split(/\r?\n/).filter(Boolean).map((line) => JSON.parse(line) as Record<string, unknown>);
  assert.equal(records.some((record) => record.event === eventName), true, `missing log event ${eventName}`);
}

test("accepts a locally signed access token, exposes only sub, and isolates requests", async () => {
  const requestedUris: string[] = [];
  const verifier = createVerifierWithLocalFetcher(localJwksFetcher(localJwks, requestedUris));
  const { server, capture } = createTestServer(verifier);
  const token = createToken({ email: "must-not-be-forwarded@example.invalid", role: "must-not-be-forwarded" });

  try {
    await server.ready();
    const accepted = await server.inject({
      method: "GET",
      url: "/protected",
      headers: { authorization: `Bearer ${token}` },
    });
    assert.equal(accepted.statusCode, 200);
    assert.deepEqual(accepted.json(), { sub: SUBJECT });
    assert.equal(requestedUris.length, 1);
    assert.equal(requestedUris[0]?.startsWith("https://cognito-idp.us-west-2.amazonaws.com/"), true);

    const nextRequest = await server.inject({ method: "GET", url: "/snapshot" });
    assert.equal(nextRequest.statusCode, 200);
    assert.deepEqual(nextRequest.json(), { sub: null });
    assertNoLeak(accepted.body, capture.text, token, "must-not-be-forwarded@example.invalid", "must-not-be-forwarded");
  } finally {
    await server.close();
    capture.end();
  }
});

test("rejects absent and malformed Bearer headers with a challenge before calling the verifier", async () => {
  let verifyCalls = 0;
  const verifier: CognitoAccessTokenVerifier = {
    async verify() {
      verifyCalls += 1;
      return { sub: SUBJECT };
    },
  };
  const { server, capture } = createTestServer(verifier);
  const badHeaders: Array<string | undefined> = [
    undefined,
    "Basic opaque-credential-sentinel",
    "Bearer",
    "Bearer token extra",
    "Bearer token,other",
  ];

  try {
    await server.ready();
    for (const authorization of badHeaders) {
      const response = await server.inject({
        method: "GET",
        url: "/protected",
        headers: authorization === undefined ? {} : { authorization },
      });
      assert.equal(response.statusCode, 401);
      assert.equal(response.headers["www-authenticate"], "Bearer");
      assert.deepEqual(response.json(), { status: "unauthorized" });
      assertNoLeak(response.body, capture.text, "opaque-credential-sentinel");
    }
    assert.equal(verifyCalls, 0);
  } finally {
    await server.close();
    capture.end();
  }
});

test("rejects invalid Cognito verifier configuration synchronously at construction", async (t) => {
  const invalidConfigurations = [
    {
      name: "blank clientId",
      options: { userPoolId: USER_POOL_ID, clientId: " \t " },
    },
    {
      name: "empty userPoolId",
      options: { userPoolId: "", clientId: CLIENT_ID },
    },
    {
      name: "malformed userPoolId",
      options: { userPoolId: "not-a-cognito-user-pool-id", clientId: CLIENT_ID },
    },
  ];

  for (const scenario of invalidConfigurations) {
    await t.test(scenario.name, () => {
      assert.throws(() => createCognitoAccessTokenVerifier(scenario.options));
    });
  }
});

test("rejects expired, wrong-use, wrong-client, wrong-issuer, and wrongly signed tokens", async (t) => {
  const now = Math.floor(Date.now() / 1000);
  const invalidCases = [
    { name: "expired", token: createToken({ exp: now - 60, iat: now - 600 }) },
    { name: "wrong token_use", token: createToken({ token_use: "id", aud: CLIENT_ID }) },
    { name: "wrong client_id", token: createToken({ client_id: "other-client-sentinel" }) },
    {
      name: "wrong issuer",
      token: createToken({ iss: "https://cognito-idp.us-west-2.amazonaws.com/us-west-2_OtherPool987" }),
    },
    { name: "missing issuer", token: createToken({ iss: undefined }) },
    { name: "wrong signature", token: createToken({}, wrongSigningKeyPair.privateKey) },
  ];

  for (const invalidCase of invalidCases) {
    await t.test(invalidCase.name, async () => {
      const verifier = createVerifierWithLocalFetcher(localJwksFetcher());
      const { server, capture } = createTestServer(verifier);

      try {
        await server.ready();
        const response = await server.inject({
          method: "GET",
          url: "/protected",
          headers: { authorization: `Bearer ${invalidCase.token}` },
        });
        assert.equal(response.statusCode, 401);
        assert.equal(response.headers["www-authenticate"], "Bearer");
        assert.deepEqual(response.json(), { status: "unauthorized" });
        assertNoLeak(response.body, capture.text, invalidCase.token, "other-client-sentinel");
      } finally {
        await server.close();
        capture.end();
      }
    });
  }
});

test("maps JWKS fetch and parse failures to safe 503 responses and fixed events", async (t) => {
  const cases: Array<{ name: string; fetcher: Fetcher; sentinel: string }> = [
    {
      name: "JWKS transport failure",
      fetcher: {
        async fetch(uri: string): Promise<ArrayBuffer> {
          throw new FetchError(uri, "jwks-fetch-exception-sentinel");
        },
      },
      sentinel: "jwks-fetch-exception-sentinel",
    },
    {
      name: "invalid JWKS response",
      fetcher: { async fetch(): Promise<ArrayBuffer> { return asArrayBuffer("not-json-jwks-sentinel"); } },
      sentinel: "not-json-jwks-sentinel",
    },
  ];

  for (const scenario of cases) {
    await t.test(scenario.name, async () => {
      const verifier = createVerifierWithLocalFetcher(scenario.fetcher);
      const { server, capture } = createTestServer(verifier);
      const token = createToken();

      try {
        await server.ready();
        const response = await server.inject({
          method: "GET",
          url: "/protected",
          headers: { authorization: `Bearer ${token}` },
        });
        assert.equal(response.statusCode, 503);
        assert.deepEqual(response.json(), { status: "unavailable" });
        assertEventLogged(capture.text, "cognito_jwks_unavailable");
        assertNoLeak(response.body, capture.text, token, scenario.sentinel);
      } finally {
        await server.close();
        capture.end();
      }
    });
  }
});

test("maps unknown verifier failures to safe 500 responses", async () => {
  const error = new Error("unknown-verifier-error-sentinel");
  const verifier: CognitoAccessTokenVerifier = {
    async verify() { throw error; },
  };
  const { server, capture } = createTestServer(verifier);
  const token = "opaque-token-secret-sentinel";

  try {
    await server.ready();
    const response = await server.inject({
      method: "GET",
      url: "/protected",
      headers: { authorization: `Bearer ${token}` },
    });
    assert.equal(response.statusCode, 500);
    assert.deepEqual(response.json(), { status: "error" });
    assertEventLogged(capture.text, "cognito_verification_failed");
    assertNoLeak(response.body, capture.text, token, error.message);
  } finally {
    await server.close();
    capture.end();
  }
});

test("keeps liveness and readiness public when the optional verifier is mounted on a separate route", async () => {
  const verifier: CognitoAccessTokenVerifier = { async verify() { return { sub: SUBJECT }; } };
  const { server, lifecycle, capture } = createTestServer(verifier);

  try {
    await server.ready();
    lifecycle.markReady();

    const live = await server.inject({ method: "GET", url: "/health/live" });
    const ready = await server.inject({ method: "GET", url: "/health/ready" });
    assert.equal(live.statusCode, 200);
    assert.deepEqual(live.json(), { status: "ok" });
    assert.equal(ready.statusCode, 200);
    assert.deepEqual(ready.json(), { status: "ready" });
  } finally {
    await server.close();
    capture.end();
  }
});
