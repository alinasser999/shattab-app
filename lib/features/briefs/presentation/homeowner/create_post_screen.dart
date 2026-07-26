import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_loading.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_text_field.dart';
import '../../../../core/models/draft_photo.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.editing});

  /// When set, the screen edits this brief instead of creating a new one.
  /// Same form, same validation — only the destination differs, so the two
  /// flows cannot drift apart.
  final Brief? editing;

  bool get isEditing => editing != null;

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
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing == null) return;
    // Prefilling here rather than in build's hydration path: that path seeds
    // defaults from the homeowner's own profile, which would overwrite the
    // brief's actual values.
    _hydrated = true;
    _descCtrl.text = editing.workDescription;
    _apartmentType = editing.apartmentType;
    _city = editing.city;
    _district = editing.district;
    _targetSpecialties.addAll(editing.targetSpecialties);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(currentSessionProvider) == null) {
      await showSignInSheet(context, reason: S.signInToPost);
      if (!mounted) return;
      if (ref.read(currentSessionProvider) == null) return;
    }
    final desc = _descCtrl.text.trim();
    if (desc.length < 10) {
      setState(() => _error = S.errorWriteMoreDetails);
      return;
    }
    if (_apartmentType == null || _city == null) {
      setState(() => _error = S.errorFillApartmentCity);
      return;
    }
    if (_targetSpecialties.isEmpty) {
      setState(() => _error = S.errorSelectSpecialty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final editing = widget.editing;
      if (editing != null) {
        // Photos are left alone on edit: replacing them would mean re-uploading
        // images the homeowner never touched, and the picker starts empty.
        await ref.read(briefsControllerProvider.notifier).updateBrief(
              editing.id,
              apartmentType: _apartmentType!,
              city: _city!,
              district: _district,
              workDescription: desc,
              targetSpecialties: _targetSpecialties.toList(),
            );
      } else {
        await ref.read(briefsControllerProvider.notifier).createPost(
              apartmentType: _apartmentType!,
              city: _city!,
              district: _district,
              workDescription: desc,
              targetSpecialties: _targetSpecialties.toList(),
              photos: _photos,
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isEditing
                ? S.changesSaved
                : S.postCreatedSuccess)),
      );
      if (widget.isEditing) {
        Navigator.of(context).maybePop();
      } else {
        context.go(Routes.homeownerRequests);
      }
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
    if (!_hydrated && ho != null) {
      _apartmentType = ho.apartmentType;
      _city = ho.city;
      _district = ho.district;
      _hydrated = true;
    }

    final reduced = MediaQuery.of(context).disableAnimations;
    final items = <Widget>[
          const SizedBox(height: BatshSpacing.md),
          Text(S.writeWhatYouNeed,
              style: BatshTypography.headlineMd),
          const SizedBox(height: BatshSpacing.xs),
          Text(S.contractorsWillSeeMatched,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant)),
          const SizedBox(height: BatshSpacing.lg),
          BatshTextField(
            controller: _descCtrl,
            label: S.descriptionLabel,
            hint: S.descriptionWorkHint,
            maxLines: 6,
            maxLength: 2000,
            errorText: _error,
          ),
          const SizedBox(height: BatshSpacing.gutter),
          Text('${S.sectionLookingForWho} *',
              style: BatshTypography.labelMd
                  .copyWith(color: BatshColors.onSurfaceVariant)),
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
          Text('${S.apartmentTypeLabel} *',
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
                  selected: _apartmentType == t,
                  onTap: () => setState(() => _apartmentType = t),
                ),
            ],
          ),
          const SizedBox(height: BatshSpacing.gutter),
          Text('${S.cityLabel} *',
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
                  selected: _city == c.city,
                  onTap: () => setState(() => _city = c.city),
                ),
            ],
          ),
          const SizedBox(height: BatshSpacing.gutter),
          // Photo editing is not wired yet, so the picker is hidden rather than
          // shown as a control whose changes would be silently dropped.
          if (!widget.isEditing) ...[
            PhotoPicker(onChanged: (p) => _photos = p),
            const SizedBox(height: BatshSpacing.md),
          ],
          Text(
            S.phoneVisibleContractors,
            style: BatshTypography.labelMd
                .copyWith(color: BatshColors.onSurfaceVariant),
          ),
          const SizedBox(height: BatshSpacing.lg),
          if (_busy) const BatshLoading() else BatshButton(
            label: widget.isEditing
                ? S.saveChanges
                : S.createPostPublishButton,
            onPressed: _submit,
          ),
          const SizedBox(height: BatshSpacing.lg),
        ];
    return BatshScaffold(
      title: widget.isEditing ? S.editBriefTitle : S.createPostTitle,
      body: ListView(
        children: reduced
            ? items
            : items.animate(interval: BatshMotion.staggerBase).fadeIn(
                  duration: BatshMotion.normal,
                ).slideY(
                  begin: 0.06,
                  end: 0,
                  curve: BatshMotion.easeOut,
                ),
      ),
    );
  }
}


