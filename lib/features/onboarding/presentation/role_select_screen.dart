import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
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
      setState(() => _error = S.nameNotEnough);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(onboardingControllerProvider.notifier).selectRole(
            _selectedRole!,
            name,
          );
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
            children: [
              Text(
                S.chooseRoleTitle,
              style: BatshTypography.headlineLg,
              ),
              const SizedBox(height: BatshSpacing.sm),
              Text(
                S.chooseRoleSubtitle,
                style: BatshTypography.bodyMd
                    .copyWith(color: BatshColors.onSurfaceVariant),
              ),
              const SizedBox(height: BatshSpacing.lg),
              _RoleCard(
                role: UserRole.homeowner,
                title: S.roleHomeowner,
                subtitle: S.roleHomeownerSub,
                icon: Icons.home_outlined,
                selected: _selectedRole == UserRole.homeowner,
                onTap: () => setState(() => _selectedRole = UserRole.homeowner),
              ),
              const SizedBox(height: BatshSpacing.gutter),
              _RoleCard(
                role: UserRole.contractor,
                title: S.roleContractor,
                subtitle: S.roleContractorSub,
                icon: Icons.engineering_outlined,
                selected: _selectedRole == UserRole.contractor,
                onTap: () =>
                    setState(() => _selectedRole = UserRole.contractor),
              ),
              const SizedBox(height: BatshSpacing.xl),
              BatshTextField(
                controller: _nameController,
                label: S.displayNameLabel,
                hint: S.nameExample,
                errorText: _error,
              ),
              const SizedBox(height: BatshSpacing.lg),
              BatshButton(
                label: S.continueLabel,
                onPressed: (_selectedRole == null || _busy) ? null : _continue,
                isLoading: _busy,
              ),
            ].animate(interval: 60.ms).fadeIn(
              duration: BatshMotion.slow,
              curve: BatshMotion.easeOut,
            ).slideY(
              begin: 0.08,
              end: 0,
              curve: BatshMotion.easeOut,
            ),
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
                  ? BatshColors.primary
                  : BatshColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: selected ? BatshColors.onPrimary : BatshColors.primary,
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
                  style: BatshTypography.bodyMd
                      .copyWith(color: BatshColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          AnimatedScale(
            scale: selected ? 1 : 0,
            duration: BatshMotion.fast,
            curve: BatshMotion.easeOut,
            child: const Icon(
              Icons.check_circle_rounded,
              size: 22,
              color: BatshColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
