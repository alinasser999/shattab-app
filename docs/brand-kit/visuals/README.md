# Shattab Visual Pack v3.0

This folder contains the approved visual pack for the Shattab identity and
product UI direction. The finished compositions use the supplied transparent
base logo, the master line "From idea to finish.", the finish-line device, and
the approved terracotta / olive / sand / cream / charcoal direction.

The product-level pack is a set of connected plates. Use it with
`docs/brand-ux-board.md` as the canonical source for new screens, states, and
brand applications.

## Finished visuals

| File | Format | Use |
| --- | --- | --- |
| [shattab-brand-system-board-v2.png](./shattab-brand-system-board-v2.png) | 2400 x 1500 PNG | Internal brand handoff and presentation |
| [shattab-campaign-hero-4x5.png](./shattab-campaign-hero-4x5.png) | 1122 x 1402 PNG | Campaign post, paid social, project story |
| [shattab-story-9x16.png](./shattab-story-9x16.png) | 941 x 1672 PNG | Story, reel cover, vertical campaign frame |
| [shattab-material-1x1.png](./shattab-material-1x1.png) | 1254 x 1254 PNG | Social tile, moodboard, material direction |
| [shattab-product-identity-board-v3.png](./shattab-product-identity-board-v3.png) | PNG | Product identity overview and quality bar |
| [shattab-identity-system-board-v4.png](./shattab-identity-system-board-v4.png) | PNG | Logo suite, materials, type, image, motion, and applications |
| [shattab-ui-patterns-board-v1.png](./shattab-ui-patterns-board-v1.png) | PNG | Tokens and reusable UI patterns |
| [shattab-page-system-board-v1.png](./shattab-page-system-board-v1.png) | PNG | Core page and screen compositions |
| [shattab-journeys-board-v1.png](./shattab-journeys-board-v1.png) | PNG | Main-page and role-based journey flows |
| [shattab-states-content-board-v1.png](./shattab-states-content-board-v1.png) | PNG | States, trust semantics, and content examples |
| [shattab-homepage-enhanced-primary-v1.png](./shattab-homepage-enhanced-primary-v1.png) | PNG | High-fidelity homeowner homepage proposal |
| [shattab-homepage-enhanced-states-v1.png](./shattab-homepage-enhanced-states-v1.png) | PNG | New, active-project, and no-evidence homepage states |
| [shattab-homepage-full-scroll-v1.png](./shattab-homepage-full-scroll-v1.png) | PNG | Full scrollable homeowner homepage with section actions |
| [shattab-homepage-full-scroll-v2.png](./shattab-homepage-full-scroll-v2.png) | PNG | Longer, warmer homepage with restrained action hierarchy |

## Source plates

The matching source PNG files are logo-free image plates. They are kept
separate so a photographer can replace the generated concept scene while the
logo placement, copy treatment, color logic, and composition remain stable.

These are art-direction assets, not proof of a Shattab project or a promise of
service quality. Before paid publication, replace concept scenes with licensed
real Egyptian project photography where available and retain the same negative
space and crop logic.

## Regeneration

Run the local compositor from the repository root:

    powershell -NoProfile -ExecutionPolicy Bypass -File ".\docs\brand-kit\visuals\build-brand-visuals.ps1"

The compositor reads assets/images/logo_wordmark.png and the three source
plates, then writes the finished PNGs in this folder. Do not use the old SVG
geometry as a logo source until it has been reconciled with the supplied PNG
mark.
