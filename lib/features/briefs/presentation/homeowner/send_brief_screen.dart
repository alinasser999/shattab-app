import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_loading.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_text_field.dart';
import '../../../../core/widgets/photo_picker.dart';
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
    final desc = _descCtrl.text.trim();
    if (desc.length < 10) {
      setState(() => _error = 'اكتب وصف للشغل على الأقل من ١٠ حروف');
      return;
    }
    if (_apartmentType == null || _city == null) {
      setState(() => _error = 'املا نوع الشقة والمحافظة');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(briefsControllerProvider.notifier).createDirectRequest(
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
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ho = ref.watch(homeownerProfileProvider).value;
    final contractor =
        ref.watch(contractorByIdProvider(widget.contractorId)).value;

    if (!_hydrated && ho != null) {
      _apartmentType = ho.apartmentType;
      _city = ho.city;
      _district = ho.district;
      _hydrated = true;
    }

    return BatshScaffold(
      title: contractor?.businessName ?? 'ابعت تفاصيل المشروع',
      body: ListView(
        children: [
          const SizedBox(height: BatshSpacing.md),
          Text('تفاصيل مشروعك',
              style: BatshTypography.headlineMd),
          const SizedBox(height: BatshSpacing.xs),
          Text('ابعت كل التفاصيل اللي محتاج المقاول يعرفها',
              style: BatshTypography.bodyMd.copyWith(
                  color: BatshColors.onSurfaceVariant)),
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
            label: 'وصف الشغل المطلوب',
            hint: 'مثال: محتاج تشطيب كامل…',
            maxLines: 6,
            maxLength: 2000,
            errorText: _error,
          ),
          const SizedBox(height: BatshSpacing.gutter),
          PhotoPicker(
            onChanged: (p) => _photos = p,
          ),
          const SizedBox(height: BatshSpacing.md),
          Text(
            'رقم تليفونك هيظهر للمقاول لما يستلم الطلب.',
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant),
          ),
          const SizedBox(height: BatshSpacing.lg),
          if (_busy) const BatshLoading() else BatshButton(
            label: 'ابعت الطلب',
            onPressed: _submit,
          ),
          const SizedBox(height: BatshSpacing.lg),
        ],
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
        Text('نوع الشقة',
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant)),
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
        Text('المحافظة',
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant)),
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
