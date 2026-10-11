import 'package:flutter/material.dart';

import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Why the screen is empty — which decides what the user should do next.
///
/// The two cases look similar and behave nothing alike. Telling a user who
/// just filtered a list to "create your first project" is wrong; so is showing
/// a brand-coloured invitation to someone who simply mistyped a search.
enum BatshEmptyStateKind {
  /// Nothing exists yet. The user has not created, saved, or received the
  /// thing. The state is an invitation, so it carries brand colour and its
  /// action starts the flow that fills it.
  nothingYet,

  /// Things exist, but a search or filter excluded all of them. Nothing is
  /// wrong and nothing needs creating, so the state stays neutral and its
  /// action is the way back out: clear the search, drop the filter.
  noResults,
}

/// The state of a screen that has nothing to show.
///
/// Every empty state carries a [title] and a [message]. The message is
/// required rather than optional because a bare headline — "Nothing here yet"
/// — tells the user what they can already see and nothing about what to do.
///
/// For a screen that failed rather than emptied, use `BatshError`. An error is
/// not an absence: it says the app could not find out, and it needs a retry
/// rather than an invitation.
class BatshEmptyState extends StatelessWidget {
  const BatshEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    this.kind = BatshEmptyStateKind.nothingYet,
  });

  final String title;

  /// What the user can do about it. Required: see the class doc.
  final String message;

  final IconData icon;

  /// The primary way forward. For [BatshEmptyStateKind.nothingYet] this starts
  /// the flow that fills the screen; for [BatshEmptyStateKind.noResults] it
  /// undoes whatever narrowed it.
  final Widget? action;

  final BatshEmptyStateKind kind;

  /// Diameter of the icon medallion. Large enough to read as a deliberate
  /// mark rather than an oversized glyph, small enough not to push the message
  /// below the fold on a short screen.
  static const double _medallion = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final content = Padding(
      padding: const EdgeInsets.all(BatshSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: _medallion,
              height: _medallion,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kind == BatshEmptyStateKind.nothingYet
                    ? colors.primaryContainer
                    : colors.surfaceContainerHigh,
              ),
              child: Icon(
                icon,
                size: BatshIconSize.xl,
                color: kind == BatshEmptyStateKind.nothingYet
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.gutter),
          Semantics(
            header: true,
            label: '$title $message',
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: BatshTypography.titleLg,
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: BatshTypography.bodyMd.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: BatshSpacing.lg),
            action!,
          ],
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? Center(child: SingleChildScrollView(child: content))
          : content,
    );
  }
}
