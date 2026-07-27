import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/batsh_icon_size.dart';
import '../theme/batsh_motion.dart';

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
    final reduced = MediaQuery.disableAnimationsOf(context);

    // nothingYet is an invitation, so it takes brand colour. noResults is a
    // dead end the user created themselves, so it stays neutral — colouring it
    // would read as a warning about a state that is not a problem.
    final (medallionColor, glyphColor) = switch (kind) {
      BatshEmptyStateKind.nothingYet => (
        BatshColors.primaryFixed.withValues(alpha: 0.2),
        BatshColors.primary.withValues(alpha: 0.65),
      ),
      BatshEmptyStateKind.noResults => (
        BatshColors.surfaceContainerHigh,
        BatshColors.onSurfaceVariant,
      ),
    };

    final iconWidget = ExcludeSemantics(
      child: Container(
        width: _medallion,
        height: _medallion,
        decoration: BoxDecoration(
          color: medallionColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: glyphColor, size: BatshIconSize.xl),
      ),
    );

    final animatedIcon = reduced
        ? iconWidget
        : iconWidget
              .animate()
              .fadeIn(duration: 350.ms, curve: BatshMotion.easeOut)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                curve: BatshMotion.springTap,
              );

    final titleWidget = Text(
      title,
      textAlign: TextAlign.center,
      style: BatshTypography.titleLg.copyWith(color: BatshColors.onSurface),
    );

    final animatedTitle = reduced
        ? titleWidget
        : titleWidget
              .animate(delay: 100.ms)
              .fadeIn(duration: 350.ms, curve: BatshMotion.easeOut)
              .slideY(begin: 0.2, end: 0, curve: BatshMotion.easeOut);

    final messageWidget = Padding(
      padding: const EdgeInsets.only(top: BatshSpacing.sm),
      child: SizedBox(
        width: 280,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: BatshTypography.bodyMd.copyWith(
            color: BatshColors.onSurfaceVariant,
          ),
        ),
      ),
    );

    final animatedMessage = reduced
        ? messageWidget
        : messageWidget
              .animate(delay: 200.ms)
              .fadeIn(duration: 350.ms, curve: BatshMotion.easeOut)
              .slideY(begin: 0.2, end: 0, curve: BatshMotion.easeOut);

    Widget? animatedAction;
    if (action != null) {
      final actionWidget = Padding(
        padding: const EdgeInsets.only(top: BatshSpacing.lg),
        child: SizedBox(width: double.infinity, child: action),
      );
      animatedAction = reduced
          ? actionWidget
          : actionWidget
                .animate(delay: 300.ms)
                .fadeIn(duration: 350.ms, curve: BatshMotion.easeOut)
                .slideY(begin: 0.2, end: 0, curve: BatshMotion.easeOut);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title and message are announced as one label. Left as separate
            // nodes a screen reader reads the headline, pauses, then reads the
            // instruction as if it were unrelated text. The action stays
            // outside this wrapper: merging it would swallow the button and
            // leave the only way forward unreachable.
            Semantics(
              label: '$title $message',
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  animatedIcon,
                  const SizedBox(height: BatshSpacing.gutter),
                  animatedTitle,
                  animatedMessage,
                ],
              ),
            ),
            ?animatedAction,
          ],
        ),
      ),
    );
  }
}
