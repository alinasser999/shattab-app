import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_chip.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../discovery/domain/contractor_listing.dart';
import '../../domain/onboarding_models.dart';
import '../providers/onboarding_draft_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_progress_header.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final TextEditingController _businessController = TextEditingController();
  File? _logo;
  bool _hydrated = false;
  bool _busy = false;
  bool _identitySaved = false;
  ProviderKind _kind = ProviderKind.contractor;
  String? _businessError;
  String? _saveError;
  String? _logoError;
  String? _logoPickerError;
  final FocusNode _businessFocus = FocusNode(debugLabel: 'business name');

  @override
  void dispose() {
    _businessController.dispose();
    _businessFocus.dispose();
    super.dispose();
  }

  void _back() => context.go(Routes.onboardingRoleSelect);

  Future<void> _pickLogo() async {
    try {
      final result = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (result == null || !mounted) return;
      final file = File(result.path);
      setState(() {
        _logo = file;
        _logoError = null;
        _logoPickerError = null;
      });
      ref
          .read(onboardingDraftProvider.notifier)
          .updateContractorIdentity(
            providerKind: _kind,
            businessName: _businessController.text,
            logoFile: file,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _logoPickerError = ErrorMapper.map(error));
    }
  }

  void _updateIdentityDraft() {
    ref
        .read(onboardingDraftProvider.notifier)
        .updateContractorIdentity(
          providerKind: _kind,
          businessName: _businessController.text,
          logoFile: _logo,
        );
  }

  void _selectKind(ProviderKind kind) {
    setState(() {
      _kind = kind;
      _businessError = null;
      _saveError = null;
      _logoError = null;
      _logoPickerError = null;
      _identitySaved = false;
    });
    _updateIdentityDraft();
  }

  Future<void> _continueWithoutLogo() async {
    ref
        .read(onboardingDraftProvider.notifier)
        .updateContractorIdentity(
          providerKind: _kind,
          businessName: _businessController.text,
          clearLogoFile: true,
        );
    if (!mounted) return;
    context.go(Routes.onboardingContractorServices);
  }

  Future<void> _retryLogo() async {
    final logo = _logo;
    if (logo == null) {
      await _continueWithoutLogo();
      return;
    }
    setState(() {
      _busy = true;
      _logoError = null;
      _saveError = null;
    });
    try {
      await ref.read(onboardingControllerProvider.notifier).uploadLogo(logo);
      ref
          .read(onboardingDraftProvider.notifier)
          .updateContractorIdentity(
            providerKind: _kind,
            businessName: _businessController.text,
            clearLogoFile: true,
          );
      if (!mounted) return;
      context.go(Routes.onboardingContractorServices);
    } catch (error) {
      if (!mounted) return;
      setState(() => _logoError = ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _next() async {
    final businessName = _businessController.text.trim();
    if (_kind.requiresBusinessName && businessName.length < 2) {
      setState(() {
        _businessError = context.l10n.identityBusinessRequired;
        _saveError = null;
      });
      FocusScope.of(context).requestFocus(_businessFocus);
      return;
    }
    setState(() {
      _businessError = null;
      _saveError = null;
      _logoError = null;
      _busy = true;
    });
    try {
      final controller = ref.read(onboardingControllerProvider.notifier);
      if (!_identitySaved) {
        await controller.setBusinessName(
          businessName: businessName,
          providerKind: _kind,
        );
        _identitySaved = true;
      }
      final logo = _logo;
      if (logo != null) {
        try {
          await controller.uploadLogo(logo);
          ref
              .read(onboardingDraftProvider.notifier)
              .updateContractorIdentity(
                providerKind: _kind,
                businessName: businessName,
                clearLogoFile: true,
              );
        } catch (error) {
          if (!mounted) return;
          setState(() => _logoError = ErrorMapper.map(error));
          return;
        }
      }
      if (!mounted) return;
      context.go(Routes.onboardingContractorServices);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractorAsync = ref.watch(contractorProfileProvider);
    final contractor = contractorAsync.value;
    final profileAsync = ref.watch(currentProfileProvider);
    final draft = ref.watch(onboardingDraftProvider);
    if (!_hydrated && !contractorAsync.isLoading && !profileAsync.isLoading) {
      if (draft.contractorIdentityEdited) {
        _kind = draft.providerKind ?? contractor?.providerKind ?? _kind;
        _businessController.text = draft.businessName;
        _logo = draft.contractorLogoFile;
      } else {
        _kind = contractor?.providerKind ?? _kind;
        _businessController.text = contractor?.businessName ?? '';
      }
      _hydrated = true;
    }

    final loadError = contractorAsync.hasError
        ? contractorAsync.error
        : profileAsync.hasError
        ? profileAsync.error
        : null;
    final loading = contractorAsync.isLoading || profileAsync.isLoading;
    final content = loadError != null
        ? BatshError(
            message: ErrorMapper.map(loadError),
            onRetry: () {
              ref.invalidate(contractorProfileProvider);
              ref.invalidate(currentProfileProvider);
            },
          )
        : loading
        ? const BatshSkeletonRegion(
            child: BatshListSkeleton(count: 2, height: 72),
          )
        : _form(context, contractor?.logoUrl);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: BatshScaffold(
        title: context.l10n.businessNameTitle,
        animateEntrance: false,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingProgressHeader(
                step: 2,
                stepLabel: context.l10n.onboardingStepContractorIdentity,
                onBack: _back,
              ),
              const SizedBox(height: BatshSpacing.lg),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, String? existingLogo) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      BatshSectionHeader(title: context.l10n.companyData),
      const SizedBox(height: BatshSpacing.sm),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          context.l10n.providerKindQuestion,
          style: BatshTypography.labelLg,
        ),
      ),
      const SizedBox(height: BatshSpacing.xs),
      Text(
        context.l10n.providerKindHelp,
        style: BatshTypography.bodySm.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: BatshSpacing.sm),
      Semantics(
        container: true,
        label: context.l10n.providerKindQuestion,
        child: Wrap(
          spacing: BatshSpacing.xs,
          runSpacing: BatshSpacing.xs,
          children: [
            for (final kind in ProviderKind.values)
              BatshChip(
                label: kind.label(context),
                icon: kind.icon,
                selected: _kind == kind,
                semanticLabel: kind.label(context),
                minimumHitHeight: true,
                singleSelection: true,
                showSelectionMark: true,
                onTap: _busy ? null : () => _selectKind(kind),
              ),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.lg),
      Semantics(
        label: context.l10n.onboardingContractorLogoTitle,
        hint: context.l10n.onboardingContractorLogoHint,
        button: true,
        onTap: _busy ? null : _pickLogo,
        child: ExcludeSemantics(
          child: Center(
            child: GestureDetector(
              onTap: _busy ? null : _pickLogo,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainer,
                  borderRadius: BatshRadius.brXl,
                  border: Border.all(
                    color: context.colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BatshRadius.brXl,
                  child: _logo != null
                      ? Image.file(_logo!, fit: BoxFit.cover)
                      : existingLogo != null
                      ? CachedNetworkImage(
                          imageUrl: existingLogo,
                          fit: BoxFit.cover,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: context.colorScheme.onSurfaceVariant,
                              size: BatshIconSize.lg,
                            ),
                            const SizedBox(height: BatshSpacing.xs),
                            Text(
                              context.l10n.chooseImage,
                              style: BatshTypography.bodySm.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: BatshSpacing.xs),
      Text(
        '${context.l10n.onboardingContractorLogoTitle} ${context.l10n.optional}',
        textAlign: TextAlign.center,
        style: BatshTypography.labelMd.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: BatshSpacing.xs),
      Text(
        context.l10n.onboardingContractorLogoHint,
        textAlign: TextAlign.center,
        style: BatshTypography.bodySm.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
      if (_logoPickerError != null) ...[
        const SizedBox(height: BatshSpacing.sm),
        _InlineError(message: _logoPickerError!),
      ],
      Focus(
        focusNode: _businessFocus,
        child: BatshTextField(
          controller: _businessController,
          label: context.l10n.businessNameTitle,
          hint: _kind.requiresBusinessName
              ? context.l10n.businessNameHint
              : context.l10n.businessNameOptionalHint,
          helperText: _kind.requiresBusinessName
              ? context.l10n.required
              : context.l10n.optional,
          errorText: _businessError,
          enabled: !_busy,
          onChanged: (_) {
            setState(() {
              _identitySaved = false;
              _logoError = null;
              _logoPickerError = null;
              _businessError = null;
              _saveError = null;
            });
            _updateIdentityDraft();
          },
        ),
      ),
      if (_saveError != null) ...[
        const SizedBox(height: BatshSpacing.md),
        _InlineError(message: _saveError!),
      ],
      if (_logoError != null) ...[
        const SizedBox(height: BatshSpacing.md),
        _InlineError(
          message: '${context.l10n.onboardingLogoUploadFailed} $_logoError',
        ),
        const SizedBox(height: BatshSpacing.sm),
        BatshButton(
          label: context.l10n.onboardingRetryLogo,
          onPressed: _busy ? null : _retryLogo,
          isLoading: _busy,
          animate: false,
        ),
        const SizedBox(height: BatshSpacing.xs),
        BatshButton(
          label: context.l10n.onboardingContinueWithoutLogo,
          style: BatshButtonStyle.secondary,
          onPressed: _busy ? null : _continueWithoutLogo,
          animate: false,
        ),
      ] else if (_busy) ...[
        const SizedBox(height: BatshSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            context.l10n.onboardingSaving,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
      const SizedBox(height: BatshSpacing.xl),
      if (_logoError == null)
        BatshButton(
          label: context.l10n.next,
          onPressed: _busy ? null : _next,
          isLoading: _busy,
          animate: false,
        ),
      const SizedBox(height: BatshSpacing.lg),
    ],
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: BatshTypography.bodySm.copyWith(color: context.colorScheme.error),
    ),
  );
}
