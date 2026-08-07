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

4. Configure `ALLOWED_ORIGINS` with the real Flutter Web origin(s).
5. Configure the R2 bucket CORS policy using `r2-cors.example.json`. Worker
   CORS protects the signer; bucket CORS protects the browser's direct PUT.
6. Run `npm run typecheck`, `npm test`, and `npm run deploy:dry`.
7. Deploy only after the authenticated upload, delete, and purge flows have
   been tested against a non-production bucket.

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
