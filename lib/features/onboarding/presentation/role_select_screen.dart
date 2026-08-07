import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_card.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../../auth/domain/profile.dart';
import 'providers/onboarding_provider.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  UserRole? _selectedRole;
  final TextEditingController _nameController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_selectedRole == null) return;
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _error = context.l10n.nameNotEnough);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .selectRole(_selectedRole!, name);
      if (!mounted) return;
      if (_selectedRole == UserRole.homeowner) {
        context.go(Routes.onboardingHomeownerDetails);
      } else {
        context.go(Routes.onboardingContractorProfile);
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
    return BatshScaffold(
      showAppBar: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BatshSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:
                [
                      Text(
                        context.l10n.chooseRoleTitle,
                        style: BatshTypography.headlineLg,
                      ),
                      const SizedBox(height: BatshSpacing.sm),
                      Text(
                        context.l10n.chooseRoleSubtitle,
                        style: BatshTypography.bodyMd.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.lg),
                      _RoleCard(
                        role: UserRole.homeowner,
                        title: context.l10n.roleHomeowner,
                        subtitle: context.l10n.roleHomeownerSub,
                        icon: Icons.home_outlined,
                        selected: _selectedRole == UserRole.homeowner,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.homeowner),
                      ),
                      const SizedBox(height: BatshSpacing.gutter),
                      _RoleCard(
                        role: UserRole.contractor,
                        title: context.l10n.roleProfessional,
                        subtitle: context.l10n.roleContractorSub,
                        icon: Icons.engineering_outlined,
                        selected: _selectedRole == UserRole.contractor,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.contractor),
                      ),
                      const SizedBox(height: BatshSpacing.xl),
                      BatshTextField(
                        controller: _nameController,
                        label: context.l10n.displayNameLabel,
                        hint: context.l10n.nameExample,
                        errorText: _error,
                      ),
                      const SizedBox(height: BatshSpacing.lg),
                      BatshButton(
                        label: context.l10n.continueLabel,
                        onPressed: (_selectedRole == null || _busy)
                            ? null
                            : _continue,
                        isLoading: _busy,
                      ),
                    ]
                    .animate(interval: 60.ms)
                    .fadeIn(
                      duration: BatshMotion.slow,
                      curve: BatshMotion.easeOut,
                    )
                    .slideY(begin: 0.08, end: 0, curve: BatshMotion.easeOut),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BatshCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(BatshSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: selected
                  ? context.colorScheme.primary
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
                Text(title, style: BatshTypography.titleLg),
                const SizedBox(height: BatshSpacing.xs),
                Text(
                  subtitle,
                  style: BatshTypography.bodyMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AnimatedScale(
            scale: selected ? 1 : 0,
            duration: BatshMotion.fast,
            curve: BatshMotion.easeOut,
            child: Icon(
              Icons.check_circle_rounded,
              size: BatshIconSize.md,
              color: context.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
