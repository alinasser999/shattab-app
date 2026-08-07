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

const PUBLIC_CATEGORIES = new Set([
  "avatars",
  "contractor-logos",
  "post-media",
  "portfolio-photos",
]);

const IMAGE_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);
const DEFAULT_MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const DEFAULT_PRESIGN_TTL_SECONDS = 15 * 60;

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

  const extension = extensionFor(fileName, contentType);
  const objectKey = `public/${category}/${userId}/${crypto.randomUUID()}${extension}`;
  const uploadUrl = await presignPut(env, objectKey, contentType);
  return {
    ok: true,
    object_key: objectKey,
    upload_url: uploadUrl,
    public_url: joinPublicUrl(env.R2_PUBLIC_BASE_URL, objectKey),
    headers: { "Content-Type": contentType },
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
      for (const object of page.objects) {
        await env.R2_MEDIA_BUCKET.delete(object.key);
        deleted += 1;
      }
      cursor = page.truncated ? page.cursor : undefined;
    } while (cursor);
  }
  return { ok: true, deleted };
}

async function presignPut(
  env: Env,
  objectKey: string,
  contentType: string,
): Promise<string> {
  const accessKey = env.R2_ACCESS_KEY_ID;
  const secretKey = env.R2_SECRET_ACCESS_KEY;
  if (!accessKey || !secretKey || !env.R2_ACCOUNT_ID || !env.R2_BUCKET_NAME) {
    throw new HttpError(503, "r2_not_configured", "R2 signing is not configured");
  }

  const endpoint = `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
  const host = new URL(endpoint).host;
  const now = new Date();
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
  const params: Record<string, string> = {
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": `${accessKey}/${credentialScope}`,
    "X-Amz-Date": amzDate,
    "X-Amz-Expires": String(expires),
    "X-Amz-Content-Sha256": "UNSIGNED-PAYLOAD",
    "X-Amz-SignedHeaders": "content-type;host",
  };
  const canonicalQuery = canonicalQueryString(params);
  const canonicalHeaders = `content-type:${contentType}\nhost:${host}\n`;
  const canonicalRequest = [
    "PUT",
    canonicalUri,
    canonicalQuery,
    canonicalHeaders,
    "content-type;host",
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

function numberEnv(value: string | undefined, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function rfc3986(value: string): string {
  return encodeURIComponent(value).replace(/[!'()*]/g, (character) =>
    `%${character.charCodeAt(0).toString(16).toUpperCase()}`,
  );
}

function canonicalQueryString(params: Record<string, string>): string {
  return Object.entries(params)
    .map(([key, value]) => [rfc3986(key), rfc3986(value)] as const)
    .sort(([aKey, aValue], [bKey, bValue]) =>
      aKey === bKey ? aValue.localeCompare(bValue) : aKey.localeCompare(bKey),
    )
    .map(([key, value]) => `${key}=${value}`)
    .join("&");
}

function toAmzDate(date: Date): string {
  return date.toISOString().replace(/[-:]|\.\d{3}/g, "").replace("Z", "Z");
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
