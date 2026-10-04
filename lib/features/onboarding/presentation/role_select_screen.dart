import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/professional_reference_theme.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_card.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../../../core/widgets/professional_reference_primitives.dart';
import '../../auth/domain/profile.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/onboarding_draft_provider.dart';
import 'providers/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  UserRole? _selectedRole;
  final TextEditingController _nameController = TextEditingController();
  bool _busy = false;
  bool _hydrated = false;
  String? _roleError;
  String? _nameError;
  String? _saveError;
  final FocusNode _roleFocus = FocusNode(debugLabel: 'account type');
  final FocusNode _nameFocus = FocusNode(debugLabel: 'personal name');

  @override
  void dispose() {
    _nameController.dispose();
    _roleFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _continue(Profile? profile) async {
    final locked = profile?.roleSelectionLocked ?? true;
    final role = locked ? profile?.role : _selectedRole;
    final name = _nameController.text.trim();
    setState(() {
      _roleError = !locked && role == null
          ? context.l10n.onboardingRoleRequired
          : null;
      _nameError = name.length < 2 ? context.l10n.onboardingNameRequired : null;
      _saveError = null;
    });
    if ((!locked && role == null) || name.length < 2 || profile == null) {
      if (!locked && role == null) {
        FocusScope.of(context).requestFocus(_roleFocus);
      } else if (name.length < 2) {
        if (role == UserRole.homeowner) {
          _focusAndReveal(_nameFocus);
        } else {
          FocusScope.of(context).requestFocus(_nameFocus);
        }
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final controller = ref.read(onboardingControllerProvider.notifier);
      if (locked) {
        if (name != profile.fullName.trim()) {
          await controller.updateFullName(name);
        }
      } else {
        await controller.selectRole(role!, name);
      }
      if (!mounted) return;
      final destination = locked
          ? _firstMissingStep(profile.role, name)
          : role == UserRole.homeowner
          ? Routes.onboardingHomeownerDetails
          : Routes.onboardingContractorProfile;
      context.go(destination);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saveError = ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _firstMissingStep(UserRole role, String name) {
    if (role == UserRole.homeowner) {
      final homeowner = ref.read(homeownerProfileProvider).value;
      return homeowner != null &&
              homeowner.hasApartmentType &&
              homeowner.hasInterests
          ? Routes.onboardingHomeownerLocation
          : Routes.onboardingHomeownerDetails;
    }
    final contractor = ref.read(contractorProfileProvider).value;
    return contractor != null &&
            contractor.hasRequiredIdentity(responsibleName: name)
        ? Routes.onboardingContractorServices
        : Routes.onboardingContractorProfile;
  }

  void _focusAndReveal(FocusNode focusNode) {
    FocusScope.of(context).requestFocus(focusNode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = focusNode.context;
      if (!mounted || targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.16,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.value;
    final draft = ref.watch(onboardingDraftProvider);
    if (!_hydrated && !profileAsync.isLoading && profile != null) {
      _selectedRole = profile.roleSelectionLocked ? profile.role : draft.role;
      _nameController.text = draft.fullNameEdited
          ? draft.fullName
          : profile.fullName;
      _hydrated = true;
    }

    if (profileAsync.isLoading) {
      return BatshScaffold(
        showAppBar: false,
        animateEntrance: false,
        body: const BatshSkeletonRegion(
          child: BatshListSkeleton(count: 2, height: 72),
        ),
      );
    }
    if (profile == null || profileAsync.hasError) {
      return BatshScaffold(
        showAppBar: false,
        animateEntrance: false,
        body: BatshError(
          message: profileAsync.hasError
              ? ErrorMapper.map(profileAsync.error!)
              : null,
          onRetry: () => ref.read(currentProfileProvider.notifier).refresh(),
        ),
      );
    }

    final locked = profile.roleSelectionLocked;
    final selectedRole = locked ? profile.role : _selectedRole;
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (selectedRole == null || selectedRole == UserRole.homeowner) {
      return Theme(
        data: ProfessionalReferenceTheme.scopedTheme(Theme.of(context)),
        child: Builder(
          builder: (referenceContext) => _buildReferenceRolePage(
            referenceContext,
            profile: profile,
            locked: locked,
            selectedRole: selectedRole,
            reduced: reduced,
          ),
        ),
      );
    }
    return PopScope<void>(
      canPop: false,
      child: BatshScaffold(
        showAppBar: false,
        animateEntrance: false,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: BatshSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OnboardingProgressHeader(
                  step: 1,
                  stepLabel: context.l10n.onboardingStepRole,
                ),
                const SizedBox(height: BatshSpacing.xl),
                Text(
                  context.l10n.chooseRoleTitle,
                  style: BatshTypography.headlineLg,
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  locked
                      ? context.l10n.onboardingRoleLocked
                      : context.l10n.chooseRoleSubtitle,
                  style: BatshTypography.bodyMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: BatshSpacing.lg),
                Focus(
                  focusNode: _roleFocus,
                  child: Semantics(
                    container: true,
                    focusable: true,
                    label: context.l10n.chooseRoleTitle,
                    child: locked
                        ? _RoleCard(
                            title: profile.role == UserRole.homeowner
                                ? context.l10n.roleHomeowner
                                : context.l10n.roleProfessional,
                            subtitle: profile.role == UserRole.homeowner
                                ? context.l10n.roleHomeownerSub
                                : context.l10n.roleContractorSub,
                            icon: profile.role == UserRole.homeowner
                                ? Icons.home_outlined
                                : Icons.engineering_outlined,
                            selected: true,
                            enabled: false,
                            reduced: reduced,
                            semanticLabel: context.l10n.onboardingRoleLocked,
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _RoleCard(
                                title: context.l10n.roleHomeowner,
                                subtitle: context.l10n.roleHomeownerSub,
                                icon: Icons.home_outlined,
                                selected: selectedRole == UserRole.homeowner,
                                enabled: !_busy,
                                reduced: reduced,
                                onTap: () {
                                  setState(() {
                                    _selectedRole = UserRole.homeowner;
                                    _roleError = null;
                                    _saveError = null;
                                  });
                                  ref
                                      .read(onboardingDraftProvider.notifier)
                                      .updateRole(UserRole.homeowner);
                                },
                              ),
                              const SizedBox(height: BatshSpacing.gutter),
                              _RoleCard(
                                title: context.l10n.roleProfessional,
                                subtitle: context.l10n.roleContractorSub,
                                icon: Icons.engineering_outlined,
                                selected: selectedRole == UserRole.contractor,
                                enabled: !_busy,
                                reduced: reduced,
                                onTap: () {
                                  setState(() {
                                    _selectedRole = UserRole.contractor;
                                    _roleError = null;
                                    _saveError = null;
                                  });
                                  ref
                                      .read(onboardingDraftProvider.notifier)
                                      .updateRole(UserRole.contractor);
                                },
                              ),
                            ],
                          ),
                  ),
                ),
                if (_roleError != null) ...[
                  const SizedBox(height: BatshSpacing.sm),
                  _InlineStatus(message: _roleError!),
                ],
                const SizedBox(height: BatshSpacing.xl),
                Focus(
                  focusNode: _nameFocus,
                  child: BatshTextField(
                    controller: _nameController,
                    label: context.l10n.professionalNameLabel,
                    hint: context.l10n.professionalNameHint,
                    errorText: _nameError,
                    enabled: !_busy,
                    onChanged: (value) {
                      ref
                          .read(onboardingDraftProvider.notifier)
                          .updateFullName(value);
                      if (_nameError != null || _saveError != null) {
                        setState(() {
                          _nameError = null;
                          _saveError = null;
                        });
                      }
                    },
                  ),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: BatshSpacing.md),
                  _InlineStatus(message: _saveError!),
                ],
                if (_busy) ...[
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
                const SizedBox(height: BatshSpacing.lg),
                BatshButton(
                  label: context.l10n.continueLabel,
                  onPressed: _busy ? null : () => _continue(profile),
                  isLoading: _busy,
                  animate: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceRolePage(
    BuildContext context, {
    required Profile profile,
    required bool locked,
    required UserRole? selectedRole,
    required bool reduced,
  }) {
    final content = <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ProfessionalReferenceBrand(label: context.l10n.appName),
      ),
      const SizedBox(height: BatshSpacing.xl),
      OnboardingProgressHeader(
        step: 1,
        stepLabel: context.l10n.onboardingStepRole,
        referenceStyle: true,
      ),
      const SizedBox(height: BatshSpacing.xl),
      Semantics(
        header: true,
        child: Text(
          context.l10n.chooseRoleTitle,
          style: ProfessionalReferenceTheme.text(28, weight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: BatshSpacing.sm),
      Text(
        locked
            ? context.l10n.onboardingRoleLocked
            : context.l10n.chooseRoleSubtitle,
        style: ProfessionalReferenceTheme.text(
          16,
          color: ProfessionalReferenceTheme.muted,
        ),
      ),
      const SizedBox(height: BatshSpacing.lg),
      Focus(
        focusNode: _roleFocus,
        child: Semantics(
          container: true,
          focusable: true,
          label: context.l10n.chooseRoleTitle,
          child: locked
              ? _RoleCard(
                  title: context.l10n.roleHomeowner,
                  subtitle: context.l10n.roleHomeownerSub,
                  icon: Icons.home_outlined,
                  selected: true,
                  enabled: false,
                  reduced: reduced,
                  referenceStyle: true,
                  semanticLabel: context.l10n.onboardingRoleLocked,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RoleCard(
                      title: context.l10n.roleHomeowner,
                      subtitle: context.l10n.roleHomeownerSub,
                      icon: Icons.home_outlined,
                      selected: selectedRole == UserRole.homeowner,
                      enabled: !_busy,
                      reduced: reduced,
                      referenceStyle: true,
                      onTap: () {
                        setState(() {
                          _selectedRole = UserRole.homeowner;
                          _roleError = null;
                          _saveError = null;
                        });
                        ref
                            .read(onboardingDraftProvider.notifier)
                            .updateRole(UserRole.homeowner);
                      },
                    ),
                    const SizedBox(height: BatshSpacing.gutter),
                    _RoleCard(
                      title: context.l10n.roleProfessional,
                      subtitle: context.l10n.roleContractorSub,
                      icon: Icons.engineering_outlined,
                      selected: selectedRole == UserRole.contractor,
                      enabled: !_busy,
                      reduced: reduced,
                      referenceStyle: true,
                      onTap: () {
                        setState(() {
                          _selectedRole = UserRole.contractor;
                          _roleError = null;
                          _saveError = null;
                        });
                        ref
                            .read(onboardingDraftProvider.notifier)
                            .updateRole(UserRole.contractor);
                      },
                    ),
                  ],
                ),
        ),
      ),
      if (_roleError != null) ...[
        const SizedBox(height: BatshSpacing.sm),
        _InlineStatus(message: _roleError!, referenceStyle: true),
      ],
      const SizedBox(height: BatshSpacing.xl),
      _ReferenceNameField(
        controller: _nameController,
        focusNode: _nameFocus,
        label: context.l10n.professionalNameLabel,
        hint: context.l10n.professionalNameHint,
        errorText: _nameError,
        enabled: !_busy,
        onChanged: (value) {
          ref.read(onboardingDraftProvider.notifier).updateFullName(value);
          if (_nameError != null || _saveError != null) {
            setState(() {
              _nameError = null;
              _saveError = null;
            });
          }
        },
      ),
      if (_saveError != null) ...[
        const SizedBox(height: BatshSpacing.md),
        _InlineStatus(message: _saveError!, referenceStyle: true),
      ],
      if (_busy) ...[
        const SizedBox(height: BatshSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            context.l10n.onboardingSaving,
            style: ProfessionalReferenceTheme.text(
              16,
              color: ProfessionalReferenceTheme.muted,
            ),
          ),
        ),
      ],
    ];

    return PopScope<void>(
      canPop: false,
      child: BatshScaffold(
        showAppBar: false,
        animateEntrance: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: BatshSpacing.lg,
                    bottom: BatshSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content,
                  ),
                ),
              ),
            ),
            ProfessionalReferencePrimaryButton(
              footerSpacing: true,
              label: context.l10n.continueLabel,
              onPressed: _busy ? null : () => _continue(profile),
              isLoading: _busy,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.reduced,
    this.referenceStyle = false,
    this.semanticLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final bool reduced;
  final bool referenceStyle;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: selected,
      inMutuallyExclusiveGroup: enabled,
      label: semanticLabel ?? '$title. $subtitle',
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: BatshCard(
          selected: selected,
          highlightColor: referenceStyle && selected
              ? ProfessionalReferenceTheme.cream
              : null,
          onTap: enabled ? onTap : null,
          padding: const EdgeInsets.all(BatshSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected
                      ? context.colorScheme.primary
                      : referenceStyle
                      ? ProfessionalReferenceTheme.cream
                      : context.colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: BatshIconSize.lg,
                  color: selected
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.primary,
                ),
              ),
              const SizedBox(width: BatshSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: referenceStyle
                          ? ProfessionalReferenceTheme.text(
                              20,
                              weight: FontWeight.w700,
                            )
                          : BatshTypography.titleLg,
                    ),
                    const SizedBox(height: BatshSpacing.xs),
                    Text(
                      subtitle,
                      style: referenceStyle
                          ? ProfessionalReferenceTheme.text(
                              16,
                              color: ProfessionalReferenceTheme.muted,
                            )
                          : BatshTypography.bodyMd.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: BatshMotion.durationFor(reduced, BatshMotion.fast),
                curve: BatshMotion.curveFor(reduced, BatshMotion.easeOut),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: BatshIconSize.md,
                  color: context.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.message, this.referenceStyle = false});

  final String message;
  final bool referenceStyle;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: referenceStyle
          ? ProfessionalReferenceTheme.text(
              14,
              color: context.colorScheme.error,
              weight: FontWeight.w600,
            )
          : BatshTypography.bodySm.copyWith(color: context.colorScheme.error),
    ),
  );
}

class _ReferenceNameField extends StatelessWidget {
  const _ReferenceNameField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.errorText,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    textInputAction: TextInputAction.done,
    onChanged: onChanged,
    style: ProfessionalReferenceTheme.text(
      16,
      color: ProfessionalReferenceTheme.navy,
    ),
    cursorColor: ProfessionalReferenceTheme.orange,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      errorMaxLines: 3,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelStyle: ProfessionalReferenceTheme.text(
        20,
        color: ProfessionalReferenceTheme.muted,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.gutter,
        vertical: BatshSpacing.md,
      ),
      labelStyle: ProfessionalReferenceTheme.text(
        16,
        color: ProfessionalReferenceTheme.muted,
      ),
      hintStyle: ProfessionalReferenceTheme.text(
        16,
        color: ProfessionalReferenceTheme.muted,
      ),
      errorStyle: ProfessionalReferenceTheme.text(
        14,
        color: context.colorScheme.error,
        weight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffd9dce3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffd9dce3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: ProfessionalReferenceTheme.orange,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.colorScheme.error, width: 2),
      ),
    ),
  );
}
