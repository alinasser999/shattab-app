import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../domain/onboarding_models.dart';
import '../providers/onboarding_provider.dart';

class ApartmentTypeScreen extends ConsumerStatefulWidget {
  const ApartmentTypeScreen({super.key});

  @override
  ConsumerState<ApartmentTypeScreen> createState() =>
      _ApartmentTypeScreenState();
}

class _ApartmentTypeScreenState extends ConsumerState<ApartmentTypeScreen> {
  ApartmentType? _selected;
  bool _busy = false;

  Future<void> _next() async {
    if (_selected == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .setApartmentType(_selected!);
      if (!mounted) return;
      context.go(Routes.onboardingHomeownerLocation);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(homeownerProfileProvider).value;
    _selected ??= existing?.apartmentType;
    final isMobile = context.isMobile;

    return BatshScaffold(
      title: S.apartmentTypeTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.md),
            Text(
              S.apartmentTypeTitle,
              style: isMobile
                  ? BatshTypography.headlineLgMobile
                  : BatshTypography.headlineLg,
            ),
            const SizedBox(height: BatshSpacing.lg),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: BatshSpacing.gutter,
              mainAxisSpacing: BatshSpacing.gutter,
              childAspectRatio: 1.1,
              children: ApartmentType.values.map((type) {
                final label = OnboardingCatalog.apartmentLabels[type] ?? '';
                final isSelected = _selected == type;
                return BatshCard(
                  selected: isSelected,
                  onTap: () => setState(() => _selected = type),
                  padding: const EdgeInsets.all(BatshSpacing.gutter),
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: BatshTypography.titleLg.copyWith(
                        color: isSelected
                            ? BatshColors.primary
                            : BatshColors.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.next,
              onPressed: _selected == null || _busy ? null : _next,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ],
        ),
      ),
    );
  }
}
