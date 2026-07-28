# Shattab — Premium UI Craft Plan

**Date:** 2026-07-28
**Branch:** `feat/bottom-nav-redesign`
**Goal:** Make Shattab feel hand-made, warm, and premium — not generic and static.

---

## 0. The reframe (read before anything else)

The brief was *"eliminate dead spaces."* That is half right, and acting on it
literally would make the app worse.

Premium products have **more** whitespace, not less. Airbnb, Houzz, and Apple's
own apps are generous with space. Cramming content into gaps is what budget
software looks like.

What is actually wrong is two different problems wearing the same costume:

| What it looks like | What it actually is | Fix |
|---|---|---|
| Loose, unstructured gaps between sections | **Rhythm failure** — spacing carries no meaning, so groups don't read as groups | Phase 2 (spatial semantics) |
| Profile screen ends after 3 buttons; huge void below | **Content starvation** — the screen ran out of things to say | Phase 4 + content backfill |

The second one cannot be fixed with layout. No amount of padding tuning makes a
profile with zero projects and zero reviews feel full. Layout can only arrange
what exists.

Meanwhile the *cards* have the opposite problem: 13 elements crammed into one
tile. So the app is simultaneously too dense (cards) and too sparse (screens).
That inversion is the core visual defect.

**Principle for this entire plan: subtract from cards, add to screens.**

---

## 1. What is already correct (do not regress)

Credit where it is due — these were done right and the plan preserves them:

- **Shadows are warm-tinted** with the terracotta primary (`0x__9E3D18`), not
  black. This is the correct premium technique; black shadows on a cream surface
  read muddy. Keep.
- **Body line-heights are Arabic-calibrated**: `bodyMd` 15/24 = 1.60,
  `bodySm` 13/22 = 1.69, `bodyLg` 17/26 = 1.53. Arabic needs more leading than
  Latin and this is right.
- **8pt spacing scale** exists and is coherent.
- **Token discipline** — no raw hex, no bare Material widgets, WCAG AA, 44dp
  targets, reduced-motion guards. Real work, keep all of it.

The problem is not the system. It is that the system was never pointed at a
decision about what matters on each screen.

---

## Phase 0 — Credibility bugs

**Why first:** these are actively destroying trust and they are cheap. No amount
of visual polish survives an app that contradicts itself.

### 0.1 The badge contradiction

Currently rendered together on one profile:

- `مستوى فضي` (silver tier — earned)
- `سجل أعمال طويل` — `strings.dart:419`
- `محترف جديد` — `strings.dart:1305`
- `٥٦ مشروع منجز` · `٨ سنين خبرة`

56 projects and 8 years, and *new*. Establish a single precedence rule and
render **exactly one** identity badge:

```
if (completedProjects >= 3 || tier > bronze) → tier badge only
else if (accountAgeDays <= 60)               → محترف جديد
else                                          → no identity badge
```

`سجل أعمال طويل` becomes a stat, not a badge (see 3.3).

**Acceptance:** no profile in the database can render two identity badges. Add a
unit test asserting mutual exclusion.

### 0.2 Two tabs with the same name

`tabDiscover = اكتشف` (`strings.dart:220`) and `tabExplore = استكشف`
(`strings.dart:229`) share a triliteral root and are adjacent in the bottom nav.
No user can distinguish them.

Rename: **Discover → `المحترفين`**, **Explore → `أعمال`**.

**Acceptance:** no two nav labels share a root.

### 0.3 Truncation audit

Observed truncating: the search placeholder itself, two contractor names, one
bio. A truncated placeholder is the clearest possible signal of unfinished work.

**Rule:** primary identity content (name, title, placeholder) never truncates.
Shorten the source string, reduce the type size, or allow two lines — never `…`.
Secondary content (bio) may truncate at exactly 2 lines with a `المزيد`
affordance.

**Acceptance:** screenshot pass over all 10 primary screens at 360dp width;
zero ellipses on any name, title, or placeholder.

### 0.4 Purge test data

`شركة اختبار الت…` is live in Discover. Remove all test accounts from
production, or filter them server-side.

### 0.5 Numeral policy

Pick one — Western (`56`) or Arabic-Indic (`٥٦`) — and apply everywhere
including prices, phone numbers, dates, and counts. **Recommendation: Western
digits**, which is the dominant convention in Egyptian apps and matches phone
number and EGP price formatting. Add a lint-style test.

---

## Phase 1 — Typography: warmth and depth

This is the "basic font" complaint, and there are **three separate defects**.

### 1.1 Negative letter-spacing on Arabic — the real bug

`lib/core/theme/batsh_typography.dart` applies negative tracking to every display
and headline style:

