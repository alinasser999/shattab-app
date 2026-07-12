import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import 'providers/homeowner_profile_providers.dart';

class HomeownerEditProfileScreen extends ConsumerStatefulWidget {
  const HomeownerEditProfileScreen({super.key});

  @override
  ConsumerState<HomeownerEditProfileScreen> createState() =>
      _HomeownerEditProfileScreenState();
}

class _HomeownerEditProfileScreenState
    extends ConsumerState<HomeownerEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  File? _newAvatar;
  bool _hydrated = false;
  bool _busy = false;
  String? _error;

  ApartmentType? _apartmentType;
  String? _city;
  String? _district;
  Set<String> _interests = {};

  List<String> get _districtsForCity {
    for (final entry in OnboardingCatalog.citiesAndDistricts) {
      if (entry.city == _city) return entry.districts;
    }
    return [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<File?> _pickImage() async {
    final r = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    return r == null ? null : File(r.path);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = S.nameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(homeownerProfileControllerProvider.notifier).save(
            newAvatarFile: _newAvatar,
            fullName: name,
            apartmentType: _apartmentType,
            city: _city,
            district: _district,
            renovationInterests: _interests.toList(),
          );
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (mounted) setState(() => _error = S.profileError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final hoProfile = ref.watch(homeownerProfileProvider).value;

    final currentAvatarUrl = profile?.avatarUrl;
    final currentName = profile?.fullName ?? '';
    final currentPhone = profile?.phone ?? '';

    if (!_hydrated && hoProfile != null) {
      _apartmentType = hoProfile.apartmentType;
      _city = hoProfile.city;
      _district = hoProfile.district;
      _interests = hoProfile.renovationInterests.toSet();
      _nameCtrl.text = currentName;
      _hydrated = true;
    }

    return BatshScaffold(
      title: S.editProfile,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: BatshSpacing.xl),
            _AvatarPicker(
              file: _newAvatar,
              existingUrl: currentAvatarUrl,
              name: currentName,
              onTap: () async {
                final f = await _pickImage();
                if (f != null) setState(() => _newAvatar = f);
              },
            ),
            const SizedBox(height: BatshSpacing.xs),
            Center(
              child: Text(S.changePhoto,
                  style: BatshTypography.labelSm
                      .copyWith(color: BatshColors.onSurfaceVariant)),
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshTextField(
              controller: _nameCtrl,
              label: S.profileNameLabel,
              maxLength: 60,
            ),
            const SizedBox(height: BatshSpacing.gutter),
            BatshTextField(
              label: S.profilePhoneLabel,
              initialValue: currentPhone,
              enabled: false,
            ),
            if (currentPhone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: BatshSpacing.xs),
                child: Text(
                  S.phoneNotEditable,
                  style: BatshTypography.labelSm
                      .copyWith(color: BatshColors.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: BatshSpacing.lg),
            _SectionDivider(S.housingData),
            const SizedBox(height: BatshSpacing.gutter),
            _ApartmentSelector(
              value: _apartmentType,
              onChanged: (v) => setState(() => _apartmentType = v),
            ),
            const SizedBox(height: BatshSpacing.gutter),
            _CityDropdown(
              value: _city,
              onChanged: (v) {
                setState(() {
                  _city = v;
                  _district = null;
                });
              },
            ),
            if (_city != null) ...[
              const SizedBox(height: BatshSpacing.gutter),
              _DistrictDropdown(
                value: _district,
                districts: _districtsForCity,
                onChanged: (v) => setState(() => _district = v),
              ),
            ],
            const SizedBox(height: BatshSpacing.lg),
            _SectionDivider(S.interestAreas),
            const SizedBox(height: BatshSpacing.sm),
            _InterestChips(
              selected: _interests,
              onChanged: (v) => setState(() => _interests = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: BatshSpacing.gutter),
              Text(
                _error!,
                style: BatshTypography.labelMd
                    .copyWith(color: BatshColors.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: BatshSpacing.xl),
            BatshButton(
              label: S.saveProfile,
              onPressed: _busy ? null : _save,
              isLoading: _busy,
            ),
            const SizedBox(height: BatshSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.file,
    required this.existingUrl,
    required this.name,
    required this.onTap,
  });
  final File? file;
  final String? existingUrl;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: BatshColors.primaryContainer,
          shape: BoxShape.circle,
          border: Border.all(color: BatshColors.primary, width: 2.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (file != null)
              Image.file(file!, fit: BoxFit.cover, width: 120, height: 120)
            else if (existingUrl != null)
              CachedNetworkImage(
                  imageUrl: existingUrl!,
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120)
            else
              Text(
                name.isNotEmpty ? name.characters.first : '؟',
                style: BatshTypography.displayLg
                    .copyWith(color: BatshColors.onPrimaryContainer),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BatshColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: BatshColors.background, width: 2),
                ),
                child: const Icon(Icons.camera_alt,
                    size: 18, color: BatshColors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: BatshTypography.labelMd.copyWith(
            color: BatshColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: BatshSpacing.gutter),
        const Expanded(
          child: Divider(color: BatshColors.outlineVariant),
        ),
      ],
    );
  }
}

class _ApartmentSelector extends StatelessWidget {
  const _ApartmentSelector({required this.value, required this.onChanged});
  final ApartmentType? value;
  final ValueChanged<ApartmentType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.apartmentTypeLabel,
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant)),
        const SizedBox(height: BatshSpacing.sm),
        Wrap(
          spacing: BatshSpacing.sm,
          runSpacing: BatshSpacing.sm,
          children: ApartmentType.values.map((apt) {
            final selected = apt == value;
            return ChoiceChip(
              label: Text(
                OnboardingCatalog.apartmentLabels[apt] ?? apt.name,
                style: BatshTypography.labelMd.copyWith(
                  color: selected ? BatshColors.onPrimaryContainer : null,
                ),
              ),
              selected: selected,
              selectedColor: BatshColors.primaryContainer,
              backgroundColor: BatshColors.surfaceContainer,
              side: BorderSide(
                color: selected
                    ? BatshColors.primary
                    : BatshColors.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BatshRadius.brDefault),
              onSelected: (_) => onChanged(selected ? null : apt),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({
    required this.value,
    required this.onChanged,
  });
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.cityLabel,
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant)),
        const SizedBox(height: BatshSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: BatshColors.surfaceContainer,
            borderRadius: BatshRadius.brDefault,
            border: Border.all(color: BatshColors.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(S.selectCity,
                  style: BatshTypography.bodyMd
                      .copyWith(color: BatshColors.onSurfaceVariant)),
              items: OnboardingCatalog.citiesAndDistricts.map((c) {
                return DropdownMenuItem(value: c.city, child: Text(c.city));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DistrictDropdown extends StatelessWidget {
  const _DistrictDropdown({
    required this.value,
    required this.districts,
    required this.onChanged,
  });
  final String? value;
  final List<String> districts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.districtLabel,
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant)),
        const SizedBox(height: BatshSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: BatshColors.surfaceContainer,
            borderRadius: BatshRadius.brDefault,
            border: Border.all(color: BatshColors.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: districts.contains(value) ? value : null,
              isExpanded: true,
              hint: Text(S.selectDistrict,
                  style: BatshTypography.bodyMd
                      .copyWith(color: BatshColors.onSurfaceVariant)),
              items: districts.map((d) {
                return DropdownMenuItem(value: d, child: Text(d));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _InterestChips extends StatelessWidget {
  const _InterestChips({
    required this.selected,
    required this.onChanged,
  });
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: BatshSpacing.sm,
      runSpacing: BatshSpacing.sm,
      children: OnboardingCatalog.interestsCatalog.entries.map((entry) {
        final isSelected = selected.contains(entry.key);
        return ChoiceChip(
          label: Text(
            entry.value,
            style: BatshTypography.labelMd.copyWith(
              color: isSelected ? BatshColors.onPrimaryContainer : null,
            ),
          ),
          selected: isSelected,
          selectedColor: BatshColors.primaryContainer,
          backgroundColor: BatshColors.surfaceContainer,
          side: BorderSide(
            color: isSelected ? BatshColors.primary : BatshColors.outlineVariant,
          ),
          shape: RoundedRectangleBorder(borderRadius: BatshRadius.brDefault),
          onSelected: (_) {
            final next = Set<String>.from(selected);
            if (isSelected) {
              next.remove(entry.key);
            } else {
              next.add(entry.key);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
