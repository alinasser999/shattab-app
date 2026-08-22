# Shattab Media Signer

This Worker is the only component allowed to know the R2 S3 credentials. The
Flutter app authenticates with Supabase as usual, then sends its Supabase access
token here to request a short-lived upload URL.

The Worker verifies the token through Supabase Auth. It does not use a
service-role key, trust a client-provided user id, or expose R2 credentials.

## Setup

1. Create the R2 bucket and a public custom domain for approved public media.
2. Replace the non-secret placeholders in `wrangler.toml`.
3. Add secrets without committing them:

```powershell
wrangler secret put SUPABASE_ANON_KEY
wrangler secret put R2_ACCESS_KEY_ID
wrangler secret put R2_SECRET_ACCESS_KEY
```

4. Configure `ALLOWED_ORIGINS` with the real Flutter Web origin(s). Mobile
   builds send no `Origin` header and are unaffected; a web build with a
   missing origin fails at preflight with an error that never says "CORS".
5. Configure the R2 bucket CORS policy using `r2-cors.example.json`. Worker
   CORS protects the signer; bucket CORS protects the browser's direct PUT.
   `Content-Length` and `Cache-Control` must be allowed — both are signed.
6. Abort incomplete multipart uploads, which otherwise accumulate invisibly
   and are billed:

```powershell
wrangler r2 bucket lifecycle add shattab-public-media abort-stale-multipart "" --abort-multipart-days 1
```

7. Run `npm run typecheck`, `npm test`, and `npm run deploy:dry`.
8. Deploy only after the authenticated upload, delete, and purge flows have
   been tested against a non-production bucket. `npm test` verifies the SigV4
   signature against an independent reference implementation, but only a live
   PUT proves R2 agrees.

The Worker is not considered configured merely because this source compiles.
The Flutter app intentionally keeps R2 disabled until the deployed Worker,
public hostname, CORS policy, and secrets have all passed the smoke test.
Enable only the public categories that have been explicitly reviewed; private
verification and payment media never use this Worker.

## Endpoints

- `GET /health`
- `POST /v1/media/upload-url`
- `POST /v1/media/finalize`
- `POST /v1/media/delete`
- `POST /v1/media/purge-user`

Only these public categories are accepted:

- `avatars`
- `contractor-logos`
- `post-media`
- `portfolio-photos`

Verification documents, payment proofs, and brief photos are not accepted by
this Worker. They remain on the existing Supabase Storage path until their
privacy model is explicitly reviewed.

The list above is duplicated in the Flutter app as
`MediaCategory.canUsePublicR2`. A Worker and a Flutter app cannot share a
constant, so both copies are pinned by tests — `test/validation.test.ts` here
and `test/core/media/media_storage_test.dart` there. Adding a category to one
side alone fails a build rather than quietly making something public.

## Upload contract

`POST /v1/media/upload-url` returns a presigned PUT plus the exact headers the
client must send:

```json
{
  "object_key": "public/post-media/11111111-1111-1111-1111-111111111111/a.jpg",
  "upload_url": "https://<account>.r2.cloudflarestorage.com/...",
  "public_url": "https://media.example.com/public/post-media/...",
  "headers": {
    "Content-Type": "image/jpeg",
    "Content-Length": "48213",
    "Cache-Control": "public, max-age=31536000, immutable"
  }
}
```

All three are **signed headers**. Sending a different value produces
`SignatureDoesNotMatch` from R2 rather than a stored object. That is deliberate:

- `Content-Length` in the signature is what makes the size limit real. Without
  it a presigned URL is a bearer token good for any body up to R2's 5 GiB
  single-object limit, no matter what size the caller declared when asking for
  the URL.
- `Cache-Control` in the signature stops a client uploading media marked
  `no-store` and handing us the egress bill. Object keys embed a UUID and are
  never rewritten, so a stored object is immutable and safe to cache for a year.

## Known ceiling: orphaned objects

An object is written by the client's PUT, not by this Worker, so a client that
takes an upload URL, PUTs, and never calls `/finalize` leaves an object nobody
references. Each is capped at `MAX_UPLOAD_BYTES` and requires a valid Supabase
session, so the exposure is bounded, but it is not zero and there is no sweep.

A lifecycle expiry cannot fix this: objects under `public/` are
indistinguishable from live media, so any expiry rule would delete real photos.
Closing it properly means presigning into a `staging/` prefix and having
`/finalize` stream the object into `public/`, which then makes a `staging/`
expiry safe. That refactor is not done. Add it if abandoned uploads show up in
the R2 metrics.
