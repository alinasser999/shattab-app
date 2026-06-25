import 'package:flutter/material.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_spacing.dart';

class BatshScaffold extends StatelessWidget {
  const BatshScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padding =
        const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
    this.showAppBar = true,
    this.centerTitle = true,
    this.resizeToAvoidBottomInset = true,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BatshColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              centerTitle: centerTitle,
              leading: leading,
              actions: actions,
              backgroundColor: BatshColors.background,
            )
          : null,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(padding: padding, child: body),
      ),
    );
  }
}
