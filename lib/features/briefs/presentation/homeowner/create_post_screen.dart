import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_loading.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_text_field.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../providers/briefs_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _descCtrl = TextEditingController();
  ApartmentType? _apartmentType;
  String? _city;
  String? _district;
  final Set<String> _targetSpecialties = {};
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
      setState(() => _error = 'اكتب تفاصيل أكتر');
      return;
    }
    if (_apartmentType == null || _city == null) {
      setState(() => _error = 'املا نوع الشقة والمحافظة');
      return;
    }
    if (_targetSpecialties.isEmpty) {
      setState(() => _error = 'اختار تخصص أو أكتر');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(briefsControllerProvider.notifier).createPost(
            apartmentType: _apartmentType!,
            city: _city!,
            district: _district,
            workDescription: desc,
            targetSpecialties: _targetSpecialties.toList(),
            photos: _photos,
          );
      if (!mounted) return;
      context.go('/h/requests');
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
    if (!_hydrated && ho != null) {
      _apartmentType = ho.apartmentType;
      _city = ho.city;
      _district = ho.district;
      _hydrated = true;
    }

    return BatshScaffold(
      title: 'بوست جديد',
      body: ListView(
        children: [
          const SizedBox(height: BatshSpacing.md),
          Text('اكتب اللي محتاجه',
              style: BatshTypography.headlineMd),
          const SizedBox(height: BatshSpacing.xs),
          Text('المقاولين اللي بتخصصاتهم وأماكنهم تطابق هيشوفوا البوست.',
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant)),
          const SizedBox(height: BatshSpacing.lg),
          BatshTextField(
            controller: _descCtrl,
            label: 'وصف الشغل',
            hint: 'مثال: محتاج حد يدهن الشقة كاملة…',
            maxLines: 6,
            maxLength: 2000,
            errorText: _error,
          ),
          const SizedBox(height: BatshSpacing.gutter),
          _SectionLabel('بدور على مين؟'),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: [
              for (final e in OnboardingCatalog.specialtiesCatalog.entries)
                BatshChip(
                  label: e.value,
                  selected: _targetSpecialties.contains(e.key),
                  onTap: () => setState(() {
                    if (_targetSpecialties.contains(e.key)) {
                      _targetSpecialties.remove(e.key);
                    } else {
                      _targetSpecialties.add(e.key);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: BatshSpacing.gutter),
          _SectionLabel('نوع الشقة'),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: [
              for (final t in ApartmentType.values)
                BatshChip(
                  label: OnboardingCatalog.apartmentLabels[t] ?? t.name,
                  selected: _apartmentType == t,
                  onTap: () => setState(() => _apartmentType = t),
                ),
            ],
          ),
          const SizedBox(height: BatshSpacing.gutter),
          _SectionLabel('المحافظة'),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: [
              for (final c in OnboardingCatalog.citiesAndDistricts)
                BatshChip(
                  label: c.city,
                  selected: _city == c.city,
                  onTap: () => setState(() => _city = c.city),
                ),
            ],
          ),
          const SizedBox(height: BatshSpacing.gutter),
          PhotoPicker(onChanged: (p) => _photos = p),
          const SizedBox(height: BatshSpacing.md),
          Text(
            'رقم تليفونك هيظهر للمقاولين اللي يشوفوا البوست.',
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant),
          ),
          const SizedBox(height: BatshSpacing.lg),
          if (_busy) const BatshLoading() else BatshButton(
            label: 'انشر البوست',
            onPressed: _submit,
          ),
          const SizedBox(height: BatshSpacing.lg),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: BatshTypography.labelMd
            .copyWith(color: BatshColors.onSurfaceVariant));
  }
}
