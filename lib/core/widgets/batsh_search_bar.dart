import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';

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
    this.height = 52,
    this.borderRadius = BatshRadius.brFull,
    this.outlined = false,
    this.rowTextDirection,
    this.textDirection,
    this.textAlign,
    this.plainInput = false,
    this.onSubmitted,
    this.fontFamily,
    this.iconSize = BatshIconSize.md,
    this.iconColor,
    this.fontSize,
    this.fontWeight,
    this.clearButtonLargeTarget = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  /// Required rather than defaulted: "Search" alone does not say what is being
  /// searched, and the two callers search different things.
  final String hintText;

  /// Browse screens can opt into the compact reference geometry without
  /// changing the established default used by other surfaces.
  final double height;

  /// Some reference layouts use a quiet rounded rectangle instead of the
  /// default pill treatment.
  final BorderRadius borderRadius;

  /// Adds the same low-contrast outline used by compact directory fields.
  final bool outlined;

  /// Controls the physical placement of the leading search affordance while
  /// the editable text keeps the ambient writing direction.
  final TextDirection? rowTextDirection;

  /// Keeps the field's writing direction independent from icon placement.
  final TextDirection? textDirection;

  final TextAlign? textAlign;

  /// Removes theme-provided input chrome when the outer container owns it.
  final bool plainInput;

  /// Optional submit handler for surfaces that navigate after search.
  final ValueChanged<String>? onSubmitted;

  /// Optional local typeface override. Null keeps the shared typography.
  final String? fontFamily;

  /// Optional leading icon styling for compact, reference-specific fields.
  final double iconSize;
  final Color? iconColor;

  /// Optional input typography. Null preserves the shared defaults.
  final double? fontSize;
  final FontWeight? fontWeight;

  /// Opts into a 48dp clear target without changing legacy callers.
  final bool clearButtonLargeTarget;

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
      height: widget.height,
      padding: const EdgeInsetsDirectional.only(
        start: BatshSpacing.gutter,
        end: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: widget.borderRadius,
        border: widget.outlined
            ? Border.all(color: context.colorScheme.outlineVariant)
            : null,
        boxShadow: BatshShadows.soft,
      ),
      child: Row(
        textDirection: widget.rowTextDirection,
        children: [
          Icon(
            Icons.search_rounded,
            size: widget.iconSize,
            color: widget.iconColor ?? context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              textDirection: widget.textDirection,
              textAlign: widget.textAlign ?? TextAlign.start,
              textAlignVertical: TextAlignVertical.center,
              style: BatshTypography.bodyMd.copyWith(
                fontFamily: widget.fontFamily,
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                enabledBorder: widget.plainInput ? InputBorder.none : null,
                focusedBorder: widget.plainInput ? InputBorder.none : null,
                disabledBorder: widget.plainInput ? InputBorder.none : null,
                filled: widget.plainInput ? false : null,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: BatshTypography.bodyMd.copyWith(
                  fontFamily: widget.fontFamily,
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              tooltip: context.l10n.clearSearch,
              constraints: widget.clearButtonLargeTarget
                  ? const BoxConstraints(
                      minWidth: BatshSpacing.minHitArea,
                      minHeight: BatshSpacing.minHitArea,
                    )
                  : null,
              visualDensity: widget.clearButtonLargeTarget
                  ? VisualDensity.standard
                  : VisualDensity.compact,
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
