-- Move the upload size limit to where it cannot be bypassed.
--
-- UploadPolicy.maxImageBytes (10 MiB) is enforced in the Flutter client only.
-- Anyone holding the anon key — which ships inside every copy of the app — can
-- call the storage API directly and ignore it. Every bucket had
-- file_size_limit = NULL and allowed_mime_types = NULL, so the storage service
-- accepted objects of any size and any declared type.
--
-- file_size_limit is the control that actually holds: the storage service
-- enforces it regardless of what the caller claims. allowed_mime_types checks
-- the *declared* content type, which a hostile client controls, so it is
-- hygiene rather than a security boundary — its real value is that Supabase
-- serves objects with their declared type, so pinning the set to images keeps a
-- stored object from ever being served as active content.
--
-- Safe to apply as-is: every upload path in the app already declares
-- 'image/jpeg' (verified across all 8 call sites). png and webp are included so
-- a future client that stops transcoding does not have to migrate the bucket
-- config first. These settings gate uploads only — existing objects stay
-- readable regardless of how they were stored.
--
-- The limit matches the client policy so the two agree: a user who hits the
-- server limit would already have been stopped by the client, and the server
-- catches everyone who skipped the client.

update storage.buckets
set file_size_limit  = 10485760,  -- 10 MiB, matches UploadPolicy.maxImageBytes
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id in (
  'avatars',
  'brief-photos',
  'contractor-covers',
  'contractor-logos',
  'portfolio-photos',
  'post-media',
  'payment-proofs',
  'verification-docs'
);
