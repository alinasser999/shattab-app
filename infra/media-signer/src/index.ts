/// <reference types="@cloudflare/workers-types" />

interface Env {
  R2_MEDIA_BUCKET: R2Bucket;
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  R2_ACCOUNT_ID: string;
  R2_BUCKET_NAME: string;
  R2_PUBLIC_BASE_URL: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  ALLOWED_ORIGINS?: string;
  MAX_UPLOAD_BYTES?: string;
  R2_PRESIGN_TTL_SECONDS?: string;
}

/**
 * The only categories that may ever reach a public bucket.
 *
 * Duplicated on the client as `MediaCategory.canUsePublicR2`, because a Worker
 * and a Flutter app cannot share a constant. Both sides are pinned by tests to
 * this exact list — `test/validation.test.ts` here and
 * `test/core/media/media_storage_test.dart` there — so a category added to one
 * side without the other fails a build instead of quietly widening what is
 * public.
 */
export const PUBLIC_CATEGORIES = new Set([
  "avatars",
  "contractor-logos",
  "post-media",
  "portfolio-photos",
]);

const IMAGE_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);
const DEFAULT_MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const DEFAULT_PRESIGN_TTL_SECONDS = 15 * 60;

/**
 * Object keys embed a UUID and are never rewritten, so a stored object is
 * immutable by construction and can be cached for a year. Without this header
 * the CDN in front of the bucket revalidates constantly, which defeats the
 * reason for moving media to R2. It is a signed header, so a client cannot
 * upload media marked `no-store` and quietly hand us the egress bill.
 */
export const PUBLIC_CACHE_CONTROL = "public, max-age=31536000, immutable";

export function isPublicCategory(category: string): boolean {
  return PUBLIC_CATEGORIES.has(category);
}

export function isOwnedPublicKey(objectKey: string, userId: string): boolean {
  const parts = objectKey.split("/");
  return (
    parts.length >= 4 &&
    parts[0] === "public" &&
    PUBLIC_CATEGORIES.has(parts[1]) &&
    parts[2] === userId
  );
}

class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      if (request.method === "OPTIONS") {
        return new Response(null, {
          status: 204,
          headers: corsHeaders(request, env),
        });
      }

      const url = new URL(request.url);
      if (request.method === "GET" && url.pathname === "/health") {
        return json({ ok: true }, 200, request, env);
      }

      if (request.method !== "POST") {
        throw new HttpError(405, "method_not_allowed", "Method not allowed");
      }

      const userId = await authenticate(request, env);
      switch (url.pathname) {
        case "/v1/media/upload-url":
          return json(
            await createUploadUrl(request, env, userId),
            200,
            request,
            env,
          );
        case "/v1/media/finalize":
          return json(
            await finalizeUpload(request, env, userId),
            200,
            request,
            env,
          );
        case "/v1/media/delete":
          return json(await deleteObject(request, env, userId), 200, request, env);
        case "/v1/media/purge-user":
          return json(await purgeUserMedia(env, userId), 200, request, env);
        default:
          throw new HttpError(404, "not_found", "Unknown media endpoint");
      }
    } catch (error) {
      if (error instanceof HttpError) {
        return json(
          { ok: false, code: error.code, message: error.message },
          error.status,
          request,
          env,
        );
      }
      console.error("media signer request failed", error);
      return json(
        { ok: false, code: "internal_error", message: "Media request failed" },
        500,
        request,
        env,
      );
    }
  },
};

async function authenticate(request: Request, env: Env): Promise<string> {
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    throw new HttpError(401, "not_authenticated", "Authentication required");
  }

  let response: Response;
  try {
    response = await fetch(`${env.SUPABASE_URL.replace(/\/$/, "")}/auth/v1/user`, {
      headers: {
        apikey: env.SUPABASE_ANON_KEY,
        Authorization: authorization,
      },
    });
  } catch {
    throw new HttpError(503, "auth_unavailable", "Authentication is unavailable");
  }

  if (!response.ok) {
    throw new HttpError(401, "invalid_session", "The session is not valid");
  }
  const user = (await response.json()) as { id?: unknown };
  if (typeof user.id !== "string" || user.id.length === 0) {
    throw new HttpError(401, "invalid_session", "The session has no user");
  }
  return user.id;
}

