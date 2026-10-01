import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/catalog/specialty_catalog.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/models/draft_photo.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/form_draft_store.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_initial_plate.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_text_field.dart';
import '../../../../core/widgets/photo_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';

/// The homeowner publish flow is deliberately stateful rather than three
/// routes. A recoverable network error, back navigation, or an edit action
/// therefore cannot discard a field the homeowner already entered.
class ProjectCreationFlow extends ConsumerStatefulWidget {
  const ProjectCreationFlow({super.key});

  @override
  ConsumerState<ProjectCreationFlow> createState() =>
      _ProjectCreationFlowState();
}

class _ProjectCreationFlowState extends ConsumerState<ProjectCreationFlow> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _areaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _scrollController = ScrollController();

  static const _draftKeyPrefix = 'brief:professionals-flow:';
  static const _anonymousDraftKey = '${_draftKeyPrefix}anonymous';
  static final _publishKeyRandom = math.Random.secure();
  String? _activeDraftKey;
  String? _draftOwnerId;
  String? _publishKey;
  Future<void> _draftWriteTail = Future<void>.value();
  int _step = 0;
  String? _selectedService;
  ApartmentType? _apartmentType;
  String? _city;
  String? _district;
  String _startTiming = 'flexible';
  bool _budgetUndecided = true;
  List<DraftPhoto> _photos = const [];
  bool _hydrated = false;
  bool _busy = false;
  String? _error;

  String get _draftKey {
    return _activeDraftKey ??
        _keyForUser(ref.read(currentSessionProvider)?.user.id);
  }

  String _keyForUser(String? userId) =>
      '$_draftKeyPrefix${userId ?? 'anonymous'}';

  String _newPublishKey() {
    final suffix = List.generate(
      32,
      (_) => _publishKeyRandom.nextInt(16).toRadixString(16),
    ).join();
    return 'flow-${DateTime.now().toUtc().microsecondsSinceEpoch}-$suffix';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_restoreDraft());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _areaController.dispose();
    _budgetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final sessionUserId = ref.read(currentSessionProvider)?.user.id;
    final userDraftKey = _keyForUser(sessionUserId);
    var activeDraftKey = userDraftKey;
    var draft = await FormDraftStore.read(userDraftKey);
    if (sessionUserId != null) {
      final guestDraft = await FormDraftStore.read(_anonymousDraftKey);
      if (guestDraft?['owner_id'] == sessionUserId) {
        draft = guestDraft;
        activeDraftKey = _anonymousDraftKey;
      }
    } else if (draft?['owner_id'] != null) {
      // A draft claimed by a previous account stays private to that account
      // until that same user signs in again.
      draft = null;
    }
    _activeDraftKey = activeDraftKey;
    _draftOwnerId = sessionUserId ?? draft?['owner_id'] as String?;
    if (!mounted) return;
    final homeowner = ref.read(homeownerProfileProvider).value;
    final restoredDraft = draft;
    if (restoredDraft == null || restoredDraft.isEmpty) {
      _publishKey = _newPublishKey();
      setState(() {
        _city = homeowner?.city;
        _district = homeowner?.district;
        _apartmentType = homeowner?.apartmentType;
        _hydrated = true;
      });
      await _writeDraftSnapshot();
      return;
    }
    _publishKey = restoredDraft['publish_key'] as String?;
    if (_publishKey == null || _publishKey!.isEmpty) {
      _publishKey = _newPublishKey();
    }
    final apartmentName = restoredDraft['apartment_type'] as String?;
    final restoredApartment = ApartmentType.values
        .cast<ApartmentType?>()
        .firstWhere(
          (value) => value?.name == apartmentName,
          orElse: () => null,
        );
    setState(() {
      _titleController.text = (restoredDraft['title'] as String?) ?? '';
      _descriptionController.text =
          (restoredDraft['description'] as String?) ?? '';
      _areaController.text = (restoredDraft['area'] as String?) ?? '';
      _budgetController.text = (restoredDraft['budget'] as String?) ?? '';
      _selectedService = restoredDraft['service'] as String?;
      _apartmentType = restoredApartment ?? homeowner?.apartmentType;
      _city = (restoredDraft['city'] as String?) ?? homeowner?.city;
      _district = (restoredDraft['district'] as String?) ?? homeowner?.district;
      _startTiming = (restoredDraft['start_timing'] as String?) ?? 'flexible';
      _budgetUndecided = (restoredDraft['budget_undecided'] as bool?) ?? true;
      _hydrated = true;
    });
    await _writeDraftSnapshot();
  }

  void _saveDraft() {
    if (!_hydrated) return;
    unawaited(_writeDraftSnapshot());
  }

  Future<void> _writeDraftSnapshot() {
    final draftKey = _draftKey;
    final snapshot = <String, dynamic>{
      'title': _titleController.text,
      'description': _descriptionController.text,
      'area': _areaController.text,
      'budget': _budgetController.text,
      'service': _selectedService,
      'apartment_type': _apartmentType?.name,
      'city': _city,
      'district': _district,
      'start_timing': _startTiming,
      'budget_undecided': _budgetUndecided,
      'publish_key': _publishKey ??= _newPublishKey(),
      if (_draftOwnerId != null) 'owner_id': _draftOwnerId,
    };
    final write = _draftWriteTail
        .catchError((Object _) {})
        .then((_) => FormDraftStore.write(draftKey, snapshot));
    _draftWriteTail = write;
    return write;
  }

  List<String> get _services {
    final popular = SpecialtyCatalog.popularRootKeys;
    return [
      ...popular,
      for (final root in SpecialtyCatalog.roots)
        if (!popular.contains(root.key)) root.key,
    ];
  }

  String _stepTitle(BuildContext context) => switch (_step) {
    0 => context.l10n.projectFlowTitleStepOne,
    1 => context.l10n.projectFlowTitleStepTwo,
    _ => context.l10n.projectFlowTitleStepThree,
  };

  String _serviceLabel(BuildContext context, String key) =>
      localizedSpecialtyDisplayLabel(context, key);

  Future<void> _next() async {
    setState(() => _error = null);
    if (_step == 0 && !_validateStepOne()) return;
    if (_step == 1 && !_validateStepTwo()) return;
    if (_step < 2) {
      setState(() => _step++);
      _saveDraft();
      await _scrollToTop();
      return;
    }
    await _publish();
  }

  bool _validateStepOne() {
    if (_selectedService == null) {
      setState(() => _error = context.l10n.chooseService);
      return false;
    }
    if (_titleController.text.trim().length < 2) {
      setState(() => _error = context.l10n.titleTooShort);
      return false;
    }
    if (_apartmentType == null || _city == null) {
      setState(() => _error = context.l10n.errorFillApartmentCity);
      return false;
    }
    return true;
  }

  bool _validateStepTwo() {
    if (_descriptionController.text.trim().length < 10) {
      setState(() => _error = context.l10n.descriptionTooShort);
      return false;
    }
    if (_areaController.text.trim().isNotEmpty &&
        int.tryParse(_areaController.text.trim()) == null) {
      setState(() => _error = context.l10n.areaInvalid);
      return false;
    }
    return true;
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  Future<void> _back() async {
    if (_busy) return;
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _step--;
      _error = null;
    });
    await _scrollToTop();
  }

  Future<void> _publish() async {
    if (_busy) return;
    if (ref.read(currentSessionProvider) == null) {
      final completed = await showSignInSheet(
        context,
        reason: context.l10n.signInToPost,
      );
      if (!completed || !mounted || ref.read(currentSessionProvider) == null) {
        return;
      }
    }
    _draftOwnerId = ref.read(currentSessionProvider)?.user.id;
    if (!_validateStepOne() || !_validateStepTwo()) {
      if (mounted) {
        setState(
          () => _step = _descriptionController.text.trim().length < 10 ? 1 : 0,
        );
      }
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Persist the logical key and latest form values before inserting. The
      // same key survives auth continuation, timeouts, and process restarts.
      final budgetNote = _budgetUndecided
          ? context.l10n.budgetUndecided
          : _budgetController.text.trim();
      await _writeDraftSnapshot();
      final brief = await ref
          .read(briefsControllerProvider.notifier)
          .createPost(
            apartmentType: _apartmentType!,
            city: _city!,
            district: _district,
            workDescription: _descriptionController.text.trim(),
            targetSpecialties: [_selectedService!],
            photos: _photos,
            projectTitle: _titleController.text.trim(),
            estimatedArea: int.tryParse(_areaController.text.trim()),
            budgetNote: budgetNote,
            startTiming: _startTiming,
            publishKey: _publishKey!,
          );
      if (!mounted) return;
      await _draftWriteTail.catchError((Object _) {});
      await FormDraftStore.clear(_draftKey);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProjectPublishedScreen(
            brief: brief,
            titleFallback: _titleController.text.trim(),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hydrated) {
      return const BatshScaffold(
        showAppBar: false,
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    return BatshScaffold(
      showAppBar: false,
      padding: EdgeInsets.zero,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _FlowHeader(step: _step, title: _stepTitle(context), onBack: _back),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  BatshSpacing.sectionH,
                  BatshSpacing.md,
                  BatshSpacing.sectionH,
                  BatshSpacing.xl,
                ),
                child: _step == 0
                    ? _buildStepOne(context)
                    : _step == 1
                    ? _buildStepTwo(context)
                    : _buildStepThree(context),
              ),
            ),
            _FlowFooter(
              step: _step,
              busy: _busy,
              error: _error,
              onBack: _step == 0 ? null : _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepOne(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.chooseService,
          style: BatshTypography.bodyMd.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.md),
        Wrap(
          spacing: BatshSpacing.sm,
          runSpacing: BatshSpacing.sm,
          children: [
            for (final service in _services.take(8))
              _ChoiceTile(
                label: _serviceLabel(context, service),
                icon: specialtyIcon(service),
                selected: _selectedService == service,
                onTap: () => setState(() {
                  _selectedService = service;
                  _error = null;
                  _saveDraft();
                }),
              ),
          ],
        ),
        const SizedBox(height: BatshSpacing.lg),
        BatshTextField(
          controller: _titleController,
          label: '${context.l10n.projectTitleLabel} *',
          hint: context.l10n.projectTitleHint,
          maxLength: 120,
          onChanged: (_) => _saveDraft(),
        ),
        const SizedBox(height: BatshSpacing.md),
        _SectionLabel(label: '${context.l10n.apartmentTypeLabel} *'),
        const SizedBox(height: BatshSpacing.xs),
        Wrap(
          spacing: BatshSpacing.xs,
          runSpacing: BatshSpacing.xs,
          children: [
            for (final type in ApartmentType.values)
              _PillChoice(
                label: OnboardingCatalog.apartmentLabels[type] ?? type.name,
                selected: _apartmentType == type,
                onTap: () => setState(() {
                  _apartmentType = type;
                  _saveDraft();
                }),
              ),
          ],
        ),
        const SizedBox(height: BatshSpacing.md),
        _SectionLabel(label: '${context.l10n.filterCity} *'),
        const SizedBox(height: BatshSpacing.xs),
        _LocationChoice(
          city: _city,
          district: _district,
          onTap: () => _chooseLocation(context),
        ),
      ],
    );
  }

  Widget _buildStepTwo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.contractorsWillSeeMatched,
          style: BatshTypography.bodyMd.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.md),
        BatshTextField(
          controller: _descriptionController,
          label: '${context.l10n.descriptionLabel} *',
          hint: context.l10n.descriptionWorkHint,
          maxLines: 7,
          maxLength: 2000,
          onChanged: (_) => _saveDraft(),
        ),
        const SizedBox(height: BatshSpacing.md),
        BatshTextField(
          controller: _areaController,
          label: context.l10n.areaLabel,
          hint: context.l10n.areaHint,
          keyboardType: TextInputType.number,
          onChanged: (_) => _saveDraft(),
        ),
        const SizedBox(height: BatshSpacing.md),
        _SectionLabel(label: context.l10n.budgetAndTimingTitle),
        const SizedBox(height: BatshSpacing.xs),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.budgetUndecided),
          value: _budgetUndecided,
          onChanged: (value) => setState(() {
            _budgetUndecided = value;
            _saveDraft();
          }),
        ),
        if (!_budgetUndecided)
          BatshTextField(
            controller: _budgetController,
            label: context.l10n.budgetLabel,
            hint: context.l10n.budgetHint,
            keyboardType: TextInputType.number,
            onChanged: (_) => _saveDraft(),
          ),
        const SizedBox(height: BatshSpacing.sm),
        _SectionLabel(label: context.l10n.startTimingLabel),
        const SizedBox(height: BatshSpacing.xs),
        Wrap(
          spacing: BatshSpacing.xs,
          runSpacing: BatshSpacing.xs,
          children: [
            _PillChoice(
              label: context.l10n.startFlexible,
              selected: _startTiming == 'flexible',
              onTap: () => _setTiming('flexible'),
            ),
            _PillChoice(
              label: context.l10n.startWithinThreeMonths,
              selected: _startTiming == 'within_3_months',
              onTap: () => _setTiming('within_3_months'),
            ),
            _PillChoice(
              label: context.l10n.startWithinMonth,
              selected: _startTiming == 'within_month',
              onTap: () => _setTiming('within_month'),
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.md),
        PhotoPicker(
          onChanged: (photos) => setState(() {
            _photos = photos;
            _saveDraft();
          }),
        ),
      ],
    );
  }

  Widget _buildStepThree(BuildContext context) {
    final title = _titleController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.projectFlowTitleStepThree,
          style: BatshTypography.headlineLgMobile,
        ),
        const SizedBox(height: BatshSpacing.md),
        _ReviewCard(
          title: context.l10n.reviewProjectDetails,
          onEdit: () => _editStep(0),
          children: [
            _ReviewLine(label: context.l10n.projectTitleLabel, value: title),
            _ReviewLine(
              label: context.l10n.filterCategory,
              value: _serviceLabel(context, _selectedService!),
            ),
            _ReviewLine(
              label: context.l10n.filterCity,
              value: [_city, _district].whereType<String>().join(' · '),
            ),
            _ReviewLine(
              label: context.l10n.apartmentTypeLabel,
              value:
                  OnboardingCatalog.apartmentLabels[_apartmentType!] ??
                  _apartmentType!.name,
            ),
          ],
        ),
        const SizedBox(height: BatshSpacing.md),
        _ReviewCard(
          title: context.l10n.descriptionLabel,
          onEdit: () => _editStep(1),
          children: [
            Text(
              _descriptionController.text.trim(),
              style: BatshTypography.bodyMd.copyWith(height: 1.5),
            ),
            const SizedBox(height: BatshSpacing.sm),
            _ReviewLine(
              label: context.l10n.areaLabel,
              value: _areaController.text.trim().isEmpty
                  ? context.l10n.notSpecified
                  : '${_areaController.text.trim()} م²',
            ),
            _ReviewLine(
              label: context.l10n.budgetLabel,
              value: _budgetUndecided
                  ? context.l10n.budgetUndecided
                  : _budgetController.text.trim(),
            ),
            _ReviewLine(
              label: context.l10n.startTimingLabel,
              value: _timingLabel(context),
            ),
          ],
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: BatshSpacing.md),
          _ReviewCard(
            title: context.l10n.reviewUploadedPhotos,
            onEdit: () => _editStep(1),
            children: [
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: BatshSpacing.xs),
                  itemBuilder: (_, index) =>
                      _DraftPhotoTile(photo: _photos[index]),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _chooseLocation(BuildContext context) async {
    final selected =
        await showModalBottomSheet<({String city, String? district})>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              _CreationLocationSheet(city: _city, district: _district),
        );
    if (!mounted || selected == null) return;
    setState(() {
      _city = selected.city;
      _district = selected.district;
      _saveDraft();
    });
  }

  void _setTiming(String value) => setState(() {
    _startTiming = value;
    _saveDraft();
  });

  String _timingLabel(BuildContext context) => switch (_startTiming) {
    'within_3_months' => context.l10n.startWithinThreeMonths,
    'within_month' => context.l10n.startWithinMonth,
    _ => context.l10n.startFlexible,
  };

  void _editStep(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
    unawaited(_scrollToTop());
  }
}

