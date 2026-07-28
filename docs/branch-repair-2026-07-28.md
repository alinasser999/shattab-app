# Branch repair — `feat/bottom-nav-redesign`, 2026-07-28

The branch did not compile at the start of this session. An automated sweep in a
prior session edited files it did not understand. This records what was wrong,
what is fixed, and the recipe for what remains.

## Error count over the repair

| Stage | Errors |
|---|---|
| Session start (baseline, pre-existing) | thousands (full cascade) |
| After fixing the l10n import | 416 |
| After porting 57 missing ARB keys | 351 |
| After restoring codegen | **223** (216 `lib/`, 7 `test/`) |

## Fixed

### 1. `l10n_extension.dart` imported a package that no longer exists

`import 'package:flutter_gen/gen_l10n/app_localizations.dart'` — the synthetic
package path. Current Flutter removed synthetic-package generation; output now
goes to `lib/l10n/`. Every `context.l10n` call in the app failed to resolve.
Fixed to `import '../../l10n/app_localizations.dart'`. Also removed the
deprecated `synthetic-package: false` key from `l10n.yaml`.

### 2. Six part files contained `import` directives

Dart forbids any directive other than `part of` in a part file. The sweep
prepended `import 'package:batsh/core/theme/theme_extension.dart';` to:

- `features/auth/presentation/phone_entry_hero.dart`
- `features/auth/presentation/phone_entry_login_card.dart`
- `features/discovery/presentation/widgets/contractor_showcase_header.dart`
- `features/discovery/presentation/widgets/contractor_showcase_sections.dart`
- `features/shell/presentation/profile_screen_contractor.dart`
- `features/shell/presentation/profile_screen_settings.dart`

Removed. All three parent libraries already import `theme_extension`, so the
symbols resolve through the library.

### 3. Every `.g.dart` file was empty

Consequence of #2. A `build_runner build --delete-conflicting-outputs` deleted
all generated outputs, then failed on the illegal part files before rewriting
them. Subsequent runs wrote almost nothing because build_runner's cache
considered them current.

This one fault accounted for ~110 errors: all `part_of_non_part`, plus every
undefined `currentSessionProvider` / `currentProfileProvider` /
`authRepositoryProvider` / `supabaseClientProvider` / `briefsRepositoryProvider` /
`portfolioRepositoryProvider`.

Fix: `dart run build_runner clean` then a full build. 52 outputs restored.

**Lesson:** after any `--delete-conflicting-outputs` run that reports `E` builder
errors, assume generated output is destroyed and `clean` before rebuilding. A
cached "up to date" is not proof the file has content.

### 4. 57 ARB keys referenced but never ported

The prior session's ARB migration ported titles and labels and stopped before
long-form copy (`*Body`, `*Message`, `*Hint`, `*Sub`). Ported from
`lib/core/l10n/strings.dart` into `app_ar.arb` / `app_en.arb`.

Two remain unported because they take parameters or use interpolation, so the
extraction regex could not lift them: **`blockUserBody`**, **`deleteAccountBody`**.
Port these by hand.

## Remaining — 216 errors in `lib/`

| Code | Count | Cause |
|---|---|---|
| `undefined_identifier` | 125 | mostly `context` (123) |
| `undefined_getter` | 67 | `context.colorScheme.*` / `context.l10n` in context-free scopes |
| `implicit_this_reference_in_initializer` | 20 | same substitution inside field initializers |
| `undefined_named_parameter` | 5 | stale tests (see below) |
| other | 4 | knock-on |

### The single remaining pattern

The sweep replaced static token references (`BatshColors.*`) with theme-aware
ones (`context.colorScheme.*`) **without checking whether the enclosing scope has
a `BuildContext`**. The intent was correct — those values must be theme-aware to
work in dark mode — but the scopes were never given a context.

Worked example, `lib/core/widgets/batsh_badge.dart:123`:

```dart
// BROKEN — a getter has no context
@visibleForTesting
(Color, Color, Color) get debugPalette => switch ((tone, emphasis)) {
  (BatshBadgeTone.neutral, BatshBadgeEmphasis.solid) => (
    context.colorScheme.inverseOnSurface,   // <- no `context` in scope
    ...
```

```dart
// FIXED — take the context the values now depend on
@visibleForTesting
(Color, Color, Color) debugPalette(BuildContext context) =>
    switch ((tone, emphasis)) { ... };
```

Then update call sites to `debugPalette(context)`.

**Recipe, per file:**

1. Find the enclosing member. If it is a getter, a static method, a field
   initializer, or a top-level function, it has no context.
2. If the value is genuinely theme-dependent → add a `BuildContext context`
   parameter and update call sites. Prefer this.
3. If it is not theme-dependent (an error string, a duration, a size) → revert to
   the static token; the sweep should not have touched it. `error_mapper.dart`
   (16 errors) is likely this case — error messages are `context.l10n` lookups
   that belong at the call site, not in a mapper.
4. For `implicit_this_reference_in_initializer`, move the computation out of the
   initializer and into `build`.

### Worst files

| File | Errors |
|---|---|
| `core/widgets/batsh_badge.dart` | 30 |
| `features/briefs/presentation/contractor/job_opportunities_screen.dart` | 20 |
| `core/utils/error_mapper.dart` | 16 |
| `features/explore/presentation/widgets/post_card.dart` | 16 |
| `features/quotes/presentation/widgets/quote_status_badge.dart` | 15 |
| `features/billing/presentation/pro_screen.dart` | 14 |
| `features/discovery/domain/trust_signals.dart` | 10 |
| `features/moderation/presentation/report_sheet.dart` | 8 |

`trust_signals.dart` is a **domain** file — it should not reference `context` at
all. Domain models must not depend on Flutter. Whatever the sweep put there
belongs in the presentation layer.

### 7 errors in `test/`

`test/domain/trust_signals_test.dart` and `test/domain/review_stats_test.dart`
reference constructor parameters that no longer exist (`businessVerified`,
`avgResponseMinutes`, `responseRate`, `completionRate`, `photoUrls`) and an
undefined `BatshLocalizations`. These tests were written against an older API and
never updated. Fix after `lib/` is green.

## Verification

```bash
flutter analyze
```

```bash
flutter test
```

Target: zero errors, ~186 tests green. Neither has passed on this branch today.

## Work completed this session besides repair

Phase 0 of `docs/superpowers/specs/2026-07-28-premium-ui-craft-design.md`:

- `محترف جديد` → `لسه مفيش تقييمات` in both rating-empty slots. The old label put
  an identity claim in a ratings slot, so a contractor with 56 finished projects
  and a silver tier was simultaneously branded "new".
- Tab name collision resolved: `اكتشف` / `استكشف` (same triliteral root, adjacent
  in the nav, indistinguishable) → `المحترفين` / `أعمال`.

Still open in Phase 0: truncation audit, test-account purge, numeral policy.