async function createUploadUrl(
  request: Request,
  env: Env,
  userId: string,
): Promise<Record<string, unknown>> {
  const body = await readJson(request);
  const category = requiredString(body.category, "category");
  const contentType = requiredString(body.content_type, "content_type");
  const fileName = requiredString(body.file_name, "file_name");
  const contentLength = Number(body.content_length);
  if (!isPublicCategory(category)) {
    throw new HttpError(403, "category_not_allowed", "This media category is not public");
  }
  if (!IMAGE_TYPES.has(contentType)) {
    throw new HttpError(415, "content_type_not_allowed", "Only common image types are allowed");
  }
  const maxBytes = numberEnv(env.MAX_UPLOAD_BYTES, DEFAULT_MAX_UPLOAD_BYTES);
  if (!Number.isSafeInteger(contentLength) || contentLength <= 0 || contentLength > maxBytes) {
    throw new HttpError(413, "file_too_large", "The image exceeds the upload limit");
  }

  // Known ceiling: the client writes the object, so an upload URL that is used
  // but never finalized leaves an orphan under `public/`. Each is capped at
  // MAX_UPLOAD_BYTES by the signed content-length and needs a valid session, so
  // it is bounded, not unbounded. A lifecycle expiry cannot clean it up here —
  // orphans are indistinguishable from live media at this prefix. Presigning
  // into `staging/` and having /finalize move the object is the fix if
  // abandoned uploads ever show up in the R2 metrics. See README.
  const extension = extensionFor(fileName, contentType);
  const objectKey = `public/${category}/${userId}/${crypto.randomUUID()}${extension}`;
  const uploadUrl = await presignPut(env, objectKey, contentType, contentLength);
  return {
    ok: true,
    object_key: objectKey,
    upload_url: uploadUrl,
    public_url: joinPublicUrl(env.R2_PUBLIC_BASE_URL, objectKey),
    // Every one of these is a signed header. The client must send all three
    // verbatim or R2 rejects the signature — that is what makes the size limit
    // real rather than advisory.
    headers: {
      "Content-Type": contentType,
      "Content-Length": String(contentLength),
      "Cache-Control": PUBLIC_CACHE_CONTROL,
    },
  };
}

async function deleteObject(
  request: Request,
  env: Env,
  userId: string,
): Promise<Record<string, unknown>> {
  const body = await readJson(request);
  const publicUrl = requiredString(body.public_url, "public_url");
  const objectKey = keyFromPublicUrl(publicUrl, env.R2_PUBLIC_BASE_URL);
  assertOwnedPublicKey(objectKey, userId);
  await env.R2_MEDIA_BUCKET.delete(objectKey);
  return { ok: true };
}

async function finalizeUpload(
  request: Request,
  env: Env,
  userId: string,
): Promise<Record<string, unknown>> {
  const body = await readJson(request);
  const objectKey = requiredString(body.object_key, "object_key");
  const requestedContentType = requiredString(body.content_type, "content_type");
  assertOwnedPublicKey(objectKey, userId);

  const object = await env.R2_MEDIA_BUCKET.head(objectKey);
  if (object === null) {
    throw new HttpError(404, "upload_missing", "The uploaded media was not found");
  }
  const maxBytes = numberEnv(env.MAX_UPLOAD_BYTES, DEFAULT_MAX_UPLOAD_BYTES);
  if (object.size > maxBytes) {
    await env.R2_MEDIA_BUCKET.delete(objectKey);
    throw new HttpError(413, "file_too_large", "The uploaded image exceeds the limit");
  }
  const storedContentType = object.httpMetadata?.contentType;
  if (storedContentType && storedContentType !== requestedContentType) {
    await env.R2_MEDIA_BUCKET.delete(objectKey);
    throw new HttpError(415, "content_type_mismatch", "The uploaded media type is invalid");
  }
  return {
    ok: true,
    object_key: objectKey,
    size: object.size,
    public_url: joinPublicUrl(env.R2_PUBLIC_BASE_URL, objectKey),
  };
}

