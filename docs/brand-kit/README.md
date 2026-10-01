# Shattab Brand Kit v2.0 — Quick Handoff

Status: working identity handoff
Date: 2026-08-26

This is the practical brand layer for Shattab. The strategic brand rules live
in [brand-identity.md](../brand-identity.md), the canonical product UI board
is [brand-ux-board.md](../brand-ux-board.md), and the compact Flutter contract
is [design-system/shattab/MASTER.md](../../design-system/shattab/MASTER.md).

For the complete specification, use [Full Brand Identity Guidelines](../brand-identity.md).
This file is the quick implementation handoff.

The visual companion is [shattab-product-identity-board-v3.png](./visuals/shattab-product-identity-board-v3.png).
The complete visual board pack is indexed in
[visuals/README.md](./visuals/README.md). Use the identity plate, pattern
plate, page plate, journey plate, and state/content plate together; none of
them is a standalone replacement for the board's written rules.
The ready-to-use campaign pack is documented in [visuals/README.md](./visuals/README.md).
The exact base-logo reference is [shattab-base-logo-sheet.svg](./shattab-base-logo-sheet.svg).

## 1. Brand platform

### Role

Shattab is the trusted starting point for home finishing in Egypt.

### Core idea

Every project moves from the first idea to the final finish. Shattab gives
homeowners a clearer way to find the right professional and gives skilled
professionals a credible way to be found.

### Master promise

From idea to finish.

Arabic campaign line:

من أول فكرة لآخر لمسة

### Positioning sentence

For Egyptian homeowners and finishing professionals who want a better way to
start and complete renovation work, Shattab is the local marketplace that
turns a vague need into a visible, comparable, trusted next step.

### Personality

- Warm, not childish.
- Capable, not corporate.
- Egyptian, not slang-heavy.
- Reassuring, not over-promising.
- Practical, not industrial.

### Brand pillars

1. Evidence over claims. Show real work, clear specialties, service areas,
   quotes, and verification signals.
2. Local relevance. Speak naturally to Egyptian homes, neighborhoods, budgets,
   and ways of contacting professionals.
3. Progress you can feel. Make the next step obvious: discover, compare,
   request, quote, hire, finish.
4. Craft with dignity. Present contractors as skilled professionals, not
   anonymous labor.

## 2. Messaging system

### Short description

Find the right professional for your home project, compare the work, and take
the next step with confidence.

### Product-facing Arabic voice

Use clear Egyptian Arabic for guidance and actions. Use formal Arabic when
legal, privacy, consent, or safety precision matters.

Prefer:

- ابدأ مشروعك
- اكتشف المحترفين
- اطلب عرض سعر
- شوف شغل اتعمل بجد
- ابعت تفاصيل مشروعك
- خلّي خطوتك الجاية أوضح

Avoid:

- guaranteed outcomes
- instant trust claims
- exaggerated urgency
- unexplained construction jargon
- corporate phrases that sound translated

### Writing rules

- Say what happened and what the user can do next.
- Keep one primary action per surface.
- Use real evidence before adjectives.
- Keep the brand name consistent as شطّب in Arabic product copy and Shattab
  in Latin product copy.
- Never make verification sound stronger than the evidence behind it.

## 3. Visual identity

### Logo idea

The primary lockup is the Arabic wordmark شطّب with a roof line that resolves
into a finished edge. The mark connects the home, the work, and the act of
finishing without falling back to a generic house icon.

### Distinctive graphic device

The finish line is a single architectural line that begins as a roof edge and
resolves into a clean completed corner. Use it as:

- a divider between sections
- a reveal line in motion
- a quiet underline under a message
- a construction detail in campaign layouts
- a watermark in spacious brand-expression surfaces

Use one finish line at a time. It should support the message, not become a
pattern behind dense product content.

### Logo behavior

- Primary: Arabic wordmark with roof line.
- Compact: roof-line mark for app icon, avatar, and small controls.
- One-color: charcoal on light; warm cream on terracotta or charcoal.
- Clear space: at least the height of the wordmark central stem.
- Never stretch, redraw, shadow, badge, or place on a busy image without a
  quiet backing surface.

The current visible base logo is the artwork in
assets/icon/app_icon_foreground.png and assets/images/logo_wordmark.png. The
visual pack uses that supplied mark as composited artwork; the image scenes do
not redraw or replace the base logo.

The SVG exports in assets/icon/ need to be reconciled with the visible PNG base
mark before they are treated as master vector artwork.

### Composition language

Use a calm, editorial rhythm:

- one expressive moment
- one functional application
- one evidence or construction detail
- generous warm space
- restrained rules and labels

