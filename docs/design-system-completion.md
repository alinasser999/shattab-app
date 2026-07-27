# Design system consolidation — completion report

Companion to [`design-system-audit.md`](design-system-audit.md), which set out
what was wrong. This records what changed, what was deliberately left, and what
is still open.

Branch `feat/bottom-nav-redesign`, commits `87c2958..a919a31`.
**75 files, +5666 / −3575.** `flutter analyze` clean, 186 tests passing
(166 at the start of the work).

The brief was explicit: no new business features, no UX redesign, no
functional change. Architecture, consistency, scalability, perceived quality.

---

## 1. What was built

### Tokens

| Token | Replaces | Note |
|---|---|---|
| `BatshIconSize` | 128 literal `size:` values, 23 distinct | Seven sizes sat in the 12–18px band, optically identical but guaranteeing baseline misalignment wherever two appeared in a row |
| `BatshBorderWidth` | ~87 literals | `hairline` / `selected` / `strong`; the selected-state distinction already existed in `BatshChip` and was unnamed |
| `BatshShadows.level(n)` | ad-hoc elevation picks | Clamps 0–5 onto the named getters |

### Primitives

| Primitive | Replaces |
|---|---|
| `BatshSnack` | 33 hand-built `SnackBar`s, each choosing its own colour, duration and icon |
| `BatshBadge` | 10 private badge classes |
| `BatshDialog` | 6 canonical `AlertDialog` sites |
| `BatshSheet` | 9 raw `showModalBottomSheet` sites |
| `BatshSearchBar` | 2 copies of the same private `_SearchBar` |
| `BatshEmptyState` (reworked) | 20 call sites, previously message-optional |
| `BatshPostSkeleton`, `BatshHeroDetailSkeleton`, `BatshCommentsSkeleton` | 3 bare spinners over known layouts |

---

## 2. Defects found while consolidating

Consolidation is a good defect detector: putting two implementations side by
side forces a decision about which one was right, and the answer is often
"neither".

**Empty states were being used to report failures.** Five sites rendered an
error through `BatshEmptyState`, two of them showing an error icon inside a
primary-tinted "invitation" medallion. An error is not an absence; it says the
app could not find out, and it needs a retry rather than an invitation. Moved
to `BatshError`.

**Post detail hid itself while loading comments.** The comments query drove a
full-screen spinner, so a post that had already loaded stayed invisible until
its comments arrived. The error branch three lines below already did the right
thing — render the post with an empty list — and the loading branch now
matches it.

**Page transitions ignored reduced motion.** Twenty-seven widgets checked
`disableAnimations` before animating; all three page transitions did not. That
is the one motion a user cannot avoid by not scrolling. They now drop the
travel and keep the fade, because opacity is not what triggers vestibular
symptoms — translation and zoom are.

**Every reduced-motion check over-subscribed.** All 27 used
`MediaQuery.of(context).disableAnimations`, which depends on the whole
`MediaQueryData`. Those widgets rebuilt on every keyboard open, rotation,
text-scale change and brightness flip to re-read one boolean that had not
moved. Now `MediaQuery.disableAnimationsOf`.

**The discovery search bar's clear button was under-sized.** A
`GestureDetector` around a 20px icon with 4px padding — roughly a 28px target,
under the 48px minimum, with no tooltip. The other copy of the same widget used
`IconButton` and was correct. The shared primitive keeps the correct one.

**`BatshBadge.outline` documented a capability it did not have.** It claimed to
be the variant "for badges sitting on photography", but draws transparent with
`onSurfaceVariant` text, so a dark photo swallows it. That is why four sites had
hand-rolled scrims instead. Added `onImage`: a 60% black scrim with white text,
chosen so white still clears 4.5:1 after compositing over a blown-out white sky.

**Two implementations disagreed about "cancelled".** `brief_card` rendered it
one grey, `inbox` another. Settled as neutral, not danger: a cancelled brief is
over, not wrong, and a list of them in red reads as a wall of errors. `danger`
now means a decision that went against the user — declined, rejected, blocked.

**A contrast test caught a live bug on first run.** Neutral-outline badges were
rendering text at 1.62:1 because the border colour was being used as the
foreground.

---

## 3. What was deliberately not changed

Judgement calls, recorded so they are not re-litigated as oversights.