```
letterSpacing: -0.4   // displayLg
letterSpacing: -0.3   // displayMd, displayAccent
letterSpacing: -0.2
letterSpacing: -0.1
```

**Arabic is a connected cursive script.** Negative tracking compresses the joins
between letters, degrading the connection strokes that define the letterforms.
Tight tracking is a *Latin* display convention for large headlines; applied to
Arabic it makes type look cramped and subtly broken — exactly the "cheap"
feeling, and exactly the kind of thing a user can sense but not name.

**Fix:** all Arabic styles → `letterSpacing: 0`. Never negative. If a Latin
fallback path needs tightening, branch on script, do not apply globally.

*Confidence: high. This is settled practice in Arabic type-setting, not a matter
of taste.*

### 1.2 Display leading is Latin-calibrated

Body leading is correct (1.53–1.69). Display is not:

- `displayAccent` 34/44 = **1.29**
- `displayLg`-class 26/34 = **1.31**

Arabic ascenders, descenders, and dot clusters need more room than Latin even at
display sizes. **Fix: display leading floor of 1.40**, headline floor of 1.45.

### 1.3 Cairo + Tajawal — no voice contrast, maximum ubiquity

```dart
static const String _arabicDisplay = 'Cairo';
static const String _arabicBody    = 'Tajawal';
```

Two problems:

1. **Both are geometric sans.** There is no tonal difference between a heading
   and a paragraph — only size. Every premium editorial system gets its depth
   from voice contrast (NYT: Cheltenham serif + Franklin sans; Airbnb
   commissioned Cereal outright). You have one voice at six sizes.
2. **Cairo is the single most-used Arabic UI face on the internet** — the Roboto
   of Arabic, on every Egyptian startup and government portal. It is competent
   and completely anonymous. Tajawal is the same story. That is precisely why
   the app reads "template."

Also: `displayAccent` is Cairo at `w900`. Cairo's Black weight is notoriously
heavy and blobby at display sizes.

#### Options

| # | Display | Body | Character | Cost |
|---|---|---|---|---|
| **A (recommended)** | **Noto Naskh Arabic** | **IBM Plex Sans Arabic** | Calligraphic naskh display with real stroke modulation against a warm humanist body. Maximum voice contrast; the modulated stroke is what reads as "hand-made." Matches the Modern Heritage brand directly. | Free |
| B | **Almarai** ExtraBold | **IBM Plex Sans Arabic** | Safer, still much warmer than Cairo, less distinctive. Lower risk if naskh reads too traditional at UI sizes. | Free |
| C | **29LT Bukra** (two weights) | **29LT Bukra** | Genuinely warm humanist family, professionally drawn, used by serious Arabic brands. The strongest result, but a paid license, and a single-family system needs disciplined weight contrast. | Paid |

### DECIDED — Option B: Almarai + IBM Plex Sans Arabic

**Chosen 2026-07-28.** Naskh judged too traditional a voice for the brand.
Option B keeps a sans display but replaces the two monoline geometrics with a
pairing that has real contrast and warmth:

- **Display: Almarai** — ExtraBold (w800) / Bold (w700). Warmer and more
  characterful than Cairo, with better heavy weights (Cairo Black is blobby at
  display sizes).
- **Body: IBM Plex Sans Arabic** — true humanist with visible warmth, 7 weights,
  a clearly different voice from Almarai.

Because both faces are sans, **voice contrast must be earned through weight and
size discipline rather than through style**. That is a harder system to run, so
these rules are binding:

1. Display weights are w700/w800 only. Body weights are w400/w500/w600 only.
   **The ranges never overlap** — that separation is what makes the pairing read
   as two voices instead of one blurry one.
2. Minimum size jump between a heading and the body beneath it: **1.4×**.
3. Display colour is `onSurface`; body drops to `onSurfaceVariant`. Colour does
   part of the contrast work a style change would otherwise do.

**Still verify in the hand** before locking: render on the three real screens
(Discover, contractor card, profile) on a mid-tier Android in daylight. If the
pairing reads as one voice at arm's length, escalate to Option C (29LT Bukra)
rather than reverting to Cairo.

### 1.4 Type scale

Rebuild as a modular scale with a real top end. Current display tops out at 34;
there is no size for a genuine hero moment. Add `displayXl` (44/62) for the
profile name and empty-state headlines.

**Acceptance for Phase 1:** every `letterSpacing` in the theme is `0`; all
display/headline leading ≥ 1.40; a golden-image test for the three primary
screens.

---

## Phase 2 — Spatial semantics

Tokens exist. Rules do not. Space is being chosen per-call-site, so grouping is
ambiguous and the eye cannot tell what belongs to what.

### 2.1 Gestalt proximity levels

