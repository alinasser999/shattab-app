import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

import '../l10n/strings.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_icon_size.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_shadows.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// The search field at the top of a browse screen.
///
/// Replaces two private `_SearchBar` classes that were the same widget written
/// twice — same height, same row, same clear-on-type behaviour — which had
/// drifted apart in every detail that was not structural: one used a radius
/// token and the other `BorderRadius.circular(26)`, one a card surface and the
/// other a container surface, one `Icons.search` and the other
/// `Icons.search_rounded`.
///
/// The divergence that mattered was the clear button. One built it from a
/// `GestureDetector` wrapping a 20px icon with 4px of padding, giving a target
/// around 28px — under the 48px minimum, and awkward for anyone who cannot
/// place a fingertip precisely. The other used [IconButton], which is 48px and
/// carries a tooltip. This keeps the second.
class BatshSearchBar extends StatefulWidget {
  const BatshSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  /// Required rather than defaulted: "Search" alone does not say what is being
  /// searched, and the two callers search different things.
  final String hintText;

  @override
  State<BatshSearchBar> createState() => _BatshSearchBarState();
}

class _BatshSearchBarState extends State<BatshSearchBar> {
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    // Repaint for the clear button appearing and disappearing. The controller
    // belongs to the caller, so dispose removes the listener and leaves the
    // controller alone.
    _listener = () => setState(() {});
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 52,
      padding: const EdgeInsetsDirectional.only(
        start: BatshSpacing.gutter,
        end: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BatshRadius.brFull,
        boxShadow: BatshShadows.soft,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: BatshIconSize.md,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: BatshTypography.bodyMd,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              tooltip: context.l10n.clearSearch,
              visualDensity: VisualDensity.compact,
              onPressed: widget.onClear,
              icon: Icon(
                Icons.close_rounded,
                size: BatshIconSize.md,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
