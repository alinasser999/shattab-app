import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/form_draft_store.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_draft_status.dart';
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
import '../../../../core/widgets/batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

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
  Timer? _draftTimer;
  bool _draftRestored = false;
  bool _draftSaved = false;
  late final String _draftKey;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(currentSessionProvider)?.user.id ?? 'anonymous';
    _draftKey = 'brief:new:$userId';
    final editing = widget.editing;
    _descCtrl.addListener(_scheduleDraftSave);
    if (editing == null) {
      unawaited(_restoreDraft());
      return;
    }
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
    _draftTimer?.cancel();
    if (!widget.isEditing) unawaited(_persistDraft());
    _descCtrl.removeListener(_scheduleDraftSave);
    _descCtrl.dispose();
    super.dispose();
  }

  void _scheduleDraftSave() {
    if (widget.isEditing) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_persistDraft(showStatus: true));
    });
  }

  Future<void> _restoreDraft() async {
    final draft = await FormDraftStore.read(_draftKey);
    if (!mounted || draft == null || draft.isEmpty) return;
    final apartmentName = draft['apartment_type'] as String?;
    ApartmentType? restoredApartment;
    for (final value in ApartmentType.values) {
      if (value.name == apartmentName) restoredApartment = value;
    }
    setState(() {
      _descCtrl.text = (draft['description'] as String?) ?? '';
      _apartmentType = restoredApartment;
      _city = draft['city'] as String?;
      _district = draft['district'] as String?;
      _targetSpecialties
        ..clear()
        ..addAll(
          ((draft['specialties'] as List?) ?? const []).whereType<String>(),
        );
      _hydrated = true;
      _draftRestored = true;
      _draftSaved = true;
    });
  }

  Future<void> _persistDraft({bool showStatus = false}) async {
    if (widget.isEditing) return;
    final hasContent =
        _descCtrl.text.trim().isNotEmpty ||
        _apartmentType != null ||
        _city != null ||
        _targetSpecialties.isNotEmpty;
    if (!hasContent) {
      await FormDraftStore.clear(_draftKey);
      return;
    }
    await FormDraftStore.write(_draftKey, {
      'description': _descCtrl.text,
      'apartment_type': _apartmentType?.name,
      'city': _city,
      'district': _district,
      'specialties': _targetSpecialties.toList(),
    });
    if (showStatus && mounted) setState(() => _draftSaved = true);
  }

  Future<void> _submit() async {
    if (ref.read(currentSessionProvider) == null) {
      await showSignInSheet(context, reason: context.l10n.signInToPost);
      if (!mounted) return;
      if (ref.read(currentSessionProvider) == null) return;
    }
    final desc = _descCtrl.text.trim();
    if (desc.length < 10) {
      setState(() => _error = context.l10n.errorWriteMoreDetails);
      return;
    }
    if (_apartmentType == null || _city == null) {
      setState(() => _error = context.l10n.errorFillApartmentCity);
      return;
    }
    if (_targetSpecialties.isEmpty) {
      setState(() => _error = context.l10n.errorSelectSpecialty);
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
        await ref
            .read(briefsControllerProvider.notifier)
            .updateBrief(
              editing.id,
              apartmentType: _apartmentType!,
              city: _city!,
              district: _district,
              workDescription: desc,
              targetSpecialties: _targetSpecialties.toList(),
            );
      } else {
        await ref
            .read(briefsControllerProvider.notifier)
            .createPost(
              apartmentType: _apartmentType!,
              city: _city!,
              district: _district,
              workDescription: desc,
              targetSpecialties: _targetSpecialties.toList(),
              photos: _photos,
            );
      }
      if (!mounted) return;
      if (!widget.isEditing) await FormDraftStore.clear(_draftKey);
      if (!mounted) return;
      BatshSnack.success(
        context,
        widget.isEditing
            ? context.l10n.changesSaved
            : context.l10n.postCreatedSuccess,
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

    final reduced = MediaQuery.disableAnimationsOf(context);
    final items = <Widget>[
      const SizedBox(height: BatshSpacing.md),
      Text(context.l10n.writeWhatYouNeed, style: BatshTypography.headlineMd),
      const SizedBox(height: BatshSpacing.xs),
      Text(
        context.l10n.contractorsWillSeeMatched,
        style: BatshTypography.bodyMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      if (_draftRestored || _draftSaved) ...[
        const SizedBox(height: BatshSpacing.xs),
        BatshDraftStatus(restored: _draftRestored),
      ],
      const SizedBox(height: BatshSpacing.lg),
      BatshTextField(
        controller: _descCtrl,
        label: context.l10n.descriptionLabel,
        hint: context.l10n.descriptionWorkHint,
        maxLines: 6,
        maxLength: 2000,
        errorText: _error,
      ),
      const SizedBox(height: BatshSpacing.gutter),
      Text(
        '${context.l10n.sectionLookingForWho} *',
        style: BatshTypography.labelMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
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
                _draftRestored = false;
                _scheduleDraftSave();
              }),
            ),
        ],
      ),
      const SizedBox(height: BatshSpacing.gutter),
      Text(
        '${context.l10n.apartmentTypeLabel} *',
        style: BatshTypography.labelMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
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
              selected: _apartmentType == t,
              onTap: () => setState(() {
                _apartmentType = t;
                _draftRestored = false;
                _scheduleDraftSave();
              }),
            ),
        ],
      ),
      const SizedBox(height: BatshSpacing.gutter),
      Text(
        '${context.l10n.cityLabel} *',
        style: BatshTypography.labelMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
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
              selected: _city == c.city,
              onTap: () => setState(() {
                _city = c.city;
                _draftRestored = false;
                _scheduleDraftSave();
              }),
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
        context.l10n.phoneVisibleContractors,
        style: BatshTypography.labelMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: BatshSpacing.lg),
      if (_busy)
        const BatshLoading()
      else
        BatshButton(
          label: widget.isEditing
              ? context.l10n.saveChanges
              : context.l10n.createPostPublishButton,
          onPressed: _submit,
        ),
      const SizedBox(height: BatshSpacing.lg),
    ];
    return BatshScaffold(
      title: widget.isEditing
          ? context.l10n.editBriefTitle
          : context.l10n.createPostTitle,
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
