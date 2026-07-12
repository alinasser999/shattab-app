import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/router/routes.dart';
import '../../briefs/presentation/providers/briefs_providers.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/motion_mode_provider.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/batsh_empty_state.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/profile.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../discovery/presentation/providers/discovery_providers.dart';
import '../../discovery/presentation/widgets/contractor_showcase.dart';
import '../../saved/presentation/providers/saved_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => BatshScaffold(
        title: S.profileTitle,
        body: const _ProfileSkeleton(),
      ),
      error: (e, _) => BatshScaffold(
        title: S.profileTitle,
        body: BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return BatshScaffold(
            title: S.profileTitle,
            body: _GuestProfile(),
          );
        }
        if (profile.role == UserRole.contractor) {
          return _ContractorProfile(profile: profile);
        }
        return _HomeownerProfile(profile: profile);
      },
    );
  }
}

class _GuestProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BatshEmptyState(
              title: S.signInOrCreateAccount,
              icon: Icons.person_outline,
              action: BatshButton(
                label: S.signInSheetTitle,
                onPressed: () =>
                    showSignInSheet(context, reason: S.signInOrCreateAccount),
              ),
            ),
            TextButton(
              onPressed: () => context.push(Routes.login),
              child: Text(
                S.contractorSignInLink,
                style: BatshTypography.labelMd.copyWith(
                  color: BatshColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: BatshColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractorProfile extends ConsumerWidget {
  const _ContractorProfile({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(contractorByIdProvider(profile.id));

    return Scaffold(
      backgroundColor: BatshColors.background,
      body: listingAsync.when(
        loading: () => const BatshProfileSkeleton(),
        error: (_, _) =>
            _ProfileFallback(profile: profile, onSignOut: () => _confirmSignOut(context, ref)),
        data: (listing) {
          if (listing == null) {
            return _ProfileFallback(
                profile: profile, onSignOut: () => _confirmSignOut(context, ref));
          }
          return ContractorShowcase(
            listing: listing,
            mode: ShowcaseMode.owner,
            onEdit: () => context.push(Routes.contractorEditProfile),
            onSignOut: () => _confirmSignOut(context, ref),
          );
        },
      ),
    );
  }
}

class _ProfileFallback extends StatelessWidget {
  const _ProfileFallback({required this.profile, required this.onSignOut});
  final Profile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return BatshScaffold(
      title: S.profileTitle,
      body: ListView(
        children: [
          const SizedBox(height: BatshSpacing.md),
          _IdentityCard(name: profile.fullName, phone: profile.phone),
          const SizedBox(height: BatshSpacing.gutter),
          BatshButton(
            label: S.editProfileButton,
            style: BatshButtonStyle.secondary,
            onPressed: () => context.push(Routes.contractorEditProfile),
          ),
          const Divider(height: 24, thickness: 1, color: BatshColors.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
            child: Column(
              children: [
                const _DarkModeTile(),
                const SizedBox(height: BatshSpacing.sm),
                const _MotionModeTile(),
                const SizedBox(height: BatshSpacing.sm),
                const _LanguageTile(),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.xl),
          BatshButton(
            label: S.signOutButton,
            style: BatshButtonStyle.ghost,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _HomeownerProfile extends ConsumerWidget {
  const _HomeownerProfile({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedCount = ref.watch(savedContractorIdsProvider).value?.length ?? 0;
    final requestsCount = ref.watch(myBriefsProvider).value?.length ?? 0;

    final reduced = MediaQuery.of(context).disableAnimations;
    final items = <Widget>[
      const SizedBox(height: BatshSpacing.lg),
      _IdentityCard(
        name: profile.fullName,
        phone: profile.phone,
        avatarUrl: profile.avatarUrl,
      ),
      const SizedBox(height: BatshSpacing.gutter),
      BatshButton(
        label: S.editProfileButton,
        style: BatshButtonStyle.secondary,
        onPressed: () => context.push(Routes.homeownerEditProfile),
      ),
      const SizedBox(height: BatshSpacing.lg),
      _StatsRow(requestsCount: requestsCount, savedCount: savedCount),
      const SizedBox(height: BatshSpacing.lg),
      _ProfileTile(
        icon: Icons.assignment_outlined,
        label: S.myRequests,
        onTap: () => context.go(Routes.homeownerRequests),
      ),
      const SizedBox(height: BatshSpacing.sm),
      _ProfileTile(
        icon: Icons.bookmark_outline,
        label: S.mySaved,
        onTap: () => context.go(Routes.homeownerSaved),
      ),
      const SizedBox(height: BatshSpacing.sm),
      _ProfileTile(
        icon: Icons.explore_outlined,
        label: S.discoverContractors,
        onTap: () => context.go(Routes.homeownerDiscover),
      ),
      const Divider(height: 24, thickness: 1, color: BatshColors.outlineVariant),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        child: Column(
          children: [
            const _DarkModeTile(),
            const SizedBox(height: BatshSpacing.sm),
            const _MotionModeTile(),
            const SizedBox(height: BatshSpacing.sm),
            const _LanguageTile(),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.xxl),
      BatshButton(
        label: S.signOutButton,
        style: BatshButtonStyle.ghost,
        onPressed: () => _confirmSignOut(context, ref),
      ),
    ];
    return BatshScaffold(
      title: S.profileTitle,
      animateEntrance: false,
      body: ListView(
        children: reduced
            ? items
            : items.animate(interval: 60.ms).fadeIn(
                  duration: 300.ms,
                  curve: Curves.easeOut,
                ).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard(
      {required this.name, required this.phone, this.avatarUrl});
  final String name;
  final String phone;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return BatshCard(
      padding: const EdgeInsets.all(BatshSpacing.lg),
      elevated: true,
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 60,
              height: 60,
              child: avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        color: BatshColors.primaryContainer,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name.characters.first : '',
                        style: BatshTypography.headlineMd
                            .copyWith(color: BatshColors.onPrimaryContainer),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: BatshSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isNotEmpty ? name : '—',
                    style: BatshTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: BatshSpacing.xxs),
                Text(
                  phone,
                  style: BatshTypography.bodyMd
                      .copyWith(color: BatshColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: BatshColors.primaryFixed.withValues(alpha: 0.4),
              borderRadius: BatshRadius.brFull,
            ),
            child: const Icon(Icons.edit_outlined,
                size: 16, color: BatshColors.primary),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.requestsCount, required this.savedCount});
  final int requestsCount;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
      child: Row(
        children: [
          _StatItem(value: '$requestsCount', label: S.myRequests),
          const SizedBox(width: BatshSpacing.lg),
          _StatItem(value: '$savedCount', label: S.mySaved),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: BatshSpacing.md, horizontal: BatshSpacing.md),
        decoration: BoxDecoration(
          color: BatshColors.surfaceContainerLow,
          borderRadius: BatshRadius.brLg,
        ),
        child: Column(
          children: [
            Text(value,
                style: BatshTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: BatshColors.primary,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: BatshTypography.labelMd.copyWith(
                    color: BatshColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BatshColors.surfaceContainerLowest,
      borderRadius: BatshRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        highlightColor: BatshColors.primaryFixed.withValues(alpha: 0.2),
        splashColor: BatshColors.primaryFixed.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.lg, vertical: BatshSpacing.gutter),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BatshColors.primaryFixed.withValues(alpha: 0.2),
                  borderRadius: BatshRadius.brMd,
                ),
                child: Icon(icon, color: BatshColors.primary, size: 22),
              ),
              const SizedBox(width: BatshSpacing.gutter),
              Expanded(
                child: Text(label,
                    style: BatshTypography.bodyLg.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
              ),
              const Icon(Icons.chevron_left,
                  color: BatshColors.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BatshColors.surfaceContainerLowest,
      borderRadius: BatshRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.lg,
            vertical: BatshSpacing.gutter,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BatshColors.primaryFixed.withValues(alpha: 0.2),
                  borderRadius: BatshRadius.brMd,
                ),
                child: Icon(icon, color: BatshColors.primary, size: 22),
              ),
              const SizedBox(width: BatshSpacing.gutter),
              Expanded(
                child: Text(
                  label,
                  style: BatshTypography.bodyLg.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkModeTile extends ConsumerWidget {
  const _DarkModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return _SettingsTile(
      icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
      label: isDark ? S.darkModeTitle : S.lightModeTitle,
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
      ),
      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isEnglish = locale.languageCode == 'en';

    return _SettingsTile(
      icon: isEnglish ? Icons.language : Icons.translate,
      label: S.languageTitle,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: BatshColors.primaryContainer,
          borderRadius: BatshRadius.brSm,
        ),
        child: Text(
          isEnglish ? S.languageEnglish : S.languageArabic,
          style: BatshTypography.labelSm.copyWith(
            color: BatshColors.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () => ref.read(localeProvider.notifier).toggle(),
    );
  }
}

class _MotionModeTile extends ConsumerWidget {
  const _MotionModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motionMode = ref.watch(motionModeProvider);
    final icon = switch (motionMode) {
      MotionMode.full => Icons.animation,
      MotionMode.reduced => Icons.animation_outlined,
      MotionMode.off => Icons.block,
    };

    return _SettingsTile(
      icon: icon,
      label: S.motionLabel,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: BatshColors.primaryContainer,
          borderRadius: BatshRadius.brSm,
        ),
        child: Text(
          ref.read(motionModeProvider.notifier).label,
          style: BatshTypography.labelSm.copyWith(
            color: BatshColors.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () => ref.read(motionModeProvider.notifier).toggle(),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: BatshSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
          child: Row(
            children: [
              BatshShimmerBox(width: 60, height: 60, borderRadius: BatshRadius.brFull),
              const SizedBox(width: BatshSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BatshShimmerBox(width: 140, height: 18, borderRadius: BatshRadius.brSm),
                    const SizedBox(height: BatshSpacing.xxs),
                    BatshShimmerBox(width: 100, height: 14, borderRadius: BatshRadius.brSm),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
          child: BatshShimmerBox(width: double.infinity, height: 44, borderRadius: BatshRadius.brMd),
        ),
        const SizedBox(height: BatshSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
          child: Row(
            children: List.generate(3, (i) => Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: i > 0 ? BatshSpacing.md : 0),
                child: BatshShimmerBox(width: double.infinity, height: 60, borderRadius: BatshRadius.brLg),
              ),
            )),
          ),
        ),
        const SizedBox(height: BatshSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
          child: Column(
            children: List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
              child: Row(
                children: [
                  BatshShimmerBox(width: 40, height: 40, borderRadius: BatshRadius.brMd),
                  const SizedBox(width: BatshSpacing.gutter),
                  BatshShimmerBox(width: 180, height: 16, borderRadius: BatshRadius.brSm),
                ],
              ),
            )),
          ),
        ),
        const SizedBox(height: BatshSpacing.xxl),
        Center(
          child: BatshShimmerBox(width: 120, height: 20, borderRadius: BatshRadius.brSm),
        ),
      ],
    );
  }
}

void _confirmSignOut(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(S.signOutTitle),
      content: Text(S.signOutConfirmation),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(S.cancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            ref.read(authRepositoryProvider).signOut();
          },
          child: Text(S.signOutButton,
              style: const TextStyle(color: BatshColors.error)),
        ),
      ],
    ),
  );
}

