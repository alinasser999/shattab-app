import assert from "node:assert/strict";
import { createHmac, createHash } from "node:crypto";
import { test } from "node:test";

import {
  PUBLIC_CACHE_CONTROL,
  canonicalQueryString,
  numberEnv,
  presignPut,
  toAmzDate,
} from "../src/index.ts";

/**
 * The signing path is the part of this Worker that fails as an opaque
 * `SignatureDoesNotMatch` in production, so it is checked against a canonical
 * request written out by hand below and signed with `node:crypto` — a
 * different implementation from the WebCrypto calls in `src/index.ts`. If both
 * the canonicalisation and the HMAC chain agree with an independently written
 * reference, the remaining risk is R2 disagreeing with the AWS spec, which
 * only a live smoke test can settle.
 */

const ACCESS_KEY = "AKIAEXAMPLEEXAMPLE";
const SECRET_KEY = "wJalrXUtnFEMI-EXAMPLE-KEY";
const ACCOUNT_ID = "acct123";
const BUCKET = "shattab-public-media";
const HOST = `${ACCOUNT_ID}.r2.cloudflarestorage.com`;
const OBJECT_KEY = "public/post-media/11111111-1111-1111-1111-111111111111/a.jpg";
const CONTENT_TYPE = "image/jpeg";
const CONTENT_LENGTH = 48213;
const FIXED_NOW = new Date("2026-08-09T01:45:30.123Z");

// Only the fields presignPut reads. The R2 binding is never touched here.
const env = {
  R2_ACCOUNT_ID: ACCOUNT_ID,
  R2_BUCKET_NAME: BUCKET,
  R2_ACCESS_KEY_ID: ACCESS_KEY,
  R2_SECRET_ACCESS_KEY: SECRET_KEY,
  R2_PRESIGN_TTL_SECONDS: "900",
} as unknown as Parameters<typeof presignPut>[0];

function referenceSignature(): string {
  const amzDate = "20260809T014530Z";
  const dateStamp = "20260809";
  const scope = `${dateStamp}/auto/s3/aws4_request`;

  // Written out literally rather than rebuilt from the source's helpers, so a
  // change to the ordering or the signed-header list fails this test.
  const canonicalQuery = [
    "X-Amz-Algorithm=AWS4-HMAC-SHA256",
    "X-Amz-Content-Sha256=UNSIGNED-PAYLOAD",
    `X-Amz-Credential=${ACCESS_KEY}%2F20260809%2Fauto%2Fs3%2Faws4_request`,
    `X-Amz-Date=${amzDate}`,
    "X-Amz-Expires=900",
    "X-Amz-SignedHeaders=cache-control%3Bcontent-length%3Bcontent-type%3Bhost",
  ].join("&");

  const canonicalRequest = [
    "PUT",
    `/${BUCKET}/${OBJECT_KEY}`,
    canonicalQuery,
    `cache-control:${PUBLIC_CACHE_CONTROL}`,
    `content-length:${CONTENT_LENGTH}`,
    `content-type:${CONTENT_TYPE}`,
    `host:${HOST}`,
    "",
    "cache-control;content-length;content-type;host",
    "UNSIGNED-PAYLOAD",
  ].join("\n");

  const stringToSign = [
    "AWS4-HMAC-SHA256",
    amzDate,
    scope,
    createHash("sha256").update(canonicalRequest).digest("hex"),
  ].join("\n");

  const dateKey = createHmac("sha256", `AWS4${SECRET_KEY}`).update(dateStamp).digest();
  const regionKey = createHmac("sha256", dateKey).update("auto").digest();
  const serviceKey = createHmac("sha256", regionKey).update("s3").digest();
  const signingKey = createHmac("sha256", serviceKey).update("aws4_request").digest();
  return createHmac("sha256", signingKey).update(stringToSign).digest("hex");
}

