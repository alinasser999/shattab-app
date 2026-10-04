import 'package:flutter/services.dart';
import '../theme/batsh_spacing.dart';
import 'package:flutter/material.dart';
import '../theme/professional_reference_theme.dart';
import 'batsh_search_bar.dart';

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
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: ProfessionalReferenceTheme.orange, size: 28),
              const SizedBox(height: 8),
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
