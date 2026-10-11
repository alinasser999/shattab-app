import 'package:flutter/services.dart';
import '../theme/batsh_spacing.dart';
import 'package:flutter/material.dart';
import '../theme/professional_reference_theme.dart';
import 'batsh_search_bar.dart';

class ProfessionalReferenceChoice extends StatelessWidget {
  const ProfessionalReferenceChoice({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.semanticLabel,
    this.minimumHitHeight = true,
    this.singleSelection = false,
    this.showSelectionMark = true,
    this.onTap,
  });
  final String label;
  final IconData? icon;
  final String? semanticLabel;
  final bool selected, minimumHitHeight, singleSelection, showSelectionMark;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    inMutuallyExclusiveGroup: singleSelection,
    label: semanticLabel ?? label,
    child: ExcludeSemantics(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: selected
              ? ProfessionalReferenceTheme.action
              : ProfessionalReferenceTheme.navy,
          backgroundColor: selected
              ? ProfessionalReferenceTheme.cream
              : Colors.white,
          side: BorderSide(
            color: selected
                ? ProfessionalReferenceTheme.orange
                : const Color(0xffd9dce3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: ProfessionalReferenceTheme.text(
                  16,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (selected && showSelectionMark) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, size: 18),
            ],
          ],
        ),
      ),
    ),
  );
}

class ProfessionalReferenceBrand extends StatelessWidget {
  const ProfessionalReferenceBrand({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: label,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'شطّب',
              style: ProfessionalReferenceTheme.text(
                24,
                color: ProfessionalReferenceTheme.orange,
                weight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              'S H A T B',
              textDirection: TextDirection.ltr,
              style: ProfessionalReferenceTheme.text(
                7.5,
                color: ProfessionalReferenceTheme.orange,
                weight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(width: 5),
        const Icon(
          Icons.home_rounded,
          color: ProfessionalReferenceTheme.orange,
          size: 22,
        ),
      ],
    ),
  );
}

class ProfessionalReferenceSearch extends StatelessWidget {
  const ProfessionalReferenceSearch({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged, onSubmitted;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(
        context,
      ).colorScheme.copyWith(surface: const Color(0xfff2f3f7)),
    ),
    child: BatshSearchBar(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onClear: onClear,
      hintText: hint,
      height:
          56 *
          MediaQuery.textScalerOf(context).scale(1).clamp(1.0, double.infinity),
      borderRadius: BorderRadius.circular(16),
      outlined: false,
      plainInput: true,
      fontFamily: 'Tajawal',
      fontSize: 16,
      iconColor: ProfessionalReferenceTheme.navy,
      clearButtonLargeTarget: true,
    ),
  );
}

class ProfessionalReferenceCategory extends StatelessWidget {
  const ProfessionalReferenceCategory({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected, compact;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? ProfessionalReferenceTheme.orange
              : const Color(0xffe7e5e0),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 84 : 0),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 8 : 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: ProfessionalReferenceTheme.orange,
                  size: compact ? 24 : 28,
                ),
                SizedBox(height: compact ? 4 : 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: ProfessionalReferenceTheme.text(
                    14,
                    color: ProfessionalReferenceTheme.navy,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ProfessionalReferencePrimaryButton extends StatelessWidget {
  const ProfessionalReferencePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.footerSpacing = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading, footerSpacing;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: footerSpacing
          ? const EdgeInsets.only(top: BatshSpacing.sm, bottom: BatshSpacing.xs)
          : EdgeInsets.zero,
      child: Semantics(
        liveRegion: isLoading,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading || onPressed == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed!.call();
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: ProfessionalReferenceTheme.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xffd8dbe2),
              disabledForegroundColor: ProfessionalReferenceTheme.muted,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? reduced
                      ? const Icon(Icons.hourglass_top_rounded, size: 22)
                      : const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ProfessionalReferenceTheme.text(
                      19,
                      color: Colors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ProfessionalReferenceTextField extends StatelessWidget {
  const ProfessionalReferenceTextField({
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
    this.focusNode,
    this.autofillHints,
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
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofillHints: autofillHints,
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
          style: ProfessionalReferenceTheme.text(16),
          cursorColor: Theme.of(context).colorScheme.primary,
          cursorWidth: 2,
          decoration: InputDecoration(
            labelText: semanticLabel ?? label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: hint,
            errorMaxLines: 4,
            helperMaxLines: 4,
            helperText: helperText,
            errorText: errorText,
            suffixIcon: suffixIcon,
            counterText: '',
            hintStyle: ProfessionalReferenceTheme.text(
              16,
            ).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            errorStyle: ProfessionalReferenceTheme.text(
              16,
            ).copyWith(color: Theme.of(context).colorScheme.error),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
