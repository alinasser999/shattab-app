import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class BatshTextField extends StatelessWidget {
  const BatshTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.initialValue,
    this.suffixIcon,
    this.enabled = true,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final String? initialValue;
  final Widget? suffixIcon;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
              child: Text(
                label!,
                style: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          TextFormField(
            controller: controller,
            initialValue: controller == null ? initialValue : null,
            autofocus: autofocus,
            enabled: enabled,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            style: BatshTypography.bodyMd,
            cursorColor: context.colorScheme.primary,
            cursorWidth: 2,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helperText,
              errorText: errorText,
              suffixIcon: suffixIcon,
              counterText: '',
              hintStyle: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
              errorStyle: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.error,
              ),
              filled: true,
              fillColor: context.colorScheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.gutter,
                vertical: BatshSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BatshRadius.brMd,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BatshRadius.brMd,
                borderSide: BorderSide(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BatshRadius.brMd,
                borderSide: BorderSide(
                  color: context.colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BatshRadius.brMd,
                borderSide: BorderSide(
                  color: context.colorScheme.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BatshRadius.brMd,
                borderSide: BorderSide(
                  color: context.colorScheme.error,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BatshRadius.brMd,
                borderSide: BorderSide(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
