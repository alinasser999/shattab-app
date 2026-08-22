import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/debug/debug_config.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/supabase/supabase_provider.dart';
import '../../briefs/presentation/providers/briefs_providers.dart';
import '../../billing/presentation/providers/billing_providers.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/motion_mode_provider.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_empty_state.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/profile.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../discovery/domain/contractor_listing.dart';
import '../../discovery/presentation/providers/discovery_providers.dart';
import '../../discovery/presentation/widgets/contractor_showcase.dart';
import '../../discovery/presentation/widgets/mockup_assets.dart';
import '../../explore/presentation/widgets/contractor_community_posts.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../../verification/data/verification_repository.dart';
import '../../verification/presentation/verification_screen.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/notification_preferences_sheet.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/utils/support_contact.dart';

import 'package:batsh/core/theme/theme_extension.dart';
part 'profile_screen_contractor.dart';
part 'profile_screen_settings.dart';
part 'profile_screen_homeowner.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return profileAsync.when(
      loading: () => BatshScaffold(
        title: context.l10n.profileTitle,
        body: const _ProfileSkeleton(),
      ),
      error: (e, _) => BatshScaffold(
        title: context.l10n.profileTitle,
        body: BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return BatshScaffold(
            title: context.l10n.profileTitle,
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
              title: context.l10n.signInOrCreateAccount,
              message: context.l10n.signInEmptyMessage,
              icon: Icons.person_outline,
              action: BatshButton(
                label: context.l10n.signInSheetTitle,
                onPressed: () => showSignInSheet(
                  context,
                  reason: context.l10n.signInOrCreateAccount,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push(Routes.login),
              child: Text(
                context.l10n.contractorSignInLink,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: context.colorScheme.primary,
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
      backgroundColor: context.colorScheme.surface,
      body: listingAsync.when(
        loading: () => const BatshProfileSkeleton(),
        error: (_, _) => _ProfileFallback(
          profile: profile,
          onSignOut: () => _confirmSignOut(context, ref),
        ),
        data: (listing) {
          if (listing == null) {
            return _ProfileFallback(
              profile: profile,
              onSignOut: () => _confirmSignOut(context, ref),
            );
          }
          return _ContractorAccountView(
            listing: listing,
            onSignOut: () => _confirmSignOut(context, ref),
          );
        },
      ),
    );
  }
}

class _HomeownerProfile extends ConsumerWidget {
  const _HomeownerProfile({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HomeownerAccountScreen(profile: profile);
    /*
    final savedCount = ref.watch(savedContractorIdsProvider).value?.length ?? 0;
    final requestsCount = ref.watch(myBriefsProvider).value?.length ?? 0;
    final reduced = MediaQuery.disableAnimationsOf(context);

    final items = <Widget>[
      const SizedBox(height: BatshSpacing.lg),
      _ProfileHero(
        profile: profile,
        onEdit: () => context.push(Routes.homeownerEditProfile),
      ),
      const SizedBox(height: BatshSpacing.lg),
      // Stats — real counts only, count up on load.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: _StatBig(
                value: requestsCount,
                label: context.l10n.myRequests,
                icon: Icons.assignment_outlined,
                reduced: reduced,
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: _StatBig(
                value: savedCount,
                label: context.l10n.mySaved,
                icon: Icons.bookmark_outline,
                reduced: reduced,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _SectionLabel(context.l10n.quickActionsTitle),
      const SizedBox(height: BatshSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.assignment_outlined,
                label: context.l10n.myRequests,
                onTap: () => context.go(Routes.homeownerRequests),
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: _QuickAction(
                icon: Icons.bookmark_outline,
                label: context.l10n.mySaved,
                onTap: () => context.go(Routes.homeownerSaved),
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: _QuickAction(
                icon: Icons.explore_outlined,
                label: context.l10n.discoverContractors,
                onTap: () => context.go(Routes.homeownerDiscover),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _SectionLabel(context.l10n.accountSettingsTitle),
      const SizedBox(height: BatshSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: _SettingsGroup(
          children: [
            const _DarkModeTile(),
            const _MotionModeTile(),
            const _LanguageTile(),
            _SettingsTile(
              icon: Icons.privacy_tip_outlined,
              label: context.l10n.privacyPolicy,
              trailing: Icon(
                Icons.chevron_left,
                color: context.colorScheme.onSurfaceVariant,
                size: BatshIconSize.md,
              ),
              onTap: () => context.push(Routes.homeownerPrivacy),
            ),
            _SettingsTile(
              icon: Icons.description_outlined,
              label: context.l10n.termsOfService,
              trailing: Icon(
                Icons.chevron_left,
                color: context.colorScheme.onSurfaceVariant,
                size: BatshIconSize.md,
              ),
              onTap: () => context.push(Routes.homeownerTerms),
            ),
            const _DeleteAccountTile(),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.xl),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: _LogoutRow(onTap: () => _confirmSignOut(context, ref)),
      ),
      const SizedBox(height: BatshSpacing.xxl),
    ];

    return BatshScaffold(
      title: context.l10n.profileTitle,
      actions: [
        _AccountRoleSwitcher(role: UserRole.homeowner),
        const SizedBox(width: BatshSpacing.sm),
      ],
      animateEntrance: false,
      padding: EdgeInsets.zero,
      backgroundColor: context.colorScheme.surface,
      body: _ProfilePageFrame(
        child: ListView(
          children: reduced
              ? items
              : items
                    .animate(interval: 55.ms)
                    .fadeIn(duration: 300.ms, curve: BatshMotion.easeOut)
                    .slideY(begin: 0.06, end: 0, curve: BatshMotion.easeOut),
        ),
      ),
    );
    */
  }
}

// ignore: unused_element
class _ProfilePageFrame extends StatelessWidget {
  const _ProfilePageFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.surface,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: child,
        ),
      ),
    );
  }
}