Define four semantic spacings and use *only* these between content:

| Level | Value | Use |
|---|---|---|
| `intra` | 4–8 | Inside one idea (name → subtitle) |
| `inter` | 12–16 | Between sibling items in a list |
| `group` | 24 | Between groups inside a section |
| `section` | 40–48 | Between sections |

**Rule:** adjacent levels must differ by ≥1.5× to be perceived as different. The
current `gutter`/`cardPadding` pair (20/16) fails this — they read as the same
space, which is why grouping is mushy.

### 2.2 Carousel edge treatment

The `الأعلى تقييمًا` carousel currently cuts the second card at an arbitrary
point. Specify an exact peek — **24dp of the next card visible** — so the cut
reads as intentional affordance rather than a clipping accident.

### 2.3 Section headers

The vertical accent bar beside section titles is a dated pattern that adds
chrome without meaning. Replace with typographic weight alone plus a
right-aligned action (`الكل ←`) where one exists.

### 2.4 Optical alignment

Circular avatars, icons, and Arabic text baselines need optical rather than
mathematical centering. Audit the badge/icon pairs in cards.

---

## Phase 3 — The contractor card: 13 elements → 6

Current card carries: cover photo, bookmark button, `جديد` badge, tier badge,
name overlay, floating circular avatar, bio line, 3 metadata chips, 3 specialty
chips, location line.

Airbnb's card carries five things. Restraint *is* the premium signal.

### 3.1 Keep

1. **Cover photo** — 4:3, ≥55% of card height, real project work
2. **Name** — `titleLg`, below the photo, never overlaid, never truncated
3. **Stat line** — set in type (see 3.3)
4. **Specialty** — maximum 2 chips + `+٣`
5. **Location** — `bodySm`, muted
6. **Tier badge** — one only, top-left of photo

### 3.2 Delete from the card

- Floating circular avatar (a generic icon placeholder — adds nothing)
- `جديد` badge (redundant with tier, and contradicts it)
- Metadata chips (become the stat line)
- Bookmark button (move to the profile screen; saving from a list is a
  low-intent action that costs a full element)
- Bio line (belongs on the profile, not the card)

### 3.3 Stats in type, not chips

Chips are for filters and taxonomy. Using them as a universal container is what
produces "component soup."

```
٥٦ مشروع  ·  ٨ سنين خبرة  ·  ٤٫٩ ★
```

Set in `labelLg` with middot separators and a muted color, the way Airbnb sets
`4.92 ★ · 128 reviews`. One line, no pills, no borders.

**Acceptance:** card renders ≤6 elements; photo ≥55% of card height.

---

## Phase 4 — The profile screen (the priority)

This is the screen the brief called "dead and static," and it is the most
important screen in the product — it is where hiring decisions happen.

Today: hero → name → 4 badges → one bio line → 3 buttons → **end**.

An Airbnb listing has 8+ sections and takes ~45 seconds to scroll. Every
scrolled section is a piece of evidence. Yours takes 3 seconds and offers none.

### 4.1 Target architecture

| # | Section | Notes |
|---|---|---|
| 1 | **Hero gallery** | Swipeable, real work photos, page indicator. Not one static stock image. |
| 2 | **Identity** | Name in `displayXl`, ONE tier badge, provider kind, location |
| 3 | **Stat row** | Projects · years · rating · typical response time — in type |
| 4 | **Bio** | 2 lines + `المزيد` |
| 5 | **الأعمال** | **Grid of completed projects.** This is the missing content. A contractor claiming 56 projects currently shows zero. |
| 6 | **التقييمات** | Rating distribution bars + 3 reviews + `عرض الكل` |
| 7 | **الثقة** | Verification status, service areas, specialties |
| 8 | **Sticky CTA bar** | See 4.2 |

### 4.2 Fix the call to action

Currently: a full-width WhatsApp-green (`#25D366`) button — the most saturated
element on screen, and it belongs to another company — plus two more CTAs of
near-equal weight. Three competing actions, no primary.

**Fix:**
- **One primary**: `ابعت تفاصيل مشروعك` in terracotta. This keeps the lead
  inside the platform, which matters for the business, not just the design.
- WhatsApp and Call demoted to **icon buttons** beside it — available, not
  dominant.
- No third-party brand color above 44dp of surface area.

### 4.3 Dependency

Sections 5 and 6 need real data. **This phase is gated on the content backfill
in Phase 7.** Building it against empty tables reproduces the current problem in
a nicer layout.

---

## Phase 5 — Depth and surface

### 5.1 Collapse the elevation system

Six shadow levels (`subtle` / `soft` / `elevated` / `raised` / `floating` /
`modal`) is more than any app can apply consistently — and inconsistent
elevation is read as sloppiness. Collapse to **three semantic levels**:

