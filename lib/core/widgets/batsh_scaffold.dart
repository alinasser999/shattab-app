import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_motion.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

enum BatshHeaderStyle { normal, primary }

class BatshScaffold extends StatelessWidget {
  const BatshScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding = const EdgeInsets.symmetric(
      horizontal: BatshSpacing.marginMobile,
    ),
    this.showAppBar = true,
    this.centerTitle = true,
    this.resizeToAvoidBottomInset = true,
    this.animateEntrance = true,
    this.appBarBottom,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.headerStyle = BatshHeaderStyle.normal,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final EdgeInsets padding;
  final bool showAppBar;
  final bool centerTitle;
  final bool resizeToAvoidBottomInset;
  final bool animateEntrance;
  final PreferredSizeWidget? appBarBottom;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final BatshHeaderStyle headerStyle;

  @override
  Widget build(BuildContext context) {
    final isPrimary = headerStyle == BatshHeaderStyle.primary;

    Widget bodyContent = SafeArea(
      child: Padding(padding: padding, child: body),
    );

    if (animateEntrance) {
      bodyContent = bodyContent
          .animate()
          .fadeIn(duration: BatshMotion.slower, curve: BatshMotion.easeOut)
          .slideY(
            begin: 0.025,
            end: 0,
            duration: BatshMotion.slower,
            curve: BatshMotion.easeOut,
          );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? context.colorScheme.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: showAppBar
          ? AppBar(
              title: title != null
                  ? Text(
                      title!,
                      style: isPrimary
                          ? BatshTypography.titleLg.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onPrimary,
                            )
                          : BatshTypography.titleLg.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    )
                  : null,
              centerTitle: centerTitle,
              leading: leading,
              actions: actions,
              backgroundColor: isPrimary
                  ? context.colorScheme.primary
                  : Colors.transparent,
              foregroundColor: isPrimary
                  ? context.colorScheme.onPrimary
                  : context.colorScheme.onSurface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              bottom: appBarBottom,
            )
          : null,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          if (isPrimary)
            Container(
              height: 1,
              color: context.colorScheme.primary.withValues(alpha: 0.15),
            )
          else if (showAppBar)
            Container(height: 0.5, color: context.colorScheme.outlineVariant),
          Expanded(child: bodyContent),
        ],
      ),
    );
  }
}
