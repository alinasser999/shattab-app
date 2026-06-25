---
title: "Batsh Design Tokens — extracted from Stitch"
date: 2026-05-14
source: "Stitch project 'Shattab: Egyptian Finishing Platform' (id 224640672337163847)"
status: source-of-truth
---

# Batsh Design Tokens

These tokens are extracted from the Stitch "Shattab: Egyptian Finishing Platform"
design system on 2026-05-14. They are the source of truth for `BatshTheme`.
Stitch uses the project name "Shattab" but the Batsh and Shattab visual systems
are intentionally identical — same Egyptian contractor concept, same Modern
Heritage aesthetic.

If the Stitch design evolves, re-extract here first, then update
`lib/core/theme/`.

## 1. Aesthetic concept

**Modern Heritage** — Mediterranean warmth + contemporary Cairene elegance.
Tactile minimalism. Soft edges, organic color transitions, sandstone/terracotta
palette evoking Egyptian sunset light. Premium, trustworthy, grounded.

Never cold, never industrial. RTL-first.

## 2. Color palette (Material 3 token names → hex)

### 2.1 Surface family (the canvas)

| Token | Hex | Notes |
|---|---|---|
| surface | `#fff8f3` | Warm cream — primary canvas |
| surface-bright | `#fff8f3` | Same as surface in light mode |
| surface-dim | `#e2d9ce` | Dimmed sandstone |
| surface-container-lowest | `#ffffff` | Pure white — cards on warm bg |
| surface-container-low | `#fcf2e7` | Subtle warm tint |
| surface-container | `#f6ece1` | Default container |
| surface-container-high | `#f1e7dc` | Elevated container |
| surface-container-highest | `#ebe1d6` | Highest tonal container |
| surface-variant | `#ebe1d6` | Variant surface |
| inverse-surface | `#353028` | Dark inverse for snackbars |
| background | `#fff8f3` | App background |
| outline | `#8a726a` | Default borders |
| outline-variant | `#dec0b7` | Hairline / subtle borders |

### 2.2 Primary — Terracotta

| Token | Hex |
|---|---|
| primary | `#9e3d18` |
| on-primary | `#ffffff` |
| primary-container | `#bf542e` |
| on-primary-container | `#fffbff` |
| inverse-primary | `#ffb59d` |
| primary-fixed | `#ffdbd0` |
| primary-fixed-dim | `#ffb59d` |
| on-primary-fixed | `#390c00` |
| on-primary-fixed-variant | `#822803` |
| surface-tint | `#a23f1a` |

### 2.3 Secondary — Olive

| Token | Hex |
|---|---|
| secondary | `#5c614d` |
| on-secondary | `#ffffff` |
| secondary-container | `#e0e5cc` |
| on-secondary-container | `#626753` |
| secondary-fixed | `#e0e5cc` |
| secondary-fixed-dim | `#c4c9b1` |
| on-secondary-fixed | `#191d0e` |
| on-secondary-fixed-variant | `#444937` |

### 2.4 Tertiary — Gold (premium accents)

| Token | Hex |
|---|---|
| tertiary | `#735c00` |
| on-tertiary | `#ffffff` |
| tertiary-container | `#cca830` |
| on-tertiary-container | `#4f3e00` |
| tertiary-fixed | `#ffe088` |
| tertiary-fixed-dim | `#e9c349` |
| on-tertiary-fixed | `#241a00` |
| on-tertiary-fixed-variant | `#574500` |

### 2.5 Text on surface

| Token | Hex | Use |
|---|---|---|
| on-surface | `#1f1b14` | Primary text |
| on-surface-variant | `#57423b` | Secondary text |
| inverse-on-surface | `#f9efe4` | Text on inverse-surface |

### 2.6 Semantic — error

| Token | Hex |
|---|---|
| error | `#ba1a1a` |
| on-error | `#ffffff` |
| error-container | `#ffdad6` |
| on-error-container | `#93000a` |

Success / warning / info are not in the Stitch palette — derive from
secondary (success), tertiary (warning), primary (info).

## 3. Typography scale

Stitch fonts: **Noto Serif** (headlines) + **Plus Jakarta Sans** (body/labels).

For Arabic rendering we wrap Latin fonts with Arabic-native fallbacks:
- Headline stack: **Noto Naskh Arabic** → Noto Serif
- Body / label stack: **IBM Plex Sans Arabic** → Plus Jakarta Sans

Flutter `fontFamilyFallback` resolves per-glyph, so Arabic codepoints render
in the Arabic font and Latin codepoints fall back cleanly.

| Token | Family | Size | Weight | Line height |
|---|---|---|---|---|
| display-lg | headline-stack | 40 | 700 | 52 |
| headline-lg | headline-stack | 32 | 600 | 40 |
| headline-lg-mobile | headline-stack | 28 | 600 | 36 |
| headline-md | headline-stack | 24 | 600 | 32 |
| title-lg | body-stack | 20 | 600 | 28 |
| body-lg | body-stack | 18 | 400 | 28 |
| body-md | body-stack | 16 | 400 | 24 |
| label-md | body-stack | 14 | 500 | 20 |

Mobile-first rule: use `headline-lg-mobile` instead of `headline-lg` on screens
≤600px wide. Wraps awkwardly less.

## 4. Spacing scale (px)

| Token | Px |
|---|---|
| xs | 4 |
| sm | 8 (base) |
| md | 12 |
| gutter | 16 |
| lg | 24 |
| xl | 40 |
| xxl | 64 |
| margin-mobile | 20 |

Vertical rhythm = 8px baseline grid.

## 5. Radius scale

| Token | Px |
|---|---|
| none | 0 |
| sm | 4 |
| default | 8 |
| md | 12 |
| lg | 16 |
| xl | 24 |
| full | 9999 |

Defaults from Stitch:
- Inputs, small buttons → 8
- Cards, surface containers → 16
- Large image containers, decorative → 24
- Pills (chips, badges) → full

## 6. Shadows / elevation

Stitch describes elevation as "tonal layers + ambient shadows tinted with
terracotta". M1 implementation: 4 levels, all tinted with `rgba(158, 61, 24, alpha)`
(primary color):

| Level | Spec |
|---|---|
| none | no shadow |
| soft | y:2 blur:8 spread:0 rgba(158,61,24,0.06) |
| raised | y:4 blur:16 spread:0 rgba(158,61,24,0.10) |
| floating | y:8 blur:24 spread:0 rgba(158,61,24,0.14) |

Never use pure black shadows.

## 7. Motion

| Token | Spec |
|---|---|
| duration.fast | 150 ms |
| duration.normal | 250 ms |
| duration.slow | 400 ms |
| curve.smooth | Curves.easeOutCubic |
| curve.spring | Curves.elasticOut (used sparingly) |

## 8. Min hit area

Per Stitch: 48×48 dp minimum on all interactive elements.

## 9. Direction

`TextDirection.rtl` is the default for the entire app. Set at the app root.