String _greeting(BuildContext context) => DateTime.now().hour < 17
    ? context.l10n.greetingMorning
    : context.l10n.greetingEvening;

// ignore: unused_element
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.onEdit});
  final Profile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName.isNotEmpty ? profile.fullName : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(BatshSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              context.colorScheme.primaryContainer,
              context.colorScheme.primaryFixed.withValues(alpha: 0.72),
              context.colorScheme.surfaceContainerLowest,
            ],
            stops: const [0, 0.48, 1],
          ),
          borderRadius: BatshRadius.brXxl,
          border: Border.all(
            color: context.colorScheme.primary.withValues(alpha: 0.16),
          ),
          boxShadow: BatshShadows.raised,
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -42,
              end: -32,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorScheme.primary.withValues(alpha: 0.10),
                ),
              ),
            ),
            PositionedDirectional(
              bottom: -54,
              start: 26,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorScheme.tertiaryFixed.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HeroAvatar(
                  name: name,
                  avatarUrl: profile.avatarUrl,
                  onEdit: onEdit,
                ),
                const SizedBox(width: BatshSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(context),
                        style: BatshTypography.labelLg.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.xxs),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.headlineLg.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.md),
                      Wrap(
                        spacing: BatshSpacing.xs,
                        runSpacing: BatshSpacing.xs,
                        children: [
                          _ProfilePill(
                            icon: Icons.home_work_outlined,
                            label: context.l10n.roleHomeowner,
                          ),
                          _ProfilePill(
                            icon: Icons.edit_outlined,
                            label: context.l10n.editProfile,
                            onTap: onEdit,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsetsDirectional.only(
        start: BatshSpacing.sm,
        end: BatshSpacing.md,
        top: BatshSpacing.xs,
        bottom: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest.withValues(
          alpha: 0.82,
        ),
        borderRadius: BatshRadius.brFull,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: BatshIconSize.sm,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: BatshSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BatshRadius.brFull,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({
    required this.name,
    required this.avatarUrl,
    required this.onEdit,
  });
  final String name;
  final String? avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colorScheme.primaryContainer,
              border: Border.all(
                color: context.colorScheme.onSurface.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: BatshShadows.soft,
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null
                ? CachedNetworkImage(imageUrl: avatarUrl!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      name.isNotEmpty && name != '—'
                          ? name.characters.first
                          : '',
                      style: BatshTypography.headlineMd.copyWith(
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Material(
              color: context.colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colorScheme.surfaceContainerLowest,
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: BatshIconSize.sm,
                    color: context.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              borderRadius: BatshRadius.brFull,
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Text(
            text,
            style: BatshTypography.titleLg.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _StatBig extends StatelessWidget {
  const _StatBig({
    required this.value,
    required this.label,
    required this.icon,
    required this.reduced,
  });
  final int value;
  final String label;
  final IconData icon;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final number = reduced
        ? Text(
            '$value',
            style: BatshTypography.displayMd.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurface,
            ),
          )
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: BatshMotion.easeOut,
            builder: (_, v, _) => Text(
              '${v.round()}',
              style: BatshTypography.displayMd.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colorScheme.onSurface,
              ),
            ),
          );
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            context.colorScheme.surfaceContainerLowest,
            context.colorScheme.primaryFixed.withValues(alpha: 0.24),
          ],
        ),
        borderRadius: BatshRadius.brXl,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.10),
        ),
        boxShadow: BatshShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BatshRadius.brMd,
            ),
            child: Icon(
              icon,
              size: BatshIconSize.md,
              color: context.colorScheme.primary,
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          number,
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            label,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BatshRadius.brXl,
        boxShadow: BatshShadows.elevated,
      ),
      child: Material(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: BatshSpacing.md,
              horizontal: BatshSpacing.sm,
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colorScheme.primaryFixed.withValues(
                      alpha: 0.48,
                    ),
                    borderRadius: BatshRadius.brLg,
                  ),
                  child: Icon(
                    icon,
                    color: context.colorScheme.primary,
                    size: BatshIconSize.md,
                  ),
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxs),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: BatshIconSize.xs,
                  color: context.colorScheme.primary.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ),
      ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: Row(
            children: [
              BatshShimmerBox(
                width: 60,
                height: 60,
                borderRadius: BatshRadius.brFull,
              ),
              const SizedBox(width: BatshSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BatshShimmerBox(
                      width: 140,
                      height: 18,
                      borderRadius: BatshRadius.brSm,
                    ),
                    const SizedBox(height: BatshSpacing.xxs),
                    BatshShimmerBox(
                      width: 100,
                      height: 14,
                      borderRadius: BatshRadius.brSm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: BatshShimmerBox(
            width: double.infinity,
            height: 44,
            borderRadius: BatshRadius.brMd,
          ),
        ),
        const SizedBox(height: BatshSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: i > 0 ? BatshSpacing.md : 0,
                  ),
                  child: BatshShimmerBox(
                    width: double.infinity,
                    height: 60,
                    borderRadius: BatshRadius.brLg,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: BatshSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: Column(
            children: List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
                child: Row(
                  children: [
                    BatshShimmerBox(
                      width: 40,
                      height: 40,
                      borderRadius: BatshRadius.brMd,
                    ),
                    const SizedBox(width: BatshSpacing.gutter),
                    BatshShimmerBox(
                      width: 180,
                      height: 16,
                      borderRadius: BatshRadius.brSm,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: BatshSpacing.xxl),
        Center(
          child: BatshShimmerBox(
            width: 120,
            height: 20,
            borderRadius: BatshRadius.brSm,
          ),
        ),
      ],
    );
  }
}

void _confirmSignOut(BuildContext context, WidgetRef ref) {
  _showHomeownerLogoutSheet(context, ref);
}
