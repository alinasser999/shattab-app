import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/batsh_colors.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
            child: Text(
              label!,
              style: BatshTypography.labelMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
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
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            errorText: errorText,
            suffixIcon: suffixIcon,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
