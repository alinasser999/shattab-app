import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../domain/onboarding_models.dart';
import '../providers/onboarding_provider.dart';

class HomeownerDetailsScreen extends ConsumerStatefulWidget {
  const HomeownerDetailsScreen({super.key});

  @override
  ConsumerState<HomeownerDetailsScreen> createState() =>
      _HomeownerDetailsScreenState();
}

class _HomeownerDetailsScreenState
    extends ConsumerState<HomeownerDetailsScreen> {
  ApartmentType? _aptType;
  Set<String> _interests = {};
  bool _busy = false;
  bool _hydrated = false;

  static const Map<ApartmentType, IconData> _apartmentIcons = {
    ApartmentType.studio: Icons.weekend_outlined,
    ApartmentType.oneBedroom: Icons.bed_outlined,
    ApartmentType.twoBedroom: Icons.king_bed_outlined,
    ApartmentType.threeBedroomPlus: Icons.bedroom_parent_outlined,
    ApartmentType.duplex: Icons.stairs_outlined,
    ApartmentType.villa: Icons.villa_outlined,
    ApartmentType.penthouse: Icons.apartment_outlined,
  };

  static const Map<String, IconData> _interestIcons = {
    'paint': Icons.format_paint_outlined,
    'flooring': Icons.layers_outlined,
    'kitchen': Icons.countertops_outlined,
    'bathroom': Icons.bathtub_outlined,
    'electrical': Icons.electrical_services_outlined,
    'plumbing': Icons.plumbing_outlined,
    'full_reno': Icons.home_repair_service_outlined,
  };

  Future<void> _next() async {
    if (_aptType == null || _interests.isEmpty) return;
    // Snapshot inputs before any await: the upserts below invalidate
    // homeownerProfileProvider, which reruns build() and re-hydrates state
    // from a half-written row (wiping _interests mid-submit).
    final aptType = _aptType!;
    final interests = _interests.toList();
    setState(() => _busy = true);
    try {
      final ctrl = ref.read(onboardingControllerProvider.notifier);
      await ctrl.saveHomeownerDetails(
        apartmentType: aptType,
        interests: interests,
      );
      await ctrl.markComplete();
      if (!mounted) return;
      context.go(Routes.homeownerDiscover);
    } catch (e) {
      // Surfaces the raw error in the browser/device console; the snackbar
      // below only shows the mapped Arabic message.
      debugPrint('homeowner onboarding submit failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.map(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(homeownerProfileProvider).value;
    if (!_hydrated && !_busy && existing != null) {
      _aptType ??= existing.apartmentType;
      _interests = existing.renovationInterests.toSet();
      _hydrated = true;
    }
    return BatshScaffold(
      title: S.yourData,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.sm),
            Text(
              S.homeownerDetailsHint,
              style: BatshTypography.bodyMd.copyWith(
                color: BatshColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.md),
            BatshSectionHeader(title: S.apartmentType),
            const SizedBox(height: BatshSpacing.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: BatshSpacing.gutter,
              mainAxisSpacing: BatshSpacing.gutter,
              childAspectRatio: 1.1,
              children: ApartmentType.values.map((type) {
                final label = OnboardingCatalog.apartmentLabels[type] ?? '';
                final isSelected = _aptType == type;
                return BatshCard(
                  selected: isSelected,
                  onTap: () => setState(() => _aptType = type),
                  padding: const EdgeInsets.all(BatshSpacing.gutter),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _apartmentIcons[type],
                        size: 28,
                        color: isSelected
                            ? BatshColors.primary
                            : BatshColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: BatshSpacing.sm),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: BatshTypography.titleLg.copyWith(
                          color: isSelected
                              ? BatshColors.primary
                              : BatshColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshSectionHeader(title: S.interestAreas),
            const SizedBox(height: BatshSpacing.sm),
            Wrap(
              spacing: BatshSpacing.sm,
              runSpacing: BatshSpacing.sm,
              children: OnboardingCatalog.interestsCatalog.entries
                  .map(
                    (e) => BatshChip(
                      label: e.value,
                      icon: _interestIcons[e.key],
                      selected: _interests.contains(e.key),
                      onTap: () => setState(() {
                        if (_interests.contains(e.key)) {
                          _interests.remove(e.key);
                        } else {
                          _interests.add(e.key);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.done,
              onPressed:
                  _aptType == null || _interests.isEmpty || _busy ? null : _next,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ].animate(interval: 60.ms).fadeIn(
            duration: BatshMotion.slow,
            curve: BatshMotion.easeOut,
          ).slideY(
            begin: 0.08,
            end: 0,
            curve: BatshMotion.easeOut,
          ),
        ),
      ),
    );
  }
}
