import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/router/routes.dart';
import '../../briefs/presentation/providers/briefs_providers.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/motion_mode_provider.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_switch.dart';
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
import '../../saved/presentation/providers/saved_providers.dart';
import '../../verification/presentation/verification_screen.dart';

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
          return _ContractorAccountView(
            listing: listing,
            onSignOut: () => _confirmSignOut(context, ref),
          );
        },
      ),
    );
  }
}

/// Premium contractor "حسابي" account screen: trust-forward hero (avatar,
/// verified badge, tier), real-signal stat chips, Pro upsell, then settings
/// incl. the verification entry. The full public profile stays reachable via
/// "معاينة الملف العام".
class _ContractorAccountView extends ConsumerWidget {
  const _ContractorAccountView({required this.listing, required this.onSignOut});
  final ContractorListing listing;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = MediaQuery.of(context).disableAnimations;

    final items = <Widget>[
      const SizedBox(height: BatshSpacing.md),
      _AccountHero(listing: listing),
      const SizedBox(height: BatshSpacing.md),
      _StatStrip(listing: listing),
      const SizedBox(height: BatshSpacing.lg),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: listing.isPro
            ? const _ProActivePill()
            : _AccountProBanner(onTap: () => context.push(Routes.pro)),
      ),
      const SizedBox(height: BatshSpacing.lg),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: BatshButton(
                label: S.editProfileButton,
                style: BatshButtonStyle.secondary,
                onPressed: () => context.push(Routes.contractorEditProfile),
              ),
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: BatshButton(
                label: S.previewPublicProfile,
                style: BatshButtonStyle.ghost,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: BatshColors.background,
                      body: ContractorShowcase(
                          listing: listing, mode: ShowcaseMode.public),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _SectionLabel(S.accountSettingsTitle),
      const SizedBox(height: BatshSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: _SettingsGroup(
          children: [
            const _DarkModeTile(),
            _VerificationTile(verified: listing.verified),
            const _LanguageTile(),
            const _HelpTile(),
            const _DeleteAccountTile(),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.xl),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: _LogoutRow(onTap: onSignOut),
      ),
      const SizedBox(height: BatshSpacing.xxl),
    ];

    return BatshScaffold(
      title: S.profileTitle,
      animateEntrance: false,
      body: ListView(
        children: reduced
            ? items
            : items
                .animate(interval: 55.ms)
                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({required this.listing});
  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.isNotEmpty
        ? listing.businessName
        : listing.fullName;
    // First name for the warm greeting ("أهلاً بك، علي").
    final first = listing.fullName.trim().isNotEmpty
        ? listing.fullName.trim().split(RegExp(r'\s+')).first
        : name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(BatshSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: BatshShadows.soft,
          // Very soft warm radial so the card feels alive, not flat white.
          gradient: RadialGradient(
            center: const Alignment(0.9, -0.9),
            radius: 1.5,
            colors: [
              BatshColors.primaryFixed.withValues(alpha: 0.5),
              BatshColors.surfaceContainerLowest,
            ],
            stops: const [0.0, 0.72],
          ),
        ),
        child: Row(
          children: [
            _AccountAvatar(logoUrl: listing.logoUrl, verified: listing.verified),
            const SizedBox(width: BatshSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('👋', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: BatshSpacing.xxs),
                      Flexible(
                        child: Text('${S.accountWelcome}، $first',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.labelMd
                                .copyWith(color: BatshColors.onSurfaceVariant)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.headlineSm
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                      if (listing.verified) ...[
                        const SizedBox(width: BatshSpacing.xs),
                        const Icon(Icons.verified_rounded,
                            size: 20, color: BatshColors.tertiary),
                      ],
                    ],
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                  // Stars only once a real review exists. This used to render
                  // `displayRating`, so a contractor with zero reviews opened
                  // their own profile to a 4.4 they never earned.
                  if (listing.rating case final avg?)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: BatshColors.tertiary),
                        const SizedBox(width: 3),
                        Text(avg.toStringAsFixed(1),
                            style: BatshTypography.labelMd.copyWith(
                                fontWeight: FontWeight.w700,
                                color: BatshColors.onSurface)),
                        const SizedBox(width: BatshSpacing.xs),
                        Text(S.ratingCaption,
                            style: BatshTypography.labelSm
                                .copyWith(color: BatshColors.onSurfaceVariant)),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 15, color: BatshColors.secondary),
                        const SizedBox(width: 4),
                        Text(S.newContractor,
                            style: BatshTypography.labelSm.copyWith(
                                color: BatshColors.onSurfaceVariant)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.logoUrl, required this.verified});
  final String? logoUrl;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: BatshColors.surfaceContainer,
              border: Border.all(
                  color: BatshColors.primary.withValues(alpha: 0.5), width: 2),
              boxShadow: BatshShadows.soft,
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl != null
                ? CachedNetworkImage(imageUrl: logoUrl!, fit: BoxFit.cover)
                : const Icon(Icons.engineering_outlined,
                    size: 36, color: BatshColors.primary),
          ),
          if (verified)
            Positioned(
              bottom: -6,
              right: -6,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BatshColors.tertiary,
                  border: Border.all(
                      color: BatshColors.surfaceContainerLowest, width: 2.5),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 14, color: BatshColors.onTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

/// One warm peach strip of real-signal stats, four cells split by hairlines —
/// matches the mockup's attached metric bar under the hero.
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.listing});
  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final since = listing.memberSince?.year;
    final tierLabel = switch (listing.tier) {
      ContractorTier.gold => S.tierGold,
      ContractorTier.silver => S.tierSilver,
      ContractorTier.bronze => S.tierBronze,
    };
    final cells = <Widget>[
      _StatCell(
          icon: Icons.event_outlined,
          value: since != null ? '$since' : '—',
          label: S.memberSinceLabel),
      _StatCell(
          icon: Icons.home_work_outlined,
          value: '${listing.projectsCompleted}',
          label: S.statJobs),
      // The "معدل الرد 100%" cell that sat here read `response_rate`, a column
      // whose default is 100 for every contractor — a constant presented as a
      // measurement. Reinstate it when brief-to-first-quote latency is tracked.
      _StatCell(
          icon: Icons.star_rounded,
          value: listing.hasReviews
              ? '${listing.reviewAvg.toStringAsFixed(1)} (${listing.reviewCount})'
              : '—',
          label: S.ratingCaption),
      _StatCell(
          icon: Icons.workspace_premium_rounded,
          value: tierLabel,
          label: S.statLevel,
          highlight: true),
    ];
    final row = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      row.add(Expanded(child: cells[i]));
      if (i != cells.length - 1) {
        row.add(Container(
            width: 1,
            height: 34,
            color: BatshColors.primary.withValues(alpha: 0.12)));
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
        decoration: BoxDecoration(
          color: BatshColors.primaryFixed.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, children: row),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final valueColor =
        highlight ? BatshColors.tertiary : BatshColors.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 15,
              color: highlight ? BatshColors.tertiary : BatshColors.primary),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                maxLines: 1,
                style: BatshTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w800, color: valueColor)),
          ),
          const SizedBox(height: 1),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm
                  .copyWith(color: BatshColors.onSurfaceVariant, fontSize: 10)),
        ],
      ),
    );
  }
}

