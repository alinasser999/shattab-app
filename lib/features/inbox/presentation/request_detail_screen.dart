import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_card.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/contact_buttons.dart';
import '../../../core/widgets/photo_picker.dart';
import '../../../core/utils/error_mapper.dart';
import '../../auth/data/auth_repository.dart';
import '../../briefs/presentation/providers/briefs_providers.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../quotes/presentation/widgets/contractor_quote_cta.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  const RequestDetailScreen({super.key, required this.briefId});
  final String briefId;

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  ({String name, String phone})? _homeowner;
  bool _homeownerLoading = true;
  String? _homeownerError;

  Future<void> _fetchHomeowner(String homeownerId) async {
    try {
      final result =
          await ref.read(authRepositoryProvider).fetchProfileNameAndPhone(homeownerId);
      if (!mounted) return;
      setState(() {
        _homeowner = result;
        _homeownerLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _homeownerError = S.clientInfoFailed;
        _homeownerLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(briefByIdProvider(widget.briefId));
    return BatshScaffold(
      title: S.requestDetailTitle,
      body: async.when(
        loading: () => const _RequestDetailSkeleton(),
        error: (e, _) => BatshError(
              message: ErrorMapper.map(e),
              onRetry: () => ref.invalidate(briefByIdProvider(widget.briefId)),
            ),
        data: (brief) {
          if (brief == null) return const BatshError();
          // Trigger homeowner fetch once on first data load.
          if (_homeownerLoading && _homeownerError == null && _homeowner == null) {
            _fetchHomeowner(brief.homeownerId);
          }
          final date = intl.DateFormat.yMMMd('ar').format(brief.createdAt);
          final apt =
              OnboardingCatalog.apartmentLabels[brief.apartmentType] ??
                  brief.apartmentType.name;
          final place = brief.district != null
              ? '$apt - ${brief.city} - ${brief.district}'
              : '$apt - ${brief.city}';
          final showContact =
              _homeowner != null && _homeowner!.phone.isNotEmpty;
          final reduced = MediaQuery.of(context).disableAnimations;
          final items = <Widget>[
              const SizedBox(height: BatshSpacing.md),
              if (brief.photoUrls.isNotEmpty) ...[
                PhotoGallery(urls: brief.photoUrls),
                const SizedBox(height: BatshSpacing.lg),
              ],
              _LabeledCard(
                  label: S.workDescriptionLabel,
                  value: brief.workDescription),
              const SizedBox(height: BatshSpacing.gutter),
              _LabeledCard(label: S.workLocationLabel, value: place),
              const SizedBox(height: BatshSpacing.xs),
              Text('  $date',
                  style: BatshTypography.labelSm
                      .copyWith(color: BatshColors.onSurfaceVariant)),
              const SizedBox(height: BatshSpacing.xl),
              ContractorQuoteCta(briefId: brief.id),
              const SizedBox(height: BatshSpacing.lg),
              if (showContact) ...[
                Text(S.contactClient,
                    style: BatshTypography.labelMd
                        .copyWith(color: BatshColors.onSurfaceVariant)),
                const SizedBox(height: BatshSpacing.sm),
                WhatsAppButton(phone: _homeowner!.phone),
                const SizedBox(height: BatshSpacing.sm),
                CallButton(phone: _homeowner!.phone),
              ],
              if (_homeownerError != null)
                Padding(
                  padding: const EdgeInsets.only(top: BatshSpacing.sm),
                  child: Text(_homeownerError!,
                      style: BatshTypography.labelSm
                          .copyWith(color: BatshColors.error)),
                ),
              const SizedBox(height: BatshSpacing.lg),
          ];
          return ListView(
            children: reduced
                ? items
                : items.animate(interval: BatshMotion.staggerBase).fadeIn(
                      duration: BatshMotion.normal,
                    ).slideY(
                      begin: 0.06,
                      end: 0,
                      curve: BatshMotion.easeOut,
                    ),
          );
        },
      ),
    );
  }
}

class _RequestDetailSkeleton extends StatelessWidget {
  const _RequestDetailSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: BatshSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
          child: Column(
            children: [
              BatshShimmerBox(width: double.infinity, height: 120, borderRadius: BatshRadius.brLg),
              const SizedBox(height: BatshSpacing.gutter),
              BatshShimmerBox(width: double.infinity, height: 80, borderRadius: BatshRadius.brLg),
              const SizedBox(height: BatshSpacing.xs),
              BatshShimmerBox(width: 120, height: 12, borderRadius: BatshRadius.brSm),
              const SizedBox(height: BatshSpacing.xl),
              BatshShimmerBox(width: double.infinity, height: 48, borderRadius: BatshRadius.brMd),
              const SizedBox(height: BatshSpacing.lg),
              BatshShimmerBox(width: 100, height: 14, borderRadius: BatshRadius.brSm),
              const SizedBox(height: BatshSpacing.sm),
              BatshShimmerBox(width: double.infinity, height: 48, borderRadius: BatshRadius.brMd),
              const SizedBox(height: BatshSpacing.sm),
              BatshShimmerBox(width: double.infinity, height: 48, borderRadius: BatshRadius.brMd),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabeledCard extends StatelessWidget {
  const _LabeledCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return BatshCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: BatshTypography.labelMd
                  .copyWith(color: BatshColors.onSurfaceVariant)),
          const SizedBox(height: BatshSpacing.sm),
          Text(value, style: BatshTypography.bodyLg),
        ],
      ),
    );
  }
}