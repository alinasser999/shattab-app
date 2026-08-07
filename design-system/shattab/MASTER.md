# Shattab Design System Master

This file is the compact implementation contract for Shattab. The complete
brand rationale and usage rules live in `docs/brand-identity.md`.

## Design read

Shattab is a trust-first Egyptian finishing marketplace. Its visual language
is warm, practical, human, and calm: modern heritage rather than cold SaaS or
generic real-estate luxury.

## Source of truth

- Brand rules: `docs/brand-identity.md`
- Flutter colors: `lib/core/theme/batsh_colors.dart`
- Flutter typography: `lib/core/theme/batsh_typography.dart`
- Spacing: `lib/core/theme/batsh_spacing.dart`
- Radius: `lib/core/theme/batsh_radius.dart`
- Shadows: `lib/core/theme/batsh_shadows.dart`
- Motion: `lib/core/theme/batsh_motion.dart`

## Core tokens

| Role | Token | Value |
| --- | --- | --- |
| Brand terracotta | `brandTerracotta` | `#9E3D18` |
| Brand cream | `brandCream` | `#FFF8F3` |
| Brand charcoal | `brandCharcoal` | `#1F1B14` |
| Brand olive | `brandOlive` | `#5C614D` |
| Brand sand | `brandSand` | `#E4DCCC` |

Terracotta owns primary actions. Olive owns positive and verification states.
Gold is a restrained premium accent. Functional colors must never be used as
decoration.

## Typography

Use the bundled `IBM Plex Sans Arabic` family. The product uses one family so
Arabic, English, and numbers keep one voice. Display text uses 700, titles use
600, body uses 400, and labels use 500 or 600. Do not use negative tracking in
Arabic.

## Layout contract

- 8dp rhythm, with 4dp micro adjustments.
- Compact screen gutter: 16dp.
- Primary section/card gutter: 24dp.
- Cards: 24dp radius.
- Inputs and buttons: 16dp radius.
- Interactive targets: at least 48dp.
- Prefer tonal surface layers and warm low-opacity shadows.
- Content always takes priority over branding.

## Interaction contract

- Use existing `Batsh*` primitives before creating private duplicates.
- Use standard platform patterns for navigation, forms, sheets, and dialogs.
- Keep focus visible and never hide the focused control behind fixed UI.
- Treat Arabic RTL as native, not as a mirrored afterthought.
- Keep animations short, purposeful, and reduced-motion safe.
- Never make color the only signal for status or action.

## Asset contract

- Primary logo: Arabic wordmark with roof line.
- Compact mark: derived from the same logo family.
- App icon: wordmark-family mark on cream or terracotta, never the Flutter
  default icon.
- Photography: real craft, real homes, warm natural light.
- Pattern: supporting marketing texture only.

## Anti-patterns

- Generic green/dark SaaS palette.
- Inter, Roboto, or runtime font downloads for Arabic product UI.
- Full-screen terracotta backgrounds on dense workflows.
- Multiple unrelated house, door, brick, and tool motifs in one composition.
- Decorative gradients, fake statistics, AI-looking project evidence, or
  placeholder controls that look interactive.
- Hard black shadows, tiny touch targets, hidden focus, or clipped Arabic.