async function purgeUserMedia(env: Env, userId: string): Promise<Record<string, unknown>> {
  let deleted = 0;
  for (const category of PUBLIC_CATEGORIES) {
    let cursor: string | undefined;
    do {
      const page = await env.R2_MEDIA_BUCKET.list({
        prefix: `public/${category}/${userId}/`,
        cursor,
        limit: 1000,
      });
      // One batched call per page rather than one round trip per object: a
      // contractor with a full portfolio can hold hundreds, and account
      // deletion must finish inside the Worker's CPU budget.
      if (page.objects.length > 0) {
        await env.R2_MEDIA_BUCKET.delete(page.objects.map((object) => object.key));
        deleted += page.objects.length;
      }
      cursor = page.truncated ? page.cursor : undefined;
    } while (cursor);
  }
  return { ok: true, deleted };
}

/**
 * Presigns a single PUT.
 *
 * `content-length` is signed, not merely validated above: a presigned URL is a
 * bearer capability, and without the size in the signature the caller may PUT
 * up to R2's 5 GiB single-object limit no matter what they declared when they
 * asked for the URL. Signing it makes R2 itself reject the mismatch, which is
 * the only enforcement point that does not depend on the client coming back to
 * call `/finalize`.
 *
 * `now` is injectable so the signature can be tested against a fixed vector.
 */