**Three "badges" that were not badges.** The audit counted thirteen; ten
migrated. `_CategoryChip` and `_RatingPill` both take an `onTap` — they are
controls, and folding them into a primitive that announces as non-interactive
would make working buttons read as inert to a screen reader. `_ProActivePill`
is a full-width banner with a title-sized line and its own icon column; only
its name suggested a badge.

**Seven spinners.** Submit buttons, the pagination footer, the photo viewer and
splash report *work in progress*, not content arriving into a known shape. A
skeleton there promises a layout that is not coming.

**No illustrations for empty states.** The audit lists "no illustration" as a
gap. There are no illustration assets, and generating SVG scenes to fill the
slot produces exactly the hand-drawn filler that reads as amateurish. A
well-treated icon medallion beats a fake illustration. This is an asset
commission, not a code change.

**Raw hex that is legitimate.** Eleven live inside `batsh_shadows.dart`, which
is where raw values belong; `0xFF4285F4` is Google's brand blue on a sign-in
button and is already commented as exempt. One real violation — the brand
terracotta hardcoded in a debug role-switcher — was fixed.

---

## 4. The six follow-ups — closed

All six items from the first draft of this report were completed. What they
turned into:

1. **69 raw curves → tokens.** In five flavours: `easeOut`, `easeOutCubic`,
   `easeOutQuad`, `elasticOut`, `easeOutBack`. Nobody picked quad over cubic on
   64 separate occasions. All three ease-outs resolve to `BatshMotion.easeOut`,
   which is a different cubic from `Curves.easeOut`, so every one of those
   sites had been decelerating slightly off-system.
2. **19 numeric radii → tokens.** Fifteen already matched a token exactly; the
   strays were 5, 11, 15 and 2. The 2 was the interesting one — it sits on a
   4×18 accent bar, where a radius of half the width means *fully round*. That
   is `brFull`, and a numeric mapping would have got it wrong in the direction
   that looks almost right.
3. **`BatshPressable` on the author affordances.** The avatar and name in both
   the post card and post detail were bare `GestureDetector`s: no feedback, and
   no button semantics, so the route to a contractor's profile was invisible to
   a screen reader. Also found the remove-photo control at a ~20px target for
   an action that destroys a photo; now ~40px with a label.
4. **`AvatarWithInitials` → `core/widgets`.** It lived in `features/discovery`
   and was imported by `briefs` and `explore` — and by nothing in discovery, so
   the package that owned it was the one package that never used it.
5. **One section header, and no `BatshAppBar`.** `discover_screen` had a
   private `_SectionHeader` while `BatshSectionHeader` sat in core with six
   callers. The header *primitive* was not built: `BatshScaffold` already is
   one, and the raw `Scaffold` screens that remain are shells, splash, the
   photo viewer, and `SliverAppBar` collapsing heroes that a fixed app bar
   cannot serve. A second header abstraction would have been ceremony.
6. **The three largest screens split.** `profile_screen` 1859 → 698,
   `contractor_showcase` 1267 → 585, `phone_entry_screen` 1216 → 299, via
   `part` files. `part` rather than new libraries because every one of those
   widgets is private to its screen; real files would have meant making them
   public to satisfy the compiler, turning an internal detail into API surface
   as a side effect of tidying.

### What is left

- `strings.dart` is 1369 lines. It is a flat string table, so length is not
  really the problem — but empty-state and error copy cannot be reviewed as a
  set while it is ordered by when each string happened to be added.
- `discover_screen` (883) and the contractor `post_detail_screen` (873) are the
  next largest, both well below the size that made the other three urgent.

---

## 5. Where the safety net is

`test/widgets/design_system_test.dart` — 20 tests. The load-bearing ones:

- every badge tone × emphasis pairing clears 4.5:1, with translucent
  backgrounds composited before measuring rather than read as alpha-free
  luminance;
- `BatshBadge` asserts it is *not* a button in the semantics tree, which is the
  line between it and `BatshChip`;
- page transitions drop travel and keep fade under reduced motion;
- `BatshEmptyState` announces title and message as one label, and `noResults`
  drops the brand tint that `nothingYet` uses to invite.

The transition test earned its place immediately: it caught the outer
`MediaQuery` being shadowed by `MaterialApp`'s own, then caught `find.byType`
picking up the outgoing route's Material transition instead of the incoming
page's. Both would have shipped as a passing test asserting nothing.
