import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/models/draft_photo.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/form_draft_store.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_draft_status.dart';
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

import 'package:batsh/core/theme/theme_extension.dart';

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
  Timer? _draftTimer;
  bool _draftRestored = false;
  bool _draftSaved = false;
  late final String _draftKey;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(currentSessionProvider)?.user.id ?? 'anonymous';
    _draftKey = 'brief:direct:${widget.contractorId}:$userId';
    _descCtrl.addListener(_scheduleDraftSave);
    unawaited(_restoreDraft());
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    unawaited(_persistDraft());
    _descCtrl.removeListener(_scheduleDraftSave);
    _descCtrl.dispose();
    super.dispose();
  }

  void _scheduleDraftSave() {
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
      _hydrated = true;
      _draftRestored = true;
      _draftSaved = true;
    });
  }

  Future<void> _persistDraft({bool showStatus = false}) async {
    final hasContent =
        _descCtrl.text.trim().isNotEmpty ||
        _apartmentType != null ||
        _city != null;
    if (!hasContent) {
      await FormDraftStore.clear(_draftKey);
      return;
    }
    await FormDraftStore.write(_draftKey, {
      'description': _descCtrl.text,
      'apartment_type': _apartmentType?.name,
      'city': _city,
      'district': _district,
    });
    if (showStatus && mounted) setState(() => _draftSaved = true);
  }

  Future<void> _submit() async {
    if (ref.read(currentSessionProvider) == null) {
      await showSignInSheet(context, reason: context.l10n.signInToSendRequest);
      if (!mounted) return;
      if (ref.read(currentSessionProvider) == null) return;
    }
    final desc = _descCtrl.text.trim();
    if (desc.length < 10) {
      setState(() => _error = context.l10n.errorDescriptionShort);
      return;
    }
    if (_apartmentType == null || _city == null) {
      setState(() => _error = context.l10n.errorFillApartmentCity);
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
      await FormDraftStore.clear(_draftKey);
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
      Text(
        context.l10n.sendBriefProjectDetails,
        style: BatshTypography.headlineMd,
      ),
      const SizedBox(height: BatshSpacing.xs),
      Text(
        context.l10n.sendBriefAllDetailsHint,
        style: BatshTypography.bodyMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      if (_draftRestored || _draftSaved) ...[
        const SizedBox(height: BatshSpacing.xs),
        BatshDraftStatus(restored: _draftRestored),
      ],
      const SizedBox(height: BatshSpacing.lg),
      _ApartmentTypeRow(
        selected: _apartmentType,
        onSelect: (t) => setState(() {
          _apartmentType = t;
          _draftRestored = false;
          _scheduleDraftSave();
        }),
      ),
      const SizedBox(height: BatshSpacing.gutter),
      _CityRow(
        selected: _city,
        onSelect: (c) => setState(() {
          _city = c;
          _district = null;
          _draftRestored = false;
          _scheduleDraftSave();
        }),
      ),
      const SizedBox(height: BatshSpacing.gutter),
      BatshTextField(
        controller: _descCtrl,
        label: context.l10n.sendBriefWorkDescLabel,
        hint: context.l10n.sendBriefWorkDescHint,
        maxLines: 6,
        maxLength: 2000,
        errorText: _error,
      ),
      const SizedBox(height: BatshSpacing.gutter),
      PhotoPicker(onChanged: (p) => _photos = p),
      const SizedBox(height: BatshSpacing.md),
      Text(
        context.l10n.phoneVisibleContractor,
        style: BatshTypography.labelMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: BatshSpacing.lg),
      if (_busy)
        const BatshLoading()
      else
        BatshButton(label: context.l10n.sendBriefButton, onPressed: _submit),
      const SizedBox(height: BatshSpacing.lg),
    ];
    return BatshScaffold(
      title: contractor?.businessName ?? context.l10n.sendBriefDefaultTitle,
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
          context.l10n.apartmentTypeLabel,
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
          context.l10n.cityLabel,
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
                selected: selected == c.city,
                onTap: () => onSelect(c.city),
              ),
          ],
        ),
      ],
    );
  }
}
