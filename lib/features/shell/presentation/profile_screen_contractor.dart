part of 'profile_screen.dart';

/// Premium contractor "حسابي" account screen: trust-forward hero (avatar,
/// verified badge, tier), real-signal stat chips, Pro upsell, then settings
/// incl. the verification entry. The full public profile stays reachable via
/// "معاينة الملف العام".
class _ContractorAccountView extends ConsumerWidget {
  const _ContractorAccountView({
    required this.listing,
    required this.onSignOut,
  });
  final ContractorListing listing;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = MediaQuery.disableAnimationsOf(context);

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
                label: context.l10n.editProfileButton,
                style: BatshButtonStyle.secondary,
                onPressed: () => context.push(Routes.contractorEditProfile),
              ),
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: BatshButton(
                label: context.l10n.previewPublicProfile,
                style: BatshButtonStyle.ghost,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: context.colorScheme.background,
                      body: ContractorShowcase(
                        listing: listing,
                        mode: ShowcaseMode.public,
                      ),
                    ),
                  ),
                ),
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
            _VerificationTile(verified: listing.verified),
            const _LanguageTile(),
            const _HelpTile(),
            _LegalTile(
              icon: Icons.privacy_tip_outlined,
              label: context.l10n.privacyPolicy,
              url: _privacyPolicyUrl,
            ),
            _LegalTile(
              icon: Icons.description_outlined,
              label: context.l10n.termsOfService,
              url: _termsUrl,
            ),
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
      title: context.l10n.profileTitle,
      animateEntrance: false,
      body: ListView(
        children: reduced
            ? items
            : items
                  .animate(interval: 55.ms)
                  .fadeIn(duration: 300.ms, curve: BatshMotion.easeOut)
                  .slideY(begin: 0.06, end: 0, curve: BatshMotion.easeOut),
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
          borderRadius: BatshRadius.brXxl,
          boxShadow: BatshShadows.soft,
          // Very soft warm radial so the card feels alive, not flat white.
          gradient: RadialGradient(
            center: const Alignment(0.9, -0.9),
            radius: 1.5,
            colors: [
              context.colorScheme.primaryFixed.withValues(alpha: 0.5),
              context.colorScheme.surfaceContainerLowest,
            ],
            stops: const [0.0, 0.72],
          ),
        ),
        child: Row(
          children: [
            _AccountAvatar(
              logoUrl: listing.logoUrl,
              verified: listing.verified,
            ),
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
                        child: Text(
                          '${context.l10n.accountWelcome}، $first',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.labelMd.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.headlineSm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (listing.verified) ...[
                        const SizedBox(width: BatshSpacing.xs),
                        Icon(
                          Icons.verified_rounded,
                          size: BatshIconSize.md,
                          color: context.colorScheme.tertiary,
                        ),
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
                        Icon(
                          Icons.star_rounded,
                          size: BatshIconSize.sm,
                          color: context.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          avg.toStringAsFixed(1),
                          style: BatshTypography.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: BatshSpacing.xs),
                        Text(
                          context.l10n.ratingCaption,
                          style: BatshTypography.labelSm.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: BatshIconSize.sm,
                          color: context.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.noRatingsYet,
                          style: BatshTypography.labelSm.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
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
    final radius = BatshRadius.brXl;
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
              color: context.colorScheme.surfaceContainer,
              border: Border.all(
                color: context.colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: BatshShadows.soft,
            ),
            clipBehavior: Clip.antiAlias,
            child: logoUrl != null
                ? CachedNetworkImage(imageUrl: logoUrl!, fit: BoxFit.cover)
                : Icon(
                    Icons.engineering_outlined,
                    size: BatshIconSize.xl,
                    color: context.colorScheme.primary,
                  ),
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
                  color: context.colorScheme.tertiary,
                  border: Border.all(
                    color: context.colorScheme.surfaceContainerLowest,
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: BatshIconSize.sm,
                  color: context.colorScheme.onTertiary,
                ),
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
    // Same getter the public badge reads, so the owner never sees a different
    // word for their level than a homeowner does.
    final tierLabel = listing.tier.label(context);
    final cells = <Widget>[
      _StatCell(
        icon: Icons.event_outlined,
        value: since != null ? '$since' : '—',
        label: context.l10n.memberSinceLabel,
      ),
      _StatCell(
        icon: Icons.home_work_outlined,
        value: '${listing.projectsCompleted}',
        label: context.l10n.statJobs,
      ),
      // The "معدل الرد 100%" cell that sat here read `response_rate`, a column
      // whose default is 100 for every contractor — a constant presented as a
      // measurement. Reinstate it when brief-to-first-quote latency is tracked.
      _StatCell(
        icon: Icons.star_rounded,
        value: listing.hasReviews
            ? '${listing.reviewAvg.toStringAsFixed(1)} (${listing.reviewCount})'
            : '—',
        label: context.l10n.ratingCaption,
      ),
      _StatCell(
        icon: Icons.workspace_premium_rounded,
        value: tierLabel,
        label: context.l10n.statLevel,
        highlight: true,
      ),
    ];
    final row = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      row.add(Expanded(child: cells[i]));
      if (i != cells.length - 1) {
        row.add(
          Container(
            width: 1,
            height: 34,
            color: context.colorScheme.primary.withValues(alpha: 0.12),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.primaryFixed.withValues(alpha: 0.5),
          borderRadius: BatshRadius.brXl,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: row,
        ),
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
    final valueColor = highlight
        ? context.colorScheme.tertiary
        : context.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: BatshIconSize.sm,
            color: highlight
                ? context.colorScheme.tertiary
                : context.colorScheme.primary,
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: BatshTypography.titleMd.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              context.colorScheme.primary,
              context.colorScheme.onPrimaryFixedVariant,
            ],
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        context.colorScheme.tertiaryContainer,
                        context.colorScheme.tertiary,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: BatshIconSize.md,
                    color: context.colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: BatshSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.upgradeToProShort,
                        style: BatshTypography.titleMd.copyWith(
                          color: context.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        context.l10n.proBannerSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.bodySm.copyWith(
                          color: context.colorScheme.onPrimary.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: context.colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
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
        color: context.colorScheme.secondaryContainer,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: context.colorScheme.secondary, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: context.colorScheme.secondary,
          ),
          const SizedBox(width: BatshSpacing.md),
          Expanded(
            child: Text(
              context.l10n.proActiveLine,
              style: BatshTypography.titleMd.copyWith(
                color: context.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
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
        label: context.l10n.verifyTileLabel,
        subtitle: context.l10n.verifySubtitle,
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.sm,
            vertical: BatshSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: context.colorScheme.tertiaryFixed,
            borderRadius: BatshRadius.brSm,
          ),
          child: Text(
            context.l10n.verifyStateVerified,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        onTap: () => _open(context),
      );
    }
    return _SettingsTile(
      icon: Icons.verified_outlined,
      label: context.l10n.verifyTileLabel,
      subtitle: context.l10n.verifySubtitle,
      trailing: Icon(
        Icons.chevron_left,
        color: context.colorScheme.onSurfaceVariant,
        size: BatshIconSize.md,
      ),
      onTap: () => _open(context),
    );
  }

  void _open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const VerificationScreen()));
}

class _ProfileFallback extends StatelessWidget {
  const _ProfileFallback({required this.profile, required this.onSignOut});
  final Profile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return BatshScaffold(
      title: context.l10n.profileTitle,
      body: ListView(
        children: [
          const SizedBox(height: BatshSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(BatshSpacing.lg),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerLowest,
                borderRadius: BatshRadius.brXxl,
                boxShadow: BatshShadows.soft,
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colorScheme.primaryContainer,
                    ),
                    child: Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName.characters.first
                          : '',
                      style: BatshTypography.headlineMd.copyWith(
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName.isNotEmpty ? profile.fullName : '—',
                          style: BatshTypography.titleLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.xxs),
                        Text(
                          profile.phone,
                          style: BatshTypography.bodyMd.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.gutter),
          BatshButton(
            label: context.l10n.upgradeToProShort,
            icon: Icons.workspace_premium_outlined,
            onPressed: () => context.push(Routes.pro),
          ),
          const SizedBox(height: BatshSpacing.sm),
          BatshButton(
            label: context.l10n.verifyTileLabel,
            icon: Icons.verified_outlined,
            style: BatshButtonStyle.secondary,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VerificationScreen()),
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          BatshButton(
            label: context.l10n.editProfileButton,
            style: BatshButtonStyle.secondary,
            onPressed: () => context.push(Routes.contractorEditProfile),
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: context.colorScheme.outlineVariant,
          ),
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
            label: context.l10n.signOutButton,
            style: BatshButtonStyle.ghost,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}