The brand should feel considered before it feels decorative.

## 4. Color system

| Role | Token | Hex | Primary use |
| --- | --- | --- | --- |
| Terracotta | brandTerracotta | #9E3D18 | Primary actions and brand signal |
| Warm cream | brandCream | #FFF8F3 | App canvas and quiet surfaces |
| Charcoal | brandCharcoal | #1F1B14 | Text, ink, dark frames |
| Olive | brandOlive | #5C614D | Verification, positive state, confidence |
| Sand | brandSand | #E4DCCC | Supporting surfaces and material texture |
| Gold | brandGold | #735C00 | Ratings and restrained premium detail only |

Color roles are semantic:

- Terracotta owns the primary action.
- Charcoal owns reading and contrast.
- Olive is reserved for positive and verified states.
- Gold is never a second primary action color.
- Functional error and warning colors communicate state; they are not
  decoration.
- Marketing may use larger terracotta fields. Dense product workflows should
  keep the canvas quiet.

## 5. Typography

The product typeface is the bundled IBM Plex Sans Arabic family for both Arabic
and Latin. It keeps mixed labels, numbers, and RTL/LTR transitions coherent
without a network dependency.

Use:

- 700 for display and major headings
- 600 for titles
- 400 for body copy
- 500 or 600 for labels and controls
- zero negative tracking in Arabic
- generous leading for Arabic marks and descenders

The Arabic wordmark is custom artwork. Do not recreate it with a font.

The current Flutter type and color tokens are the implementation authority:

- lib/core/theme/batsh_typography.dart
- lib/core/theme/batsh_colors.dart

## 6. Image direction

Photography is part of the trust system, not filler.

Show:

- real Egyptian homes and finishing details
- hands, tools, tile, plaster, wood, paint, and visible progress
- warm natural light
- honest before/after context
- the work first, the mood second

Avoid:

- generic luxury interiors with no evidence of craft
- staged office scenes
- impossible or AI-looking construction
- unlabelled before/after promises
- images that imply a service Shattab does not provide

The preferred visual temperature is warm-neutral, with terracotta or olive
appearing as a controlled accent rather than a heavy filter.

## 7. Brand applications

| Surface | Expression | Rule |
| --- | --- | --- |
| App icon | Compact roof-line mark | Cream/terracotta relationship only |
| Onboarding | Brand expression | One promise, one finish line, one clear action |
| Discover and opportunities | Product UI | Content leads; brand color guides attention |
| Contractor profile | Evidence system | Real work, one identity badge, clear contact path |
| Pro promotion | Premium expression | Charcoal, terracotta, restrained gold |
| Social post | Campaign | One short line plus one real project image |
| Contractor card or folder | Physical trust cue | Quiet mark, name, role, verification evidence |
| Motion | Progress signal | Finish line resolves; no looping decoration |

## 8. Do and do not

Do:

- keep the logo family consistent across touchpoints
- use warm tonal layers before shadows
- use low-opacity terracotta-tinted shadows
- keep content ahead of decoration
- make Arabic RTL native
- repeat the same accent logic across a composition

Do not:

- use a generic house, roof, brick, or tool icon as the identity
- combine every construction metaphor in one layout
- use blue-purple startup gradients
- use WhatsApp green as a brand color
- fill dense workflows with full-screen terracotta
- turn every status into a pill or badge
- use fake statistics or unverified project evidence

## 9. Production checklist

Ready in the workspace:

- existing Shattab app icon source
- existing wordmark source
- implementation token system
- written identity baseline
- this brand-kit handoff
- visual direction board
- campaign, story, material, and brand-system visuals

Next production assets:

1. Finalize the Arabic wordmark as clean SVG/PDF artwork.
2. Export primary, compact, one-color, and reversed logo lockups.
3. Export Android adaptive, iOS, web favicon, and social avatar variants.
4. Build a small photo library from real Egyptian projects with usage rights.
5. Create 4:5 social and 9:16 story templates around the finish-line device.
6. Run Arabic/LTR legibility, contrast, and small-size recognition checks.

## 10. Freeze criteria

The identity is ready for broader rollout when:

- the wordmark is recognizable at 16, 24, 32, 48, 96, and 192 logical pixels
- the logo passes one-color and reversed-background tests
- light, dark, and increased-contrast product themes remain readable
- Arabic RTL, English LTR, long names, and mixed numbers have been reviewed
- real-photo quality and usage rights are confirmed
- five Egyptian homeowners can understand the next action without explanation

The board is the visual starting point. The written rules and the Flutter token
files are the system that should govern production work.
