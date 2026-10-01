import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../features/auth/domain/profile.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../router/routes.dart';
import '../theme/batsh_colors.dart';
import '../theme/batsh_icon_size.dart';
import '../theme/batsh_radius.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import '../theme/theme_extension.dart';
import '../widgets/batsh_pressable.dart';
import '../widgets/batsh_sheet.dart';
import 'debug_role_override.dart';

/// Mounts the debug switcher only when the surrounding app has a Riverpod
/// scope. Lightweight shell/widget tests can intentionally render a shell
/// without the app scope; those tests should not fail just because debug tools
/// are enabled by default in `flutter run`.
class DebugRoleSwitcherHost extends StatelessWidget {
  const DebugRoleSwitcherHost({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      ProviderScope.containerOf(context, listen: false);
    } on StateError {
      return const SizedBox.shrink();
    }
    return const DebugRoleSwitcher();
  }
}

/// Floating dev-only switcher between the homeowner and contractor shells.
///
/// The switch is a client-side view override. The account's real role remains
/// authoritative for data, writes, and Supabase authorization.
class DebugRoleSwitcher extends ConsumerWidget {
  const DebugRoleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(debugRoleOverrideProvider);
    final label = _label(context, override);

    return PositionedDirectional(
      bottom: 116,
      start: BatshSpacing.sm,
      child: BatshPressable(
        semanticLabel: label,
        onTap: () => _openMenu(context, ref, override),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsetsDirectional.fromSTEB(
            BatshSpacing.sm,
            BatshSpacing.xs,
            BatshSpacing.sm,
            BatshSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.colorScheme.inverseSurface.withValues(alpha: 0.92),
            borderRadius: BatshRadius.brFull,
            border: Border.all(color: BatshColors.brandGold),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                size: BatshIconSize.action,
                color: BatshColors.brandGold,
              ),
              const SizedBox(width: BatshSpacing.xxs),
              Text(
                label,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(BuildContext context, UserRole? override) {
    final role = switch (override) {
      UserRole.homeowner => context.l10n.debugRoleHomeowner,
      UserRole.contractor => context.l10n.debugRoleContractor,
      null => context.l10n.debugRoleSwitcher,
    };
    return '${context.l10n.debugMode}: $role';
  }

  void _openMenu(BuildContext context, WidgetRef ref, UserRole? override) {
    BatshSheet.show<void>(
      context,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(
        BatshSpacing.md,
        BatshSpacing.sm,
        BatshSpacing.md,
        BatshSpacing.md,
      ),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            sheetContext.l10n.debugRoleSwitcherTitle,
            textAlign: TextAlign.center,
            style: BatshTypography.titleMd.copyWith(
              color: sheetContext.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            sheetContext.l10n.debugRoleSwitcherBody,
            textAlign: TextAlign.center,
            style: BatshTypography.bodySm.copyWith(
              color: sheetContext.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          _option(
            sheetContext,
            icon: Icons.home_rounded,
            label: sheetContext.l10n.debugRoleHomeowner,
            active: override == UserRole.homeowner,
            onTap: () => _apply(sheetContext, ref, UserRole.homeowner),
          ),
          const SizedBox(height: BatshSpacing.xs),
          _option(
            sheetContext,
            icon: Icons.engineering_rounded,
            label: sheetContext.l10n.debugRoleContractor,
            active: override == UserRole.contractor,
            onTap: () => _apply(sheetContext, ref, UserRole.contractor),
          ),
          const SizedBox(height: BatshSpacing.xs),
          _option(
            sheetContext,
            icon: Icons.person_outline_rounded,
            label: sheetContext.l10n.debugRoleReal,
            active: override == null,
            onTap: () => _apply(sheetContext, ref, null),
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final foreground = active
        ? context.colorScheme.onPrimaryContainer
        : context.colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: BatshPressable(
        semanticLabel: label,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsetsDirectional.fromSTEB(
            BatshSpacing.sm,
            BatshSpacing.xs,
            BatshSpacing.sm,
            BatshSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: active
                ? context.colorScheme.primaryContainer
                : context.colorScheme.surfaceContainerLow,
            borderRadius: BatshRadius.brMd,
            border: Border.all(
              color: active
                  ? context.colorScheme.primary
                  : context.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: BatshIconSize.action),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: BatshTypography.bodyMd.copyWith(
                    color: foreground,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (active)
                Icon(
                  Icons.check_rounded,
                  color: context.colorScheme.primary,
                  size: BatshIconSize.action,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _apply(BuildContext sheetContext, WidgetRef ref, UserRole? role) {
    final router = GoRouter.of(sheetContext);
    ref.read(debugRoleOverrideProvider.notifier).set(role);
    Navigator.of(sheetContext).pop();

    if (role == UserRole.contractor) {
      router.go(Routes.contractorDashboard);
      return;
    }
    if (role == UserRole.homeowner) {
      router.go(Routes.homeownerHome);
      return;
    }

    final realRole = ref.read(currentProfileProvider).value?.role;
    router.go(
      realRole == UserRole.contractor
          ? Routes.contractorDashboard
          : Routes.homeownerHome,
    );
  }
}