| Semantic | Use |
|---|---|
| `rest` | Cards at rest |
| `raised` | Pressed / active / featured |
| `overlay` | Sheets, dialogs, sticky bars |

Keep the warm terracotta tint — that part is already right.

### 5.2 Image scrims

Any text over a photo needs a **gradient** scrim (transparent → 60% at the text
edge), never a flat overlay. Flat overlays grey the whole image and are a
reliable cheap-app tell.

### 5.3 Hairlines

Borders should be warm-tinted at low alpha, not neutral grey. Grey borders on a
cream surface read dirty.

---

## Phase 6 — Motion and micro-interaction

"Hand-made" is felt mostly in response to touch. Currently the app has page
transitions and skeletons but little tactile feedback.

1. **Press state on every tappable** — scale to 0.97 + shadow drop to `rest`,
   120ms, `BatshMotion` easing
2. **Haptics** — selection click on chips/tabs, light impact on save/like,
   success notification on quote sent
3. **Hero transition** card cover → profile hero
4. **Image fade-in** on decode — images must never pop in
5. **Skeleton → content crossfade**, not a hard swap

All guarded by `MediaQuery.disableAnimations`, per existing rules.

---

## Phase 7 — Photography standard and content backfill

**The single highest-impact item in this document.** Renovation is a visual
category; the imagery *is* the product. Current screenshots use Western stock
photography, which fails twice: generic, and not credible for Cairo.

### 7.1 Standard

- **No stock photography. Ever.** Real Egyptian interiors only.
- 4:3 or 16:10, minimum 1200px on the long edge
- Warm-neutral grade, consistent across the app
- Before/after pairs wherever available — the native format of the category

### 7.2 No-photo fallback

Replace the gold gradient placeholder with a **warm textured plate carrying the
contractor's initial** set in the display face. A typographic fallback reads as
designed; a gradient reads as missing.

### 7.3 Backfill

Onboard **6 contractors properly** — real photos, real completed projects, real
reviews — rather than showing 11 with stock. Fewer and true beats more and fake.
This unblocks Phase 4.

---

## Phase 8 — Copy

- **Egyptian dialect pass** over `strings.dart`. MSA reads institutional and
  cold. `لسه مفيش عروض — عادةً بتوصل خلال يومين، متقلقش` does more for warmth
  than any visual change in this document, and costs nothing.
- Fix label-bolted-to-number constructions: `٥٦ المشاريع المنجزة` → `٥٦ مشروع منجز`
- Every empty state gets a reason *and* an action (the `BatshEmptyState` contract
  already requires this — audit that it is honoured)

---

## Sequencing

```
Phase 0  Credibility bugs      -- 1-2 days  -- no dependencies
Phase 1  Typography            -- 2-3 days  -- decision gate: pairing test
Phase 2  Spatial semantics     -- 2 days    -- after 1
Phase 3  Card redesign         -- 2 days    -- after 1, 2
Phase 7  Photography backfill  -- parallel, start immediately
Phase 4  Profile rebuild       -- 4-5 days  -- GATED on 7
Phase 5  Depth/surface         -- 1 day
Phase 6  Motion                -- 2 days
Phase 8  Copy                  -- parallel
```

Phase 7 starts on day 1 in parallel with everything, because Phase 4 — the most
important screen — cannot begin without it.

---

## Definition of done

Objective, per phase:

1. Zero ellipses on names, titles, or placeholders at 360dp
2. Zero profiles rendering two identity badges (unit test)
3. Zero `letterSpacing` values below `0` in the theme
4. All display/headline leading ≥ 1.40
5. Contractor card renders ≤ 6 elements; photo ≥ 55% of card height
6. Profile screen scrolls ≥ 2.5 viewport heights with real content
7. Zero stock photographs in the production database
8. Every tappable surface has a press state
9. `flutter analyze` clean; test suite green (currently ~186 tests)

Subjective, and the real test: **hand the phone to five Egyptian homeowners who
have never seen it and ask them to find a contractor for a kitchen.** Watch where
they hesitate. Ask afterwards whether it feels like a company they would trust
with 200,000 EGP. That question is the whole point of this plan.

---

## What this plan deliberately does not do

- **No background pattern.** It was already built, shipped, and retired — see the
  comment in `lib/core/widgets/batsh_pattern_background.dart`: it "competed with
  content and caused eye-strain on scroll." That verdict was correct. The dead
  no-op widget and the unused `assets/images/construction_pattern.jpg` should be
  deleted.
- **No new features.** The app has 15 feature modules already. Depth here means
  craft and content, not surface area.
- **No filling of whitespace.** See §0.