class _AccountProBanner extends StatelessWidget {
  const _AccountProBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BatshRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [BatshColors.primary, BatshColors.onPrimaryFixedVariant],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(BatshSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      BatshColors.tertiaryContainer,
                      BatshColors.tertiary,
                    ]),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      size: 22, color: BatshColors.onTertiaryContainer),
                ),
                const SizedBox(width: BatshSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.upgradeToProShort,
                          style: BatshTypography.titleMd.copyWith(
                              color: BatshColors.onPrimary,
                              fontWeight: FontWeight.w700)),
                      Text(S.proBannerSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.bodySm.copyWith(
                              color: BatshColors.onPrimary
                                  .withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded,
                    color: BatshColors.onPrimary.withValues(alpha: 0.9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProActivePill extends StatelessWidget {
  const _ProActivePill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: BatshColors.secondaryContainer,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: BatshColors.secondary, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: BatshColors.secondary),
          const SizedBox(width: BatshSpacing.md),
          Expanded(
            child: Text(S.proActiveLine,
                style: BatshTypography.titleMd.copyWith(
                    color: BatshColors.onSecondaryContainer,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    if (verified) {
      return _SettingsTile(
        icon: Icons.verified_rounded,
        label: S.verifyTileLabel,
        subtitle: S.verifySubtitle,
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.sm, vertical: BatshSpacing.xxs),
          decoration: BoxDecoration(
            color: BatshColors.tertiaryFixed,
            borderRadius: BatshRadius.brSm,
          ),
          child: Text(S.verifyStateVerified,
              style: BatshTypography.labelSm.copyWith(
                  color: BatshColors.onTertiaryContainer,
                  fontWeight: FontWeight.w700)),
        ),
        onTap: () => _open(context),
      );
    }
    return _SettingsTile(
      icon: Icons.verified_outlined,
      label: S.verifyTileLabel,
      subtitle: S.verifySubtitle,
      trailing: const Icon(Icons.chevron_left,
          color: BatshColors.onSurfaceVariant, size: 20),
      onTap: () => _open(context),
    );
  }

  void _open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VerificationScreen()),
      );
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(BatshSpacing.lg),
              decoration: BoxDecoration(
                color: BatshColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: BatshShadows.soft,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: BatshColors.primaryContainer,
                    ),
                    child: Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName.characters.first
                          : '',
                      style: BatshTypography.headlineMd
                          .copyWith(color: BatshColors.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName.isNotEmpty ? profile.fullName : '—',
                          style: BatshTypography.titleLg
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: BatshSpacing.xxs),
                        Text(profile.phone,
                            style: BatshTypography.bodyMd.copyWith(
                                color: BatshColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.gutter),
          BatshButton(
            label: S.upgradeToProShort,
            icon: Icons.workspace_premium_outlined,
            onPressed: () => context.push(Routes.pro),
          ),
          const SizedBox(height: BatshSpacing.sm),
          BatshButton(
            label: S.verifyTileLabel,
            icon: Icons.verified_outlined,
            style: BatshButtonStyle.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VerificationScreen()),
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
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
      const SizedBox(height: BatshSpacing.md),
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
                label: S.myRequests,
                icon: Icons.assignment_outlined,
                reduced: reduced,
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: _StatBig(
                value: savedCount,
                label: S.mySaved,
                icon: Icons.bookmark_outline,
                reduced: reduced,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _SectionLabel(S.quickActionsTitle),
      const SizedBox(height: BatshSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.assignment_outlined,
                label: S.myRequests,
                onTap: () => context.go(Routes.homeownerRequests),
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: _QuickAction(
                icon: Icons.bookmark_outline,
                label: S.mySaved,
                onTap: () => context.go(Routes.homeownerSaved),
              ),
            ),
            const SizedBox(width: BatshSpacing.md),
            Expanded(
              child: _QuickAction(
                icon: Icons.explore_outlined,
                label: S.discoverContractors,
                onTap: () => context.go(Routes.homeownerDiscover),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _SectionLabel(S.accountSettingsTitle),
      const SizedBox(height: BatshSpacing.md),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
        child: _SettingsGroup(
          children: [
            _DarkModeTile(),
            _MotionModeTile(),
            _LanguageTile(),
            _DeleteAccountTile(),
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
      title: S.profileTitle,
      animateEntrance: false,
      body: ListView(
        children: reduced
            ? items
            : items
                .animate(interval: 55.ms)
                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

String _greeting() =>
    DateTime.now().hour < 17 ? S.greetingMorning : S.greetingEvening;

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
        padding: const EdgeInsets.all(BatshSpacing.lg),
        decoration: BoxDecoration(
          color: BatshColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: BatshShadows.soft,
        ),
        child: Row(
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
                  Text(_greeting(),
                      style: BatshTypography.labelMd
                          .copyWith(color: BatshColors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.headlineSm
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: BatshSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: BatshSpacing.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: BatshColors.primaryFixed.withValues(alpha: 0.4),
                      borderRadius: BatshRadius.brFull,
                    ),
                    child: Text(S.roleHomeowner,
                        style: BatshTypography.labelSm.copyWith(
                          color: BatshColors.primary,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar(
      {required this.name, required this.avatarUrl, required this.onEdit});
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
              color: BatshColors.primaryContainer,
              border: Border.all(
                  color: BatshColors.onSurface.withValues(alpha: 0.06),
                  width: 1),
              boxShadow: BatshShadows.soft,
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null
                ? CachedNetworkImage(imageUrl: avatarUrl!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      name.isNotEmpty && name != '—' ? name.characters.first : '',
                      style: BatshTypography.headlineMd
                          .copyWith(color: BatshColors.onPrimaryContainer),
                    ),
                  ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Material(
              color: BatshColors.primary,
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
                        color: BatshColors.surfaceContainerLowest, width: 2.5),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 14, color: BatshColors.onPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
      child: Text(text,
          style: BatshTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

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
        ? Text('$value',
            style: BatshTypography.displayMd
                .copyWith(fontWeight: FontWeight.w700, color: BatshColors.onSurface))
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text('${v.round()}',
                style: BatshTypography.displayMd.copyWith(
                    fontWeight: FontWeight.w700, color: BatshColors.onSurface)),
          );
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.lg),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: BatshColors.primary),
          const SizedBox(height: BatshSpacing.md),
          number,
          const SizedBox(height: BatshSpacing.xxs),
          Text(label,
              style: BatshTypography.labelMd
                  .copyWith(color: BatshColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: BatshShadows.soft,
      ),
      child: Material(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: BatshSpacing.lg, horizontal: BatshSpacing.sm),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BatshColors.primaryFixed.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: BatshColors.primary, size: 22),
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelMd
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS-style grouped settings: one soft card, hairline dividers between rows.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(const Divider(
            height: 1, thickness: 1, indent: 64, color: BatshColors.outlineVariant));
      }
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: BatshShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: BatshColors.surfaceContainerLowest,
          child: Column(children: rows),
        ),
      ),
    );
  }
}

class _LogoutRow extends StatelessWidget {
  const _LogoutRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: BatshShadows.soft,
      ),
      child: Material(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: BatshColors.error.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.lg, vertical: BatshSpacing.gutter),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BatshColors.error.withValues(alpha: 0.1),
                    borderRadius: BatshRadius.brMd,
                  ),
                  child: const Icon(Icons.logout,
                      color: BatshColors.error, size: 20),
                ),
                const SizedBox(width: BatshSpacing.gutter),
                Expanded(
                  child: Text(S.signOutButton,
                      style: BatshTypography.bodyLg.copyWith(
                          color: BatshColors.error,
                          fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_left,
                    color: BatshColors.error, size: 20),
              ],
            ),
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
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback onTap;
  final String? subtitle;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: BatshTypography.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelSm.copyWith(
                          color: BatshColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
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
      subtitle: S.darkModeSubtitle,
      trailing: BatshSwitch(
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
      subtitle: S.languageSubtitle,
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

/// Support number for the "المساعدة والدعم" tile. ponytail: single knob —
/// set this to the real Shattab support WhatsApp before launch.
const String _supportPhone = '201000000000';

class _HelpTile extends StatelessWidget {
  const _HelpTile();

  Future<void> _open(BuildContext context) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse('https://wa.me/$_supportPhone');
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(S.couldNotOpenApp)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.support_agent_outlined,
      label: S.helpSupport,
      subtitle: S.helpSubtitle,
      trailing: const Icon(Icons.chevron_left,
          color: BatshColors.onSurfaceVariant, size: 20),
      onTap: () => _open(context),
    );
  }
}

/// Permanent account deletion — required in-app by Google Play for any app
/// that creates accounts in-app.
///
/// Guarded by typed confirmation rather than a plain "are you sure": this
/// erases briefs, quotes, posts, photos and reviews with no recovery path, and
/// a misplaced tap in a settings list should not be able to trigger it. The
/// work happens server-side in `delete_my_account()` (0023) so the account
/// cannot end up half-deleted.
class _DeleteAccountTile extends ConsumerStatefulWidget {
  const _DeleteAccountTile();

  @override
  ConsumerState<_DeleteAccountTile> createState() => _DeleteAccountTileState();
}

class _DeleteAccountTileState extends ConsumerState<_DeleteAccountTile> {
  Future<void> _confirm() async {
    final controller = TextEditingController();
    final word = S.deleteAccountConfirmWord;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(S.deleteAccountTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.deleteAccountBody),
              const SizedBox(height: BatshSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                decoration:
                    InputDecoration(hintText: S.deleteAccountConfirmHint),
                onChanged: (_) => setLocal(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(S.cancel),
            ),
            TextButton(
              // Disabled until the word matches exactly.
              onPressed: controller.text.trim() == word
                  ? () => Navigator.of(ctx).pop(true)
                  : null,
              child: Text(S.deleteAccount,
                  style: const TextStyle(color: BatshColors.error)),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(S.accountDeleted)));
      // The router's auth listener returns the user to the landing screen once
      // the session is gone, so there is no manual navigation here.
    } catch (e) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ErrorMapper.map(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.delete_forever_outlined,
      label: S.deleteAccount,
      trailing: const Icon(Icons.chevron_left,
          color: BatshColors.onSurfaceVariant, size: 20),
      onTap: _confirm,
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

