# Technical Debt Register

Priorities are based on user-data risk, regression risk and operational cost,
not on the number of files involved.

## P0

| Item | Evidence | Next safe action |
| --- | --- | --- |
| Live RLS/storage verification is not executed in the repository gate | `supabase/tests/rls_regression.sql` is versioned, but `supabase test db --workdir supabase` still needs a disposable local/staging Postgres service | Run the harness and Supabase lint/advisors in a protected staging workflow, then add owner/non-owner fixture assertions |

## P1

| Item | Evidence | Next safe action |
| --- | --- | --- |
| RLS regression coverage is thin | Migration SQL is versioned, but no database policy test harness is present in `test/` | Add staging/local SQL tests for anonymous, owner and non-owner access |

Upload validation is now centralized through `UploadPolicy` at every image and
private-document boundary. The media router also normalizes public images before
an optional R2 upload, so the storage provider cannot change the size/format
contract.

## P2

| Item | Evidence | Next safe action |
| --- | --- | --- |
| Collection pagination is inconsistent | Some legacy RPCs remain offset-compatible for released-client compatibility, while discovery landing/search, feed, briefs, completed work and saved professionals now use stable cursors | Migrate the remaining bounded account-owned lists feature-by-feature; do not add cache/realtime to an offset list until its cursor contract is defined |
| Large presentation modules | Four screens exceed 1,200 lines | Extract cohesive private widget families without moving route/provider ownership |
| Migration lint is not a pull-request gate | It requires a configured safe database | Add a protected staging workflow, never a production-connected PR job |
| Secret and dependency scanning are not gates | No dedicated workflow step exists | Add a trusted scanner after reviewing current false positives and lockfile policy |
| CI toolchain upgrades are deliberate | `.github/workflows/ci.yml` pins Flutter `3.44.4` and the local SDK matches it | Upgrade the pin and local toolchain together, then rerun the full release preflight |
| Mobile release signing is not verified in CI | CI compiles an unsigned Android release target; signing credentials and an iOS build lane are still intentionally external | Add signed Android/iOS build jobs once signing/toolchain setup is documented |
| Sentry ownership is not documented | DSN is optional and no alert/on-call owner is encoded | Assign alert routing, retention and privacy ownership before production launch |
| Backup restoration has not been demonstrated | Runbook documents the requirement but no drill artifact exists | Restore into a non-production Supabase project and record RPO/RTO results |

## P3

| Item | Evidence | Next safe action |
| --- | --- | --- |
| Legal/support URLs and support phone are placeholders | Settings code contains launch-time constants | Replace with verified production destinations before store submission |
| Generated files are ignored | 26 local `.g.dart` files are not tracked | Keep CI generation mandatory and document generator compatibility changes |
