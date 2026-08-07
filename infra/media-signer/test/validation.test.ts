import assert from "node:assert/strict";
import { test } from "node:test";

import { isOwnedPublicKey, isPublicCategory } from "../src/index.ts";

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
