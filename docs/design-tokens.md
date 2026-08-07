---
title: "Shattab Product Design Tokens"
status: source-of-truth
brand: "شطّب / Shattab"
---

# Shattab Product Design Tokens

These tokens implement the Shattab Brand Identity v1.0 in Flutter. They are
the product layer of the brand, not a replacement for the marketing identity.

## Aesthetic

Warm Egyptian craft, expressed through quiet surfaces, terracotta actions,
charcoal type, olive trust signals, and real evidence of work. The app is
light and scannable first; expression increases in onboarding, campaigns, and
Pro surfaces.

## Color roles

| Role | Flutter token | Hex |
| --- | --- | --- |
| Canvas | `background` | `#FFF8F3` |
| Card | `surfaceContainerLowest` | `#FFFFFF` |
| Soft surface | `surfaceContainerLow` | `#F5EDE3` |
| Terracotta action | `primary` | `#9E3D18` |
| Terracotta tint | `primaryContainer` | `#FFDBD0` |
| Charcoal text | `onSurface` | `#1F1B14` |
| Secondary text | `onSurfaceVariant` | `#4A3630` |
| Olive trust | `secondary` | `#5C614D` |
| Olive tint | `secondaryContainer` | `#E0E5CC` |
| Gold premium | `tertiary` | `#735C00` |
| Sand support | `surfaceDim` | `#E4DCCC` |

The product must use semantic roles rather than raw hex values. Light and dark
schemes must preserve the same meaning, not simply invert the light palette.

## Typography

The bundled family is `IBM Plex Sans Arabic`.

| Role | Size | Weight | Line height |
| --- | ---: | ---: | ---: |
| Display large | 40 | 700 | 56 |
| Display medium | 34 | 700 | 48 |
| Headline large | 28 | 700 | 40 |
| Headline mobile | 26 | 700 | 38 |
| Headline medium | 24 | 700 | 34 |
| Headline small | 20 | 700 | 29 |
| Title large | 20 | 600 | 28 |
| Title medium | 18 | 600 | 26 |
| Body large | 17 | 400 | 26 |
| Body medium | 15 | 400 | 24 |
| Body small | 13 | 400 | 20 |
| Label large | 15 | 600 | 22 |
| Label medium | 13 | 500 | 18 |
| Label small | 11 | 500 | 16 |

Arabic does not use negative tracking. Keep enough leading for marks and
descenders. Mixed Arabic and Latin labels use the same family.

## Spacing

Use the existing `BatshSpacing` scale. The important semantic boundaries are:

- 8dp: elements within one idea.
- 16dp: sibling controls and screen edges.
- 24dp: card interiors and section sides.
- 40dp and above: section separation.
- 48dp: minimum interactive target.

## Radius and depth

- 8dp: compact controls.
- 12dp: small fields and chips.
- 16dp: buttons and inputs.
- 20dp: media.
- 24dp: cards and major surfaces.
- Full pill: status/filter chips only.

Use `BatshShadows` warm-tinted levels. Tonal separation is preferred over
strong shadows.

## Motion

Use `BatshMotion` and its reduced-motion helpers. Motion should communicate
entrance, state change, completion, or navigation. Never add looping decoration
to a workflow.

## Accessibility and localization

- Arabic RTL is the default.
- English LTR must remain stable.
- Do not rely on color alone for status.
- Preserve visible focus.
- Test large text, dark mode, 320dp width, and long translated strings.
- Keep fixed navigation from obscuring the final content.
