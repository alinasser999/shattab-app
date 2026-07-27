import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/models/draft_photo.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_loading.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_text_field.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../discovery/presentation/providers/discovery_providers.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../providers/briefs_providers.dart';

class SendBriefScreen extends ConsumerStatefulWidget {
  const SendBriefScreen({super.key, required this.contractorId});

  final String contractorId;

  @override
  ConsumerState<SendBriefScreen> createState() => _SendBriefScreenState();
}

class _SendBriefScreenState extends ConsumerState<SendBriefScreen> {
  final TextEditingController _descCtrl = TextEditingController();
  ApartmentType? _apartmentType;
  String? _city;
  String? _district;
  List<DraftPhoto> _photos = const [];
  bool _hydrated = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(currentSessionProvider) == null) {
      await showSignInSheet(context, reason: S.signInToSendRequest);
      if (!mounted) return;
      if (ref.read(currentSessionProvider) == null) return;
    }
    final desc = _descCtrl.text.trim();
    if (desc.length < 10) {
      setState(() => _error = S.errorDescriptionShort);
      return;
    }
    if (_apartmentType == null || _city == null) {
      setState(() => _error = S.errorFillApartmentCity);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(briefsControllerProvider.notifier)
          .createDirectRequest(
            contractorId: widget.contractorId,
            apartmentType: _apartmentType!,
            city: _city!,
            district: _district,
            workDescription: desc,
            photos: _photos,
          );
      if (!mounted) return;
      context.go(Routes.homeownerBriefSentPath(widget.contractorId));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ErrorMapper.map(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ho = ref.watch(homeownerProfileProvider).value;
    final contractor = ref
        .watch(contractorByIdProvider(widget.contractorId))
        .value;

    if (!_hydrated && ho != null) {
      _apartmentType = ho.apartmentType;
      _city = ho.city;
      _district = ho.district;
      _hydrated = true;
    }

    final reduced = MediaQuery.disableAnimationsOf(context);
    final items = <Widget>[
      const SizedBox(height: BatshSpacing.md),
      Text(S.sendBriefProjectDetails, style: BatshTypography.headlineMd),
      const SizedBox(height: BatshSpacing.xs),
      Text(
        S.sendBriefAllDetailsHint,
        style: BatshTypography.bodyMd.copyWith(
          color: BatshColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: BatshSpacing.lg),
      _ApartmentTypeRow(
        selected: _apartmentType,
        onSelect: (t) => setState(() => _apartmentType = t),
      ),
      const SizedBox(height: BatshSpacing.gutter),
      _CityRow(
        selected: _city,
        onSelect: (c) => setState(() {
          _city = c;
          _district = null;
        }),
      ),
      const SizedBox(height: BatshSpacing.gutter),
      BatshTextField(
        controller: _descCtrl,
        label: S.sendBriefWorkDescLabel,
        hint: S.sendBriefWorkDescHint,
        maxLines: 6,
        maxLength: 2000,
        errorText: _error,
      ),
      const SizedBox(height: BatshSpacing.gutter),
      PhotoPicker(onChanged: (p) => _photos = p),
      const SizedBox(height: BatshSpacing.md),
      Text(
        S.phoneVisibleContractor,
        style: BatshTypography.labelMd.copyWith(
          color: BatshColors.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: BatshSpacing.lg),
      if (_busy)
        const BatshLoading()
      else
        BatshButton(label: S.sendBriefButton, onPressed: _submit),
      const SizedBox(height: BatshSpacing.lg),
    ];
    return BatshScaffold(
      title: contractor?.businessName ?? S.sendBriefDefaultTitle,
      body: ListView(
        children: reduced
            ? items
            : items
                  .animate(interval: BatshMotion.staggerBase)
                  .fadeIn(duration: BatshMotion.normal)
                  .slideY(begin: 0.06, end: 0, curve: BatshMotion.easeOut),
      ),
    );
  }
}

class _ApartmentTypeRow extends StatelessWidget {
  const _ApartmentTypeRow({required this.selected, required this.onSelect});
  final ApartmentType? selected;
  final ValueChanged<ApartmentType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.apartmentTypeLabel,
          style: BatshTypography.labelMd.copyWith(
            color: BatshColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        Wrap(
          spacing: BatshSpacing.sm,
          runSpacing: BatshSpacing.sm,
          children: [
            for (final t in ApartmentType.values)
              BatshChip(
                label: OnboardingCatalog.apartmentLabels[t] ?? t.name,
                selected: selected == t,
                onTap: () => onSelect(t),
              ),
          ],
        ),
      ],
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.cityLabel,
          style: BatshTypography.labelMd.copyWith(
            color: BatshColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        Wrap(
          spacing: BatshSpacing.sm,
          runSpacing: BatshSpacing.sm,
          children: [
            for (final c in OnboardingCatalog.citiesAndDistricts)
              BatshChip(
                label: c.city,
                selected: selected == c.city,
                onTap: () => onSelect(c.city),
              ),
          ],
        ),
      ],
    );
  }
}