test("the presigned signature matches an independent SigV4 reference", async () => {
  const url = new URL(
    await presignPut(env, OBJECT_KEY, CONTENT_TYPE, CONTENT_LENGTH, FIXED_NOW),
  );
  assert.equal(
    url.searchParams.get("X-Amz-Signature"),
    referenceSignature(),
    "canonical request or HMAC chain diverged from the AWS SigV4 spec",
  );
});

test("the upload size is signed, so R2 rejects a larger body", async () => {
  const signed = await presignPut(
    env,
    OBJECT_KEY,
    CONTENT_TYPE,
    CONTENT_LENGTH,
    FIXED_NOW,
  );
  const tampered = await presignPut(
    env,
    OBJECT_KEY,
    CONTENT_TYPE,
    CONTENT_LENGTH + 1,
    FIXED_NOW,
  );
  assert.equal(
    new URL(signed).searchParams.get("X-Amz-SignedHeaders"),
    "cache-control;content-length;content-type;host",
  );
  assert.notEqual(
    new URL(signed).searchParams.get("X-Amz-Signature"),
    new URL(tampered).searchParams.get("X-Amz-Signature"),
    "content-length must be inside the signature, not merely validated",
  );
});

test("cache-control is signed so uploads cannot opt out of CDN caching", async () => {
  const url = await presignPut(env, OBJECT_KEY, CONTENT_TYPE, CONTENT_LENGTH, FIXED_NOW);
  assert.match(
    new URL(url).searchParams.get("X-Amz-SignedHeaders") ?? "",
    /(^|;)cache-control(;|$)/,
  );
  assert.equal(PUBLIC_CACHE_CONTROL, "public, max-age=31536000, immutable");
});

test("the presigned URL is path-style against the account endpoint", async () => {
  const url = new URL(
    await presignPut(env, OBJECT_KEY, CONTENT_TYPE, CONTENT_LENGTH, FIXED_NOW),
  );
  assert.equal(url.host, HOST);
  assert.equal(url.pathname, `/${BUCKET}/${OBJECT_KEY}`);
});

test("expiry is clamped to at most fifteen minutes", async () => {
  const long = { ...env, R2_PRESIGN_TTL_SECONDS: "86400" } as typeof env;
  const short = { ...env, R2_PRESIGN_TTL_SECONDS: "1" } as typeof env;
  const expiresOf = async (candidate: typeof env) =>
    new URL(
      await presignPut(candidate, OBJECT_KEY, CONTENT_TYPE, CONTENT_LENGTH, FIXED_NOW),
    ).searchParams.get("X-Amz-Expires");

  assert.equal(await expiresOf(long), "900");
  assert.equal(await expiresOf(short), "60");
});

test("signing refuses to run when R2 credentials are absent", async () => {
  const unset = { ...env, R2_SECRET_ACCESS_KEY: "" } as typeof env;
  await assert.rejects(
    () => presignPut(unset, OBJECT_KEY, CONTENT_TYPE, CONTENT_LENGTH, FIXED_NOW),
    /R2 signing is not configured/,
  );
});

test("query parameters sort by code point, not by locale", () => {
  // `-` is ignorable punctuation under some locale collations, which reorders
  // these two against the server's byte-order sort.
  assert.equal(
    canonicalQueryString({ "X-AmzDate": "b", "X-Amz-Date": "a" }),
    "X-Amz-Date=a&X-AmzDate=b",
  );
  // Uppercase precedes lowercase in code point order.
  assert.equal(canonicalQueryString({ a: "1", B: "2" }), "B=2&a=1");
});

test("amz dates use the basic UTC format", () => {
  assert.equal(toAmzDate(FIXED_NOW), "20260809T014530Z");
});

test("a blank env var falls back instead of collapsing to zero", () => {
  // Number("") is 0, which would silently reject every upload as too large.
  assert.equal(numberEnv("", 10), 10);
  assert.equal(numberEnv("   ", 10), 10);
  assert.equal(numberEnv(undefined, 10), 10);
  assert.equal(numberEnv("not-a-number", 10), 10);
  assert.equal(numberEnv("25", 10), 25);
});
