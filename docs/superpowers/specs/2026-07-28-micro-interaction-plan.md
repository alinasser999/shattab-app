# Shattab — Micro-interaction plan

**Date:** 2026-07-28
**Branch:** `feat/bottom-nav-redesign`
**Supersedes:** Phase 6 of `2026-07-28-premium-ui-craft-design.md`

---

## Why this replaces Phase 6

Phase 6 was written from screenshots. It proposed press states, haptics, hero
transitions, image fade-in and skeleton crossfades as if none existed.

Reading the code, most of it does:

| Phase 6 said "add" | Actually present |
|---|---|
| Press state on tappables | `BatshPressable` + `BatshCard`, 6 files |
| Haptics | 10 files — nav, buttons, every filter control |
| Hero transitions | 12 `Hero` widgets |
| Skeletons | 25 files |
| Reduced-motion guards | Honoured in `BatshPressable`, page transitions, list entrances |

Optimistic UI is real too: `toggleLike` / `toggleSave` patch the feed
immediately and roll back on failure.

So the work is not "add micro-interactions." It is **finish the ones already
started and fix the two that are actively wrong**. That is a much smaller, much
higher-confidence change set.

---

## Findings, ranked by user-visible impact

### 1. Every feed action icon renders 10% too small — BUG

`post_card.dart:430` and `post_detail_screen.dart:581`:

```dart
late final AnimationController _ctrl = AnimationController(
  vsync: this,
  duration: BatshMotion.fast,
  lowerBound: 0.9,
  upperBound: 1.0,
);          // <- no `value:`
```

`AnimationController.value` defaults to `lowerBound`. Every like, comment,
share and save icon in the feed and on post detail therefore renders at
**scale 0.9 from first paint** and only springs to full size after the first
tap — permanently, for icons the user never taps.

The whole action row sits slightly small against the padding around it. This is
precisely the class of defect that reads as "cheap" without being nameable.

**Fix:** `value: 1.0`.

### 2. The same two controllers ignore reduced motion

Every other animation in the app checks `MediaQuery.disableAnimationsOf`.
These two do not — the app's own rule, unenforced in the one place a user taps
most often.

**Fix:** guard the scale, pass the tap through untouched.

### 3. No image fades in — 0 of 26

Not one `CachedNetworkImage` in the app sets `fadeInDuration`. Every photo
hard-swaps from placeholder to image the instant it decodes.

In a category where the imagery *is* the product, this is the loudest cheap-app
tell in the build, and the fix is one parameter per call site.

**Fix:** a `BatshNetworkImage` wrapper carrying the fade plus the decode cap and
placeholder/error defaults currently copy-pasted across 26 call sites.

### 4. Like and save have no haptic

Haptics are wired into navigation and filters — the *navigational* actions.
They are absent from like and save, the two most emotionally meaningful taps in
the product.

`BatshButton` already has `hapticOnPress`. The feed's `_ActionButton` predates
it.

**Fix:** `HapticFeedback.lightImpact()` on like/save; selection click elsewhere.

### 5. Optimistic rollback is silent

```dart
} catch (_) {
  feed.patchPost(post); // rollback
}
```

On a failed like the heart fills, then quietly empties — identical to a tap that
never registered. On Egyptian mobile networks this will not be rare.

**Fix:** keep the rollback, surface a `BatshSnack.error`. The app already has the
component and already uses it for every other failed write.

### 6. Thirteen files tap without feedback

`GestureDetector` with no press state and no haptic, in: `app.dart`,
`batsh_card.dart`, `batsh_chip.dart`, `batsh_search_bar.dart`,
`phone_entry_login_card.dart`, `phone_entry_screen.dart`, `pro_screen.dart`,
`job_opportunities_screen.dart`, `post_detail_screen.dart`,
`create_post_screen.dart`, `company_profile_screen.dart`,
`edit_profile_screen.dart`, `homeowner_edit_profile_screen.dart`.

Some are legitimate — `app.dart` is a debug role switcher, and `batsh_card` /
`batsh_chip` implement their own feedback internally. The rest are real gaps.

**Fix:** audit each; route the genuine tappables through `BatshPressable`.

---

## What this plan does not do

- **No new animation vocabulary.** `BatshMotion` already defines the curves and
  durations. Anything added here uses them.
- **No hero transition work.** Twelve already exist; adding more is Phase 4's
  job, once the profile screen has content worth transitioning into.
- **No "delight" animations.** Confetti on quote-accepted and similar are the
  opposite of premium where someone is spending 200,000 EGP. Restraint is the
  signal.

---

## Order

1. Fix the two controllers (#1, #2) — a bug, minutes to fix
2. `BatshNetworkImage` + migrate the call sites (#3)
3. Haptics on like/save (#4)
4. Surface the rollback (#5)
5. Audit the thirteen (#6)

Items 1–4 are self-contained and low-risk. 5 needs judgement per file and can
follow.

## Done when

- No `AnimationController` with a `lowerBound` below 1.0 and no explicit `value`
- Every network image fades in, and no call site sets `memCacheWidth` by hand
- Like and save fire a haptic
- A failed like or save shows an error
- `flutter analyze` clean, suite green
