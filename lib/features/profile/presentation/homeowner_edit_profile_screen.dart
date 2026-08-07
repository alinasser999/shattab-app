import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import 'providers/homeowner_profile_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

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
      setState(() => _error = context.l10n.nameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(homeownerProfileControllerProvider.notifier)
          .save(
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
      if (mounted) setState(() => _error = context.l10n.profileError);
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
      title: context.l10n.editProfile,
      leading: IconButton(
        tooltip: context.l10n.back,
        onPressed: _busy ? null : () => context.pop(),
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.sm,
          BatshSpacing.md,
          BatshSpacing.xxxxl,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brXxl,
            border: Border.all(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.62),
            ),
            boxShadow: BatshShadows.soft,
          ),
          child: Padding(
            padding: const EdgeInsets.all(BatshSpacing.md),
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
                  child: Text(
                    context.l10n.changePhoto,
                    style: BatshTypography.labelSm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: BatshSpacing.lg),
                BatshTextField(
                  controller: _nameCtrl,
                  label: context.l10n.profileNameLabel,
                  maxLength: 60,
                ),
                const SizedBox(height: BatshSpacing.gutter),
                BatshTextField(
                  label: context.l10n.profilePhoneLabel,
                  initialValue: currentPhone,
                  enabled: false,
                ),
                if (currentPhone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: BatshSpacing.xs),
                    child: Text(
                      context.l10n.phoneNotEditable,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: BatshSpacing.lg),
                _SectionDivider(context.l10n.housingData),
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
                _SectionDivider(context.l10n.interestAreas),
                const SizedBox(height: BatshSpacing.sm),
                _InterestChips(
                  selected: _interests,
                  onChanged: (v) => setState(() => _interests = v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: BatshSpacing.gutter),
                  Text(
                    _error!,
                    style: BatshTypography.labelMd.copyWith(
                      color: context.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: BatshSpacing.xl),
                BatshButton(
                  label: context.l10n.saveProfile,
                  onPressed: _busy ? null : _save,
                  isLoading: _busy,
                ),
                const SizedBox(height: BatshSpacing.xs),
                TextButton(
                  onPressed: _busy ? null : () => context.pop(),
                  child: Text(context.l10n.cancel),
                ),
                const SizedBox(height: BatshSpacing.xs),
              ],
            ),
          ),
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
    return Semantics(
      button: true,
      label: context.l10n.editProfileImage,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: context.colorScheme.primary, width: 2.5),
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
                  height: 120,
                  errorWidget: (_, _, _) => const _AvatarInitial(),
                )
              else
                const _AvatarInitial(),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: BatshIconSize.md,
                    color: context.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial();

  @override
  Widget build(BuildContext context) {
    return Text(
      'm',
      style: BatshTypography.displayLg.copyWith(
        color: context.colorScheme.onPrimaryContainer,
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
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: BatshSpacing.gutter),
        Expanded(child: Divider(color: context.colorScheme.outlineVariant)),
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
        Text(
          context.l10n.apartmentTypeLabel,
          style: BatshTypography.labelMd.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
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
                  color: selected
                      ? context.colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
              selected: selected,
              selectedColor: context.colorScheme.primaryContainer,
              backgroundColor: context.colorScheme.surfaceContainer,
              side: BorderSide(
                color: selected
                    ? context.colorScheme.primary
                    : context.colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BatshRadius.brDefault,
              ),
              onSelected: (_) => onChanged(selected ? null : apt),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.cityLabel,
          style: BatshTypography.labelMd.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer,
            borderRadius: BatshRadius.brDefault,
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                context.l10n.selectCity,
                style: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
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
        Text(
          context.l10n.districtLabel,
          style: BatshTypography.labelMd.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainer,
            borderRadius: BatshRadius.brDefault,
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: districts.contains(value) ? value : null,
              isExpanded: true,
              hint: Text(
                context.l10n.selectDistrict,
                style: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
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
  const _InterestChips({required this.selected, required this.onChanged});
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
              color: isSelected ? context.colorScheme.onPrimaryContainer : null,
            ),
          ),
          selected: isSelected,
          selectedColor: context.colorScheme.primaryContainer,
          backgroundColor: context.colorScheme.surfaceContainer,
          side: BorderSide(
            color: isSelected
                ? context.colorScheme.primary
                : context.colorScheme.outlineVariant,
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