export async function presignPut(
  env: Env,
  objectKey: string,
  contentType: string,
  contentLength: number,
  now: Date = new Date(),
): Promise<string> {
  const accessKey = env.R2_ACCESS_KEY_ID;
  const secretKey = env.R2_SECRET_ACCESS_KEY;
  if (!accessKey || !secretKey || !env.R2_ACCOUNT_ID || !env.R2_BUCKET_NAME) {
    throw new HttpError(503, "r2_not_configured", "R2 signing is not configured");
  }

  const endpoint = `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
  const host = new URL(endpoint).host;
  const amzDate = toAmzDate(now);
  const dateStamp = amzDate.slice(0, 8);
  const region = "auto";
  const service = "s3";
  const expires = Math.min(
    Math.max(numberEnv(env.R2_PRESIGN_TTL_SECONDS, DEFAULT_PRESIGN_TTL_SECONDS), 60),
    900,
  );
  const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
  const canonicalUri = `/${rfc3986(env.R2_BUCKET_NAME)}/${objectKey
    .split("/")
    .map(rfc3986)
    .join("/")}`;
  // SigV4 requires canonical headers in lowercase byte order:
  // cache-control < content-length < content-type < host.
  const signedHeaders = "cache-control;content-length;content-type;host";
  const params: Record<string, string> = {
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": `${accessKey}/${credentialScope}`,
    "X-Amz-Date": amzDate,
    "X-Amz-Expires": String(expires),
    "X-Amz-Content-Sha256": "UNSIGNED-PAYLOAD",
    "X-Amz-SignedHeaders": signedHeaders,
  };
  const canonicalQuery = canonicalQueryString(params);
  const canonicalHeaders =
    `cache-control:${PUBLIC_CACHE_CONTROL}\n` +
    `content-length:${contentLength}\n` +
    `content-type:${contentType}\n` +
    `host:${host}\n`;
  const canonicalRequest = [
    "PUT",
    canonicalUri,
    canonicalQuery,
    canonicalHeaders,
    signedHeaders,
    "UNSIGNED-PAYLOAD",
  ].join("\n");
  const stringToSign = [
    "AWS4-HMAC-SHA256",
    amzDate,
    credentialScope,
    await sha256Hex(canonicalRequest),
  ].join("\n");
  const signingKey = await signingKeyFor(secretKey, dateStamp, region, service);
  const signature = await hmacHex(signingKey, stringToSign);
  params["X-Amz-Signature"] = signature;
  return `${endpoint}${canonicalUri}?${canonicalQueryString(params)}`;
}

function assertOwnedPublicKey(objectKey: string, userId: string): void {
  if (!isOwnedPublicKey(objectKey, userId)) {
    throw new HttpError(403, "object_not_owned", "This media object is not owned by the user");
  }
}

function keyFromPublicUrl(rawUrl: string, rawBaseUrl: string): string {
  let url: URL;
  let base: URL;
  try {
    url = new URL(rawUrl);
    base = new URL(rawBaseUrl);
  } catch {
    throw new HttpError(400, "invalid_public_url", "The media URL is invalid");
  }
  const basePath = base.pathname.replace(/\/+$/, "");
  if (url.origin !== base.origin || !url.pathname.startsWith(`${basePath}/`)) {
    throw new HttpError(403, "invalid_public_url", "The media URL is not managed by this service");
  }
  const key = decodeURIComponent(url.pathname.slice(`${basePath}/`.length));
  if (!key || key.includes("..")) {
    throw new HttpError(400, "invalid_object_key", "The media object key is invalid");
  }
  return key;
}

function joinPublicUrl(baseUrl: string, objectKey: string): string {
  return `${baseUrl.replace(/\/+$/, "")}/${objectKey
    .split("/")
    .map(rfc3986)
    .join("/")}`;
}

async function readJson(request: Request): Promise<Record<string, unknown>> {
  try {
    const value = (await request.json()) as unknown;
    if (typeof value !== "object" || value === null || Array.isArray(value)) {
      throw new Error("not an object");
    }
    return value as Record<string, unknown>;
  } catch {
    throw new HttpError(400, "invalid_json", "The request body is invalid");
  }
}

function requiredString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0 || value.length > 512) {
    throw new HttpError(400, `invalid_${field}`, `The ${field} field is invalid`);
  }
  return value.trim();
}

function extensionFor(_fileName: string, contentType: string): string {
  return contentType === "image/png" ? ".png" : contentType === "image/webp" ? ".webp" : ".jpg";
}

export function numberEnv(value: string | undefined, fallback: number): number {
  // `Number("")` is 0, not NaN. An unset-but-present var would otherwise make
  // MAX_UPLOAD_BYTES zero and reject every upload, so treat blank as absent.
  if (value === undefined || value.trim() === "") return fallback;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function rfc3986(value: string): string {
  return encodeURIComponent(value).replace(/[!'()*]/g, (character) =>
    `%${character.charCodeAt(0).toString(16).toUpperCase()}`,
  );
}

export function canonicalQueryString(params: Record<string, string>): string {
  // SigV4 sorts by code point, not by locale. `localeCompare` treats `-` as
  // ignorable punctuation in some locales, so it can order `X-Amz-Date` and a
  // hypothetical `X-AmzDate` differently from the way the server does — and a
  // signature that disagrees with the server fails as an opaque
  // SignatureDoesNotMatch. Plain `<`/`>` is the comparison the spec means.
  return Object.entries(params)
    .map(([key, value]) => [rfc3986(key), rfc3986(value)] as const)
    .sort(([aKey, aValue], [bKey, bValue]) => {
      if (aKey !== bKey) return aKey < bKey ? -1 : 1;
      if (aValue === bValue) return 0;
      return aValue < bValue ? -1 : 1;
    })
    .map(([key, value]) => `${key}=${value}`)
    .join("&");
}

export function toAmzDate(date: Date): string {
  return date.toISOString().replace(/[-:]|\.\d{3}/g, "");
}

async function sha256Hex(value: string): Promise<string> {
  return bytesToHex(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)));
}

async function hmacHex(key: ArrayBuffer, value: string): Promise<string> {
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    key,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return bytesToHex(await crypto.subtle.sign("HMAC", cryptoKey, new TextEncoder().encode(value)));
}

async function hmacBytes(key: ArrayBuffer | string, value: string): Promise<ArrayBuffer> {
  const rawKey = typeof key === "string" ? new TextEncoder().encode(key) : key;
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    rawKey,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return crypto.subtle.sign("HMAC", cryptoKey, new TextEncoder().encode(value));
}

async function signingKeyFor(
  secret: string,
  dateStamp: string,
  region: string,
  service: string,
): Promise<ArrayBuffer> {
  const dateKey = await hmacBytes(`AWS4${secret}`, dateStamp);
  const regionKey = await hmacBytes(dateKey, region);
  const serviceKey = await hmacBytes(regionKey, service);
  return hmacBytes(serviceKey, "aws4_request");
}

function bytesToHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function corsHeaders(request: Request, env: Env): Headers {
  const headers = new Headers({
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Max-Age": "600",
    Vary: "Origin",
  });
  const origin = request.headers.get("Origin");
  const allowed = (env.ALLOWED_ORIGINS ?? "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  if (origin && (allowed.includes(origin) || allowed.includes("*"))) {
    headers.set("Access-Control-Allow-Origin", origin);
  }
  return headers;
}

function json(
  body: unknown,
  status: number,
  request: Request,
  env: Env,
): Response {
  const headers = corsHeaders(request, env);
  headers.set("Content-Type", "application/json; charset=utf-8");
  return new Response(JSON.stringify(body), { status, headers });
}
