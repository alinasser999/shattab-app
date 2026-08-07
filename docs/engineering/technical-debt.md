# Technical Debt Register

Priorities are based on user-data risk, regression risk and operational cost,
not on the number of files involved.

## P0

| Item | Evidence | Next safe action |
| --- | --- | --- |
| Live RLS/storage verification is not automated | `supabase db lint --workdir supabase` cannot connect because local Postgres is not running | Start a disposable local/staging database, run lint/advisors, and add owner/non-owner policy tests |

## P1

| Item | Evidence | Next safe action |
| --- | --- | --- |
| Upload validation is distributed | Brief, portfolio, verification, payment, avatar, logo and post repositories each upload directly | Add one pure upload policy, then apply it at every repository boundary with size/type/path tests |
| Collection pagination is inconsistent | Several repositories cap at 100, while some feed/profile reads have separate cursor work | Inventory each list contract and standardize stable cursors before adding cache/realtime |
| Large presentation modules | Four screens exceed 1,200 lines | Extract cohesive private widget families without moving route/provider ownership |
| RLS regression coverage is thin | Migration SQL is versioned, but no database policy test harness is present in `test/` | Add staging/local SQL tests for anonymous, owner and non-owner access |
| CI depends on the hosted Flutter channel | `.github/workflows/ci.yml` uses `channel: stable` without a pinned SDK constraint | Pin the CI Flutter version after choosing the supported release policy |

## P2

| Item | Evidence | Next safe action |
| --- | --- | --- |
| Migration lint is not a pull-request gate | It requires a configured safe database | Add a protected staging workflow, never a production-connected PR job |
| Secret and dependency scanning are not gates | No dedicated workflow step exists | Add a trusted scanner after reviewing current false positives and lockfile policy |
| Mobile release builds are not verified in CI | CI now verifies a web release build only | Add Android/iOS build jobs once signing/toolchain setup is documented |
| Sentry ownership is not documented | DSN is optional and no alert/on-call owner is encoded | Assign alert routing, retention and privacy ownership before production launch |
| Backup restoration has not been demonstrated | Runbook documents the requirement but no drill artifact exists | Restore into a non-production Supabase project and record RPO/RTO results |

## P3

| Item | Evidence | Next safe action |
| --- | --- | --- |
| Legal/support URLs and support phone are placeholders | Settings code contains launch-time constants | Replace with verified production destinations before store submission |
| Generated files are ignored | 26 local `.g.dart` files are not tracked | Keep CI generation mandatory and document generator compatibility changes |

