# Shattab Brand Identity v1.0

Status: implementation baseline
Scope: Shattab brand, mobile application, web build, and product design system

This document is the working source of truth for brand expression. It is
deliberately smaller than a marketing moodboard: every rule below must be
usable in the Flutter product without weakening clarity, accessibility, or
RTL behavior.

## Brand decision

### Name

- Arabic product name in written copy: `شطّب`.
- Latin product name: `Shattab`.
- The logo is artwork, not running text. A small-size logo may omit the
  shadda when the vector lockup needs it, but product copy must not alternate
  between `شطب` and `شطّب`.
- Product line: `شطّب Pro`. Pro is a product tier, not a separate brand.

### Position

Shattab makes home finishing easier to start, compare, and complete by
connecting homeowners with suitable professionals and giving professionals a
clear path to relevant work.

### Promise

`من أول فكرة لآخر لمسة`

The promise is only credible when the product shows the next step clearly,
surfaces real work, and makes trust signals easy to verify.

### Personality

- Warm, not childish.
- Capable, not corporate.
- Egyptian, not slang-heavy.
- Reassuring, not over-promising.
- Practical, not industrial.

## Distinctive assets

The identity owns a small set of repeatable cues instead of decorating every
surface with every construction metaphor.

1. The Arabic wordmark `شطّب` with its roof line.
2. The terracotta and warm-cream pairing.
3. The finish-line device: a simple architectural line that resolves into a
   completed edge or check. Use it as a divider, reveal, or campaign detail.
4. Human craft photography showing real homes, real work, and real progress.
5. A calm, direct Egyptian Arabic voice.

The roof line is the primary graphic cue. Doors, bricks, tools, and repeated
house patterns are supporting imagery only. Do not use all of them in the same
composition.

## Logo rules

### Lockups

- Primary lockup: Arabic wordmark with roof line.
- Compact lockup: roof-line mark with the wordmark where space permits.
- One-color lockup: charcoal on light surfaces, warm cream on terracotta or
  charcoal surfaces.
- Small-size lockup: use the compact mark only when the full wordmark is not
  legible.

### Clear space and size

- Keep clear space equal to the height of the wordmark's central stem.
- Do not place the wordmark on a busy photograph without a quiet backing
  surface.
- Validate at 16, 24, 32, 48, 96, and 192 logical pixels.
- Never redraw, stretch, add a shadow, or place the mark inside an unrelated
  badge.

### App icon

The app icon must be derived from the wordmark family, not a generic house
symbol. Use a warm-cream field with the terracotta mark for light contexts and
the terracotta field with the warm-cream mark for dark or maskable contexts.
The icon must remain recognizable without the product name.

## Color system

### Core brand colors

| Role | Token | Hex | Use |
| --- | --- | --- | --- |
| Terracotta | `brandTerracotta` | `#9E3D18` | Primary action and brand signal |
| Warm cream | `brandCream` | `#FFF8F3` | App canvas and quiet brand surfaces |
| Charcoal | `brandCharcoal` | `#1F1B14` | Primary text and high-contrast ink |
| Olive | `brandOlive` | `#5C614D` | Trust, verified, and success contexts |
| Sand | `brandSand` | `#E4DCCC` | Supporting surfaces and campaign texture |

### Product roles

- Terracotta is the only primary action color.
- Charcoal is the default text color.
- Olive is reserved for positive state, verification, and confidence cues.
- Gold is reserved for premium detail and rating emphasis. It must not become
  a second primary action color.
- Error and warning colors communicate state only. They are not decorative
  brand colors.
- Marketing compositions may use larger terracotta fields. Product screens
  should keep the canvas quiet and let content lead.

Every text and essential icon combination must be checked for WCAG contrast.
Do not rely on color alone to communicate status.

## Typography

The product uses one bundled family: `IBM Plex Sans Arabic`.

- Display and headings: 700.
- Titles: 600.
- Body: 400.
- Labels and controls: 500 or 600.
- No negative tracking in Arabic.
- Keep Arabic line height generous enough for marks and descenders.
- Use the same family for Latin and Arabic so mixed labels do not change tone.
- The logo is custom artwork and is not recreated with a font.

The current Flutter type scale is the approved implementation scale. Do not
introduce Cairo, Tajawal, Inter, or a runtime font download for product UI
without a measured readability review.

## Shape, layout, and depth

- Screen gutters: 16dp on compact screens, 24dp for primary sections.
- Card padding: 24dp where content needs to breathe.
- Card radius: 24dp.
- Button and input radius: 16dp.
- Compact chips: 8 to 12dp or full pill where the control is genuinely a
  filter/status chip.
- Use warm tonal layers first and shadows second.
- Shadows stay terracotta-tinted and low opacity. Never use a hard black drop
  shadow as a brand effect.
- Use an 8dp rhythm with 4dp micro adjustments only when required by glyph or
  icon alignment.

## Photography

Photography should feel observed, not staged:

- Show Egyptian homes, materials, hands, tools, and progress.
- Prefer evidence of craft over generic luxury interiors.
- Keep warm natural light and restrained editing.
- Avoid repeated AI-looking rooms, impossible construction scenes, and stock
  images that imply a service we do not provide.
- On product cards, crop for the work first and the mood second.
- Before/after images must be truthful and labeled by context, never implied
  as a guarantee.

## Iconography and illustration

- Use one consistent line icon family.
- Default stroke is light to medium, with 44dp or larger tap areas around
  interactive icons.
- Icons explain actions or status; they do not replace labels when the meaning
  is ambiguous.
- Illustration is reserved for onboarding, empty states, and campaigns.
- The pattern is a quiet supporting texture, never the background of a dense
  workflow.

## Product expression

The brand has two layers:

### Brand expression

Used in onboarding, campaigns, app icon, splash, Pro promotion, empty-state
illustration, and marketing photography. It can be warmer, more expressive,
and more image-led.

### Product UI

Used in discovery, opportunities, profiles, settings, forms, and account
management. It must be quieter, scannable, and familiar. Brand color guides
attention; it does not fill every card.

The same wordmark, color roles, typography, and tone must be recognizable in
both layers, while common controls keep platform conventions.

## Motion

Motion communicates progress, not decoration.

- Entrance: a short fade and small upward translation for hierarchy.
- Completion: a restrained check or finish-line resolution.
- Press: a subtle scale or tonal response without layout shift.
- Navigation: fast fade/slide transitions that preserve context.
- Reduced-motion mode removes travel and keeps essential state feedback.
- Never use looping motion to compensate for missing content.

## Voice and writing

- Product guidance: clear Egyptian Arabic.
- Legal, privacy, and consent: formal Arabic where precision matters.
- Error messages: say what happened and what the user can do next.
- Avoid exaggerated promises such as guaranteed results or instant trust.
- Prefer `كمّل ملفك عشان تظهر لعملاء أكتر` over formal bureaucratic wording.
- Use one spelling of the brand in every user-facing surface.

## Required validation before marketing freeze

- Blind recognition test for wordmark, compact mark, color pairing, and finish
  line against local marketplace and construction competitors.
- Legibility test at small icon sizes and large text settings.
- Contrast check for light, dark, and increased-contrast themes.
- Arabic RTL and English LTR review with long titles and mixed numbers.
- Task-based usability test for homeowner discovery and contractor
  opportunities, not only a preference survey.
- Real-photo review before publishing any generated or stock-like image.

This is the final implementation baseline for the codebase. Recognition and
market validation remain product work, not claims that can be inferred from a
static board.
