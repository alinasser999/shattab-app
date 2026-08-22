import assert from "node:assert/strict";
import { test } from "node:test";

import {
  PUBLIC_CATEGORIES,
  isOwnedPublicKey,
  isPublicCategory,
} from "../src/index.ts";

test("the public allowlist matches the client's copy exactly", () => {
  // Mirrored by `MediaCategory.canUsePublicR2` in the Flutter app, which has
  // the same literal list in its own test. Widening one side alone breaks a
  // build rather than silently making a private category public.
  assert.deepEqual([...PUBLIC_CATEGORIES].sort(), [
    "avatars",
    "contractor-logos",
    "portfolio-photos",
    "post-media",
  ]);
});

test("keeps private categories outside the public R2 allowlist", () => {
  assert.equal(isPublicCategory("avatars"), true);
  assert.equal(isPublicCategory("portfolio-photos"), true);
  assert.equal(isPublicCategory("verification-docs"), false);
  assert.equal(isPublicCategory("payment-proofs"), false);
  assert.equal(isPublicCategory("brief-photos"), false);
});

test("only the authenticated user's public namespace is deletable", () => {
  assert.equal(
    isOwnedPublicKey("public/post-media/user-1/object.jpg", "user-1"),
    true,
  );
  assert.equal(
    isOwnedPublicKey("public/post-media/user-2/object.jpg", "user-1"),
    false,
  );
  assert.equal(
    isOwnedPublicKey("private/payment-proofs/user-1/object.jpg", "user-1"),
    false,
  );
});