class ProjectPublishedScreen extends StatelessWidget {
  const ProjectPublishedScreen({
    super.key,
    required this.brief,
    required this.titleFallback,
  });

  final Brief brief;
  final String titleFallback;

  @override
  Widget build(BuildContext context) {
    final title = brief.projectTitle?.trim().isNotEmpty == true
        ? brief.projectTitle!.trim()
        : titleFallback;
    final photo = brief.photoUrls.firstOrNull;
    return BatshScaffold(
      showAppBar: false,
      padding: EdgeInsets.zero,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.sectionH,
              BatshSpacing.lg,
              BatshSpacing.sectionH,
              BatshSpacing.xl,
            ),
            children: [
              Align(
                alignment: AlignmentDirectional.topStart,
                child: IconButton(
                  tooltip: context.l10n.back,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
              const SizedBox(height: BatshSpacing.sm),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: context.colorScheme.secondaryContainer,
                  borderRadius: BatshRadius.brXxl,
                ),
                clipBehavior: Clip.antiAlias,
                child: photo != null && isDisplayableImageUrl(photo)
                    ? CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover)
                    : Stack(
                        children: [
                          const Positioned.fill(
                            child: Opacity(
                              opacity: .3,
                              child: BatshInitialPlate(name: 'Shattab'),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: context.colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: context.colorScheme.onSecondary,
                                size: 42,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: BatshSpacing.lg),
              Text(
                context.l10n.projectPublishedTitle,
                textAlign: TextAlign.center,
                style: BatshTypography.headlineLgMobile,
              ),
              const SizedBox(height: BatshSpacing.xs),
              Text(
                context.l10n.projectPublishedBody,
                textAlign: TextAlign.center,
                style: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: BatshSpacing.lg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerLowest,
                  borderRadius: BatshRadius.brLg,
                  border: Border.all(color: context.colorScheme.outlineVariant),
                  boxShadow: BatshShadows.soft,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BatshSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(title, style: BatshTypography.titleLg),
                      const SizedBox(height: BatshSpacing.xs),
                      Text(
                        [_cityLabel(context), brief.district]
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .join(' · '),
                        style: BatshTypography.bodyMd.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshButton(
                label: context.l10n.trackProject,
                icon: Icons.arrow_back_rounded,
                onPressed: () =>
                    context.push(Routes.homeownerBriefDetailPath(brief.id)),
              ),
              const SizedBox(height: BatshSpacing.sm),
              BatshButton(
                label: context.l10n.returnToProfessionals,
                style: BatshButtonStyle.secondary,
                onPressed: () => context.go(Routes.homeownerDiscover),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _cityLabel(BuildContext context) =>
      brief.city.isEmpty ? null : brief.city;
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.step,
    required this.title,
    required this.onBack,
  });

  final int step;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 148,
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: .24,
                  child: Image.asset(
                    'assets/images/login_bg_optimized.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.colorScheme.surface.withValues(alpha: .2),
                        context.colorScheme.surface.withValues(alpha: .86),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: .18,
                  child: SizedBox(
                    width: double.infinity,
                    height: 110,
                    child: CustomPaint(
                      painter: _ArchHeaderPainter(context.colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              BatshSpacing.sectionH,
              BatshSpacing.sm,
              BatshSpacing.sectionH,
              BatshSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: IconButton(
                    tooltip: context.l10n.back,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
                Text(
                  context.l10n.projectFlowStep(step + 1),
                  textAlign: TextAlign.center,
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= step
                                ? context.colorScheme.primary
                                : context.colorScheme.primary.withValues(
                                    alpha: .18,
                                  ),
                            borderRadius: BatshRadius.brFull,
                          ),
                        ),
                      ),
                      if (i != 2) const SizedBox(width: BatshSpacing.xs),
                    ],
                  ],
                ),
                const SizedBox(height: BatshSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: BatshTypography.headlineLgMobile,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowFooter extends StatelessWidget {
  const _FlowFooter({
    required this.step,
    required this.busy,
    required this.error,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool busy;
  final String? error;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.sectionH,
            BatshSpacing.sm,
            BatshSpacing.sectionH,
            BatshSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: BatshTypography.bodySm.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
              ],
              Row(
                children: [
                  if (onBack != null) ...[
                    Expanded(
                      child: BatshButton(
                        label: context.l10n.back,
                        style: BatshButtonStyle.secondary,
                        onPressed: busy ? null : onBack,
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                  ],
                  Expanded(
                    flex: 2,
                    child: BatshButton(
                      label: step == 2
                          ? context.l10n.publishProject
                          : context.l10n.next,
                      isLoading: busy,
                      onPressed: busy ? null : onNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brLg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 108,
          height: 94,
          padding: const EdgeInsets.all(BatshSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? context.colorScheme.primaryContainer
                : context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brLg,
            border: Border.all(
              color: selected
                  ? context.colorScheme.primary
                  : context.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: context.colorScheme.primary, size: 28),
              const SizedBox(height: BatshSpacing.xs),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: BatshTypography.labelSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillChoice extends StatelessWidget {
  const _PillChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brFull,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? context.colorScheme.primaryContainer
                : context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brFull,
            border: Border.all(
              color: selected
                  ? context.colorScheme.primary
                  : context.colorScheme.outlineVariant,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: BatshTypography.labelMd.copyWith(
              color: selected
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: BatshTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
  );
}

class _LocationChoice extends StatelessWidget {
  const _LocationChoice({
    required this.city,
    required this.district,
    required this.onTap,
  });

  final String? city;
  final String? district;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = [
      city,
      district,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BatshRadius.brMd,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brMd,
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: Text(
                label.isEmpty ? context.l10n.changeLocation : label,
                style: BatshTypography.bodyMd.copyWith(
                  color: label.isEmpty
                      ? context.colorScheme.onSurfaceVariant
                      : context.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.children,
    required this.onEdit,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: context.colorScheme.outlineVariant),
        boxShadow: BatshShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: BatshTypography.titleMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(context.l10n.editLabel),
                ),
              ],
            ),
            const Divider(height: BatshSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: BatshTypography.labelMd)),
        ],
      ),
    );
  }
}

class _DraftPhotoTile extends StatelessWidget {
  const _DraftPhotoTile({required this.photo});
  final DraftPhoto photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BatshRadius.brMd,
      child: photo.file != null
          ? Image.file(photo.file!, width: 88, height: 88, fit: BoxFit.cover)
          : photo.bytes != null
          ? Image.memory(photo.bytes!, width: 88, height: 88, fit: BoxFit.cover)
          : Container(
              width: 88,
              height: 88,
              color: context.colorScheme.surfaceContainer,
              child: const Icon(Icons.image_outlined),
            ),
    );
  }
}

class _CreationLocationSheet extends StatefulWidget {
  const _CreationLocationSheet({this.city, this.district});
  final String? city;
  final String? district;

  @override
  State<_CreationLocationSheet> createState() => _CreationLocationSheetState();
}

class _CreationLocationSheetState extends State<_CreationLocationSheet> {
  late String? _city = widget.city;
  late String? _district = widget.district;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final options = OnboardingCatalog.citiesAndDistricts
        .where(
          (item) =>
              item.city.contains(_query) ||
              item.districts.any((district) => district.contains(_query)),
        )
        .toList();
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BatshRadius.xxl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.sectionH,
          BatshSpacing.sm,
          BatshSpacing.sectionH,
          BatshSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BatshRadius.brFull,
              ),
            ),
            const SizedBox(height: BatshSpacing.md),
            Text(
              context.l10n.changeLocation,
              style: BatshTypography.titleLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
            TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: context.l10n.regionSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BatshRadius.brMd),
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: BatshSpacing.xs),
                itemBuilder: (_, index) {
                  final item = options[index];
                  final selected = item.city == _city;
                  return Column(
                    children: [
                      ListTile(
                        selected: selected,
                        selectedTileColor: context.colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BatshRadius.brMd,
                        ),
                        leading: Icon(Icons.location_city_outlined),
                        title: Text(item.city),
                        trailing: Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected ? context.colorScheme.primary : null,
                        ),
                        onTap: () => setState(() {
                          _city = item.city;
                          _district = null;
                        }),
                      ),
                      if (selected)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 40),
                          child: Wrap(
                            spacing: BatshSpacing.xs,
                            children: [
                              for (final district in item.districts)
                                _PillChoice(
                                  label: district,
                                  selected: _district == district,
                                  onTap: () =>
                                      setState(() => _district = district),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: BatshSpacing.md),
            BatshButton(
              label: context.l10n.confirmLocation,
              onPressed: _city == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop((city: _city!, district: _district)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchHeaderPainter extends CustomPainter {
  const _ArchHeaderPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final rect = Rect.fromLTWH(
      size.width * .22,
      8,
      size.width * .56,
      size.height * .82,
    );
    canvas.drawArc(rect, math.pi, math.pi, false, paint);
    canvas.drawLine(
      Offset(rect.left, rect.top + rect.height / 2),
      Offset(rect.left, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top + rect.height / 2),
      Offset(rect.right, size.height),
      paint,
    );
    for (var i = 0; i < 9; i++) {
      final x = i * size.width / 8;
      canvas.drawLine(
        Offset(x, size.height * .72),
        Offset(x + 30, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArchHeaderPainter oldDelegate) =>
      oldDelegate.color != color;
}
