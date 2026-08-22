part of 'profile_screen.dart';

class _ContractorAccountView extends ConsumerWidget {
  const _ContractorAccountView({
    required this.listing,
    required this.onSignOut,
  });

  final ContractorListing listing;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(
      portfolioForContractorProvider(listing.id),
    );
    final portfolioCount = portfolioAsync.maybeWhen(
      data: (projects) => projects.length,
      orElse: () => 0,
    );
    final completion = _ProfileCompletion.calculate(
      listing,
      portfolioCount: portfolioCount,
    );
    final verificationStatus = ref.watch(verificationStatusProvider).value;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final sections = <Widget>[
      _ContractorProfileCard(
        listing: listing,
        completion: completion,
        portfolioCount: portfolioCount,
        reducedMotion: reducedMotion,
      ),
      const SizedBox(height: BatshSpacing.xl),
      _ContractorSectionLabel(context.l10n.nextStepsTitle),
      const SizedBox(height: BatshSpacing.sm),
      _ContractorChecklist(
        listing: listing,
        portfolioCount: portfolioCount,
        verificationStatus: verificationStatus,
      ),
      const SizedBox(height: BatshSpacing.xl),
      _ContractorSectionLabel(context.l10n.communityPostsTitle),
      const SizedBox(height: BatshSpacing.sm),
      ContractorCommunityPosts(contractorId: listing.id),
      const SizedBox(height: BatshSpacing.xl),
      _ContractorSectionLabel(context.l10n.performanceTitle),
      const SizedBox(height: BatshSpacing.sm),
      _ContractorPerformanceCard(
        onAddProject: () => context.push(Routes.contractorPortfolioNew),
        onCompleteProfile: () => context.push(Routes.contractorEditProfile),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _ContractorProCard(listing: listing),
      const SizedBox(height: BatshSpacing.xl),
      _ContractorSectionLabel(context.l10n.homeownerSettingsPreview),
      const SizedBox(height: BatshSpacing.sm),
      _AccountSettingsPreview(
        onAppearance: () => context.push(Routes.contractorAppearance),
        onMotion: () => context.push(Routes.contractorAppearance),
        onLanguage: () => context.push(Routes.contractorLanguage),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _ContractorSectionLabel(context.l10n.homeownerAccountExperienceSection),
      const SizedBox(height: BatshSpacing.sm),
      _ContractorAccountPreferences(
        onSettings: () => context.push(Routes.contractorSettings),
        onNotifications: () => _showNotificationPreferences(context),
      ),
      const SizedBox(height: BatshSpacing.md),
      _LogoutRow(onTap: onSignOut),
      const SizedBox(height: BatshSpacing.sm),
      const _DeleteAccountTile(),
    ];

    return BatshScaffold(
      title: context.l10n.profileTitle,
      actions: [
        _AccountRoleSwitcher(role: UserRole.contractor),
        const SizedBox(width: BatshSpacing.sm),
      ],
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.sm,
          BatshSpacing.md,
          BatshSpacing.xxxxl,
        ),
        children: reducedMotion
            ? sections
            : sections
                  .animate(interval: 45.ms)
                  .fadeIn(duration: 280.ms, curve: BatshMotion.easeOut)
                  .slideY(
                    begin: 0.025,
                    end: 0,
                    duration: 280.ms,
                    curve: BatshMotion.easeOut,
                  ),
      ),
    );
  }

  Future<void> _showNotificationPreferences(BuildContext context) async {
    await showNotificationPreferencesSheet(context);
  }
}

class _AccountRoleSwitcher extends ConsumerWidget {
  const _AccountRoleSwitcher({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: BatshSpacing.xs),
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: BatshRadius.brFull,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoleChoice(
            label: context.l10n.roleSwitcherOwner,
            active: role == UserRole.homeowner,
            onTap: kDebugAuth
                ? () => _switchRole(context, ref, UserRole.homeowner)
                : null,
          ),
          _RoleChoice(
            label: context.l10n.roleSwitcherContractor,
            active: role == UserRole.contractor,
            onTap: kDebugAuth
                ? () => _switchRole(context, ref, UserRole.contractor)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _switchRole(
    BuildContext context,
    WidgetRef ref,
    UserRole nextRole,
  ) async {
    if (nextRole == role) return;
    await debugSwitchRole(ref.read(supabaseClientProvider), nextRole);
    await ref.read(currentProfileProvider.notifier).refresh();
  }
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({required this.label, required this.active, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      enabled: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brFull,
        child: AnimatedContainer(
          duration: BatshMotion.fast,
          constraints: const BoxConstraints(minHeight: 34),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? context.colorScheme.primary : Colors.transparent,
            borderRadius: BatshRadius.brFull,
          ),
          child: Text(
            label,
            style: BatshTypography.labelSm.copyWith(
              color: active
                  ? context.colorScheme.onPrimary
                  : context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCompletion {
  const _ProfileCompletion(this.value, this.completed, this.total);

  final int value;
  final int completed;
  final int total;

  static _ProfileCompletion calculate(
    ContractorListing listing, {
    required int portfolioCount,
  }) {
    final checks = <bool>[
      listing.logoUrl?.trim().isNotEmpty ?? false,
      listing.businessName.trim().isNotEmpty ||
          listing.fullName.trim().isNotEmpty,
      listing.phone.trim().isNotEmpty,
      listing.specialties.isNotEmpty,
      listing.serviceAreas.isNotEmpty,
      listing.bio?.trim().isNotEmpty ?? false,
      listing.yearsExperience != null && listing.yearsExperience! > 0,
      portfolioCount > 0,
      listing.verified,
    ];
    final completed = checks.where((done) => done).length;
    return _ProfileCompletion(
      (completed / checks.length * 100).round(),
      completed,
      checks.length,
    );
  }
}

class _ContractorProfileCard extends StatelessWidget {
  const _ContractorProfileCard({
    required this.listing,
    required this.completion,
    required this.portfolioCount,
    required this.reducedMotion,
  });

  final ContractorListing listing;
  final _ProfileCompletion completion;
  final int portfolioCount;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final card = Semantics(
      container: true,
      label: context.l10n.profileCompletionPercent(completion.value),
      child: _ContractorPanel(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BatshRadius.brXxl,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: _ArchitecturalPattern(
                    color: context.colorScheme.primary.withValues(alpha: 0.045),
                  ),
                ),
              ),
              Column(
                children: [
                  _ContractorHeroTop(listing: listing),
                  _ContractorStatsRow(listing: listing),
                  _ContractorCompletionBlock(completion: completion),
                  _ContractorProfileActions(listing: listing),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (reducedMotion) return card;
    return card
        .animate()
        .fadeIn(duration: 360.ms, curve: BatshMotion.easeOut)
        .slideY(
          begin: 0.035,
          end: 0,
          duration: 360.ms,
          curve: BatshMotion.easeOut,
        );
  }
}

class _ContractorHeroTop extends StatelessWidget {
  const _ContractorHeroTop({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 330;
        final media = _ContractorHeroMedia(listing: listing);
        final info = Directionality(
          textDirection: TextDirection.rtl,
          child: _ContractorHeroInfo(listing: listing),
        );

        if (stacked) {
          return Column(
            children: [
              SizedBox(height: 168, width: double.infinity, child: media),
              info,
            ],
          );
        }

        return SizedBox(
          height: 188,
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              Expanded(flex: 44, child: media),
              Expanded(flex: 56, child: info),
            ],
          ),
        );
      },
    );
  }
}

class _ContractorHeroMedia extends StatelessWidget {
  const _ContractorHeroMedia({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.coverPhotoUrl?.trim().isNotEmpty == true
        ? listing.coverPhotoUrl!
        : mockupHeroImage;

    return Semantics(
      image: true,
      label: context.l10n.coverPhoto,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            memCacheWidth: 720,
            placeholder: (_, _) => const _ContractorHeroFallback(),
            errorWidget: (_, _, _) => const _ContractorHeroFallback(),
            fadeInDuration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : BatshMotion.normal,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x52000000)],
              ),
            ),
          ),
          if (listing.logoUrl?.trim().isNotEmpty == true)
            PositionedDirectional(
              bottom: BatshSpacing.sm,
              start: BatshSpacing.sm,
              child: Container(
                width: 42,
                height: 42,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colorScheme.surfaceContainerLowest,
                    width: 2,
                  ),
                ),
                child: CachedNetworkImage(
                  imageUrl: listing.logoUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Icon(
                    listing.providerKind.icon,
                    color: context.colorScheme.primary,
                    size: BatshIconSize.md,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContractorHeroFallback extends StatelessWidget {
  const _ContractorHeroFallback();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/opportunities_hero_motif.jpg',
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
        ColoredBox(
          color: context.colorScheme.primary.withValues(alpha: 0.18),
          child: Icon(
            Icons.home_work_outlined,
            color: context.colorScheme.primary.withValues(alpha: 0.66),
            size: BatshIconSize.xl,
          ),
        ),
      ],
    );
  }
}

class _ContractorHeroInfo extends StatelessWidget {
  const _ContractorHeroInfo({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final displayName = listing.businessName.trim().isNotEmpty
        ? listing.businessName
        : listing.fullName;
    final personName = listing.fullName.trim().isNotEmpty
        ? listing.fullName
        : displayName;
    final areas = listing.serviceAreas.isEmpty
        ? context.l10n.areasNotAdded
        : listing.serviceAreas.take(2).join(' / ');

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        BatshSpacing.md,
        BatshSpacing.sm,
        BatshSpacing.md,
        BatshSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.topStart,
            child: Semantics(
              button: true,
              label: context.l10n.editProfile,
              child: IconButton(
                tooltip: context.l10n.editProfile,
                visualDensity: VisualDensity.compact,
                onPressed: () => context.push(Routes.contractorEditProfile),
                icon: Icon(
                  Icons.edit_outlined,
                  size: BatshIconSize.sm,
                  color: context.colorScheme.primary,
                ),
              ),
            ),
          ),
          Text(
            '${context.l10n.accountWelcome} $personName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.headlineSm.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.16,
            ),
          ),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            listing.providerKind.label(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            areas,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.xs),
          _ContractorTrustBadge(verified: listing.verified),
        ],
      ),
    );
  }
}

class _ContractorTrustBadge extends StatelessWidget {
  const _ContractorTrustBadge({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final color = verified
        ? context.colorScheme.success
        : context.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verified ? Icons.verified_rounded : Icons.shield_outlined,
          size: BatshIconSize.sm,
          color: color,
        ),
        const SizedBox(width: BatshSpacing.xxs),
        Text(
          verified
              ? context.l10n.verifiedStatus
              : context.l10n.unverifiedStatus,
          style: BatshTypography.labelSm.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ContractorStatsRow extends StatelessWidget {
  const _ContractorStatsRow({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final rating = listing.rating;
    final tiles = <Widget>[
      if (rating != null)
        _ContractorProfileStat(
          value: rating.toStringAsFixed(1),
          label: context.l10n.ratingCaption,
          icon: Icons.star_border_rounded,
          color: context.colorScheme.warning,
        ),
      if (listing.projectsCompleted > 0)
        _ContractorProfileStat(
          value: '${listing.projectsCompleted}',
          label: context.l10n.projects,
          icon: Icons.work_outline_rounded,
        ),
      if (listing.yearsExperience != null && listing.yearsExperience! > 0)
        _ContractorProfileStat(
          value: '${listing.yearsExperience}',
          label: context.l10n.experienceYears,
          icon: Icons.schedule_outlined,
        ),
    ];

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) _ContractorStatDivider(),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _ContractorProfileStat extends StatelessWidget {
  const _ContractorProfileStat({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
        child: Column(
          children: [
            Icon(
              icon,
              size: BatshIconSize.sm,
              color: color ?? context.colorScheme.primary,
            ),
            const SizedBox(height: BatshSpacing.xxs),
            Text(
              value,
              style: BatshTypography.titleLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractorStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 54,
    color: context.colorScheme.outlineVariant.withValues(alpha: 0.65),
  );
}

class _ContractorCompletionBlock extends StatelessWidget {
  const _ContractorCompletionBlock({required this.completion});

  final _ProfileCompletion completion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.xs,
        BatshSpacing.md,
        BatshSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.profileCompletionTitle,
                style: BatshTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${completion.value}%',
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xs),
          Semantics(
            label: context.l10n.profileCompletionPercent(completion.value),
            value: '${completion.value}%',
            child: ClipRRect(
              borderRadius: BatshRadius.brFull,
              child: LinearProgressIndicator(
                minHeight: 5,
                value: completion.value / 100,
                backgroundColor: context.colorScheme.surfaceContainerHigh,
                color: context.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            completion.value == 100
                ? context.l10n.profileCompleteMessage
                : context.l10n.profileIncompleteMessage,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractorProfileActions extends StatelessWidget {
  const _ContractorProfileActions({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: BatshButton(
              label: context.l10n.completeProfileAction,
              onPressed: () => context.push(Routes.contractorEditProfile),
              animate: false,
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: BatshButton(
              label: context.l10n.previewPublicProfile,
              style: BatshButtonStyle.secondary,
              onPressed: () => _openPreview(context),
              animate: false,
            ),
          ),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: context.colorScheme.surface,
          body: ContractorShowcase(listing: listing, mode: ShowcaseMode.public),
        ),
      ),
    );
  }
}

class _ContractorSectionLabel extends StatelessWidget {
  const _ContractorSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.titleLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContractorChecklist extends StatelessWidget {
  const _ContractorChecklist({
    required this.listing,
    required this.portfolioCount,
    required this.verificationStatus,
  });

  final ContractorListing listing;
  final int portfolioCount;
  final VerificationStatus? verificationStatus;

  @override
  Widget build(BuildContext context) {
    final verificationDone =
        listing.verified || verificationStatus == VerificationStatus.approved;
    return _ContractorPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ContractorChecklistItem(
            icon: Icons.photo_library_outlined,
            title: context.l10n.addFirstProject,
            subtitle: context.l10n.addFirstProjectSubtitle,
            complete: portfolioCount > 0,
            onTap: portfolioCount > 0
                ? null
                : () => context.push(Routes.contractorPortfolioNew),
          ),
          _ContractorChecklistDivider(),
          _ContractorChecklistItem(
            icon: Icons.verified_user_outlined,
            title: context.l10n.verifyAccount,
            subtitle: context.l10n.verifyAccountSubtitle,
            complete: verificationDone,
            pending: verificationStatus == VerificationStatus.pending,
            onTap:
                verificationDone ||
                    verificationStatus == VerificationStatus.pending
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VerificationScreen(),
                    ),
                  ),
          ),
          _ContractorChecklistDivider(),
          _ContractorChecklistItem(
            icon: Icons.location_on_outlined,
            title: context.l10n.addWorkAreas,
            subtitle: context.l10n.addWorkAreasSubtitle,
            complete: listing.serviceAreas.isNotEmpty,
            onTap: listing.serviceAreas.isNotEmpty
                ? null
                : () => context.push(Routes.contractorEditProfile),
          ),
        ],
      ),
    );
  }
}

class _ContractorChecklistItem extends StatelessWidget {
  const _ContractorChecklistItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.complete,
    this.pending = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool complete;
  final bool pending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = complete || pending
        ? context.colorScheme.success
        : context.colorScheme.primary;
    final status = complete
        ? context.l10n.completedLabel
        : pending
        ? context.l10n.verificationPending
        : context.l10n.more;

    return Semantics(
      button: onTap != null,
      label: '$title. $subtitle',
      hint: onTap == null ? status : null,
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            BatshSpacing.md,
            BatshSpacing.sm,
            BatshSpacing.md,
            BatshSpacing.sm,
          ),
          child: Row(
            children: [
              _ContractorIconContainer(icon: icon, color: statusColor),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BatshTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              if (complete || pending)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      complete
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: BatshIconSize.sm,
                      color: statusColor,
                    ),
                    const SizedBox(width: BatshSpacing.xxs),
                    Text(
                      status,
                      style: BatshTypography.labelSm.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Icon(
                  Icons.chevron_left_rounded,
                  size: BatshIconSize.md,
                  color: context.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContractorChecklistDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 58,
    endIndent: BatshSpacing.md,
    color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
  );
}

class _ContractorIconContainer extends StatelessWidget {
  const _ContractorIconContainer({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BatshRadius.brMd,
      ),
      child: Icon(icon, size: BatshIconSize.md, color: color),
    );
  }
}

class _ContractorPerformanceCard extends StatelessWidget {
  const _ContractorPerformanceCard({
    required this.onAddProject,
    required this.onCompleteProfile,
  });

  final VoidCallback onAddProject;
  final VoidCallback onCompleteProfile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${context.l10n.performanceEmptyTitle}. ${context.l10n.performanceEmptyMessage}',
      child: _ContractorPanel(
        padding: const EdgeInsets.all(BatshSpacing.md),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.performanceEmptyTitle,
                          style: BatshTypography.titleMd.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.xxs),
                        Text(
                          context.l10n.performanceEmptyMessage,
                          style: BatshTypography.bodySm.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.md),
                  const SizedBox(
                    width: 90,
                    height: 84,
                    child: _PerformanceIllustration(),
                  ),
                ],
              ),
              const SizedBox(height: BatshSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: BatshButton(
                      label: context.l10n.addFirstProject,
                      icon: Icons.add_photo_alternate_outlined,
                      fullWidth: false,
                      animate: false,
                      onPressed: onAddProject,
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.sm),
                  Expanded(
                    child: BatshButton(
                      label: context.l10n.completeProfileAction,
                      style: BatshButtonStyle.secondary,
                      icon: Icons.edit_outlined,
                      fullWidth: false,
                      animate: false,
                      onPressed: onCompleteProfile,
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

class _PerformanceIllustration extends StatelessWidget {
  const _PerformanceIllustration();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PerformancePainter(
      color: context.colorScheme.primary.withValues(alpha: 0.20),
      accent: context.colorScheme.success.withValues(alpha: 0.65),
    ),
  );
}

class _PerformancePainter extends CustomPainter {
  const _PerformancePainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final bars = Paint()..color = color.withValues(alpha: 0.60);
    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.10, size.height * 0.82),
      Offset(size.width * 0.92, size.height * 0.82),
      base,
    );
    final barWidth = size.width * 0.12;
    final heights = [0.25, 0.42, 0.34, 0.64, 0.52];
    for (var i = 0; i < heights.length; i++) {
      final left = size.width * 0.14 + i * (barWidth + size.width * 0.05);
      final top = size.height * (0.78 - heights[i] * 0.62);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, size.height * 0.78 - top),
          const Radius.circular(3),
        ),
        bars,
      );
    }
    final line = Path()
      ..moveTo(size.width * 0.12, size.height * 0.56)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.38,
        size.width * 0.43,
        size.height * 0.52,
        size.width * 0.57,
        size.height * 0.30,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.14,
        size.width * 0.78,
        size.height * 0.30,
        size.width * 0.90,
        size.height * 0.10,
      );
    canvas.drawPath(line, accentPaint);
  }

  @override
  bool shouldRepaint(_PerformancePainter oldDelegate) =>
      color != oldDelegate.color || accent != oldDelegate.accent;
}

class _ContractorProCard extends ConsumerWidget {
  const _ContractorProCard({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billing = ref.watch(billingStateProvider).asData?.value;
    final placementStatus = billing?.isSponsoredActive == true
        ? context.l10n.specialProActive
        : billing?.hasPendingSponsoredRequest == true
        ? context.l10n.specialProPending
        : null;
    final title = listing.isPro
        ? context.l10n.proActiveLine
        : context.l10n.proCardTitle;
    final subtitle = listing.isPro
        ? context.l10n.proManageSubtitle
        : context.l10n.proCardSubtitle;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: context.colorScheme.primary,
        borderRadius: BatshRadius.brXl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(Routes.pro),
          child: SizedBox(
            height: 124,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: _ArchitecturalPattern(
                      color: context.colorScheme.onPrimary.withValues(
                        alpha: 0.13,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(BatshSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        color: context.colorScheme.tertiaryContainer,
                        size: BatshIconSize.lg,
                      ),
                      const SizedBox(width: BatshSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: BatshTypography.titleMd.copyWith(
                                color: context.colorScheme.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: BatshSpacing.xxs),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: BatshTypography.labelSm.copyWith(
                                color: context.colorScheme.onPrimary.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                            ),
                            if (placementStatus != null) ...[
                              const SizedBox(height: BatshSpacing.xxs),
                              Text(
                                placementStatus,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BatshTypography.labelSm.copyWith(
                                  color: context.colorScheme.tertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: BatshSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: BatshSpacing.sm,
                                vertical: BatshSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    context.colorScheme.surfaceContainerLowest,
                                borderRadius: BatshRadius.brSm,
                              ),
                              child: Text(
                                context.l10n.proLearnMore,
                                style: BatshTypography.labelSm.copyWith(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContractorAccountPreferences extends StatelessWidget {
  const _ContractorAccountPreferences({
    required this.onSettings,
    required this.onNotifications,
  });

  final VoidCallback onSettings;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return _ContractorPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ContractorPreferenceRow(
            icon: Icons.tune_rounded,
            title: context.l10n.settingsEntryTitle,
            subtitle: context.l10n.settingsEntrySubtitle,
            onTap: onSettings,
          ),
          _ContractorPreferenceDivider(),
          _ContractorPreferenceRow(
            icon: Icons.notifications_none_rounded,
            title: context.l10n.notificationsTitle,
            subtitle: context.l10n.notificationsSubtitle,
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _ContractorPreferenceRow extends StatelessWidget {
  const _ContractorPreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: onTap,
        excludeFromSemantics: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            BatshSpacing.md,
            BatshSpacing.sm,
            BatshSpacing.md,
            BatshSpacing.sm,
          ),
          child: Row(
            children: [
              _ContractorIconContainer(
                icon: icon,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BatshTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                size: BatshIconSize.md,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContractorPreferenceDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 58,
    endIndent: BatshSpacing.md,
    color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
  );
}

class _ContractorPanel extends StatelessWidget {
  const _ContractorPanel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXxl,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _ArchitecturalPattern extends StatelessWidget {
  const _ArchitecturalPattern({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ArchitecturalPatternPainter(color),
    child: const SizedBox.expand(),
  );
}

class _ArchitecturalPatternPainter extends CustomPainter {
  const _ArchitecturalPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final radius = size.shortestSide * 0.18;
    for (var i = 0; i < 5; i++) {
      final inset = i * 14.0;
      canvas.drawArc(
        Rect.fromLTWH(
          size.width * 0.58 - inset,
          size.height * 0.34 - inset,
          radius + inset * 2,
          radius + inset * 2,
        ),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
    for (var i = -2; i < 7; i++) {
      final y = size.height * 0.10 + i * 22;
      final path = Path()
        ..moveTo(size.width * 0.54, y)
        ..cubicTo(
          size.width * 0.68,
          y - 12,
          size.width * 0.82,
          y + 12,
          size.width,
          y,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ArchitecturalPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ProfileFallback extends StatelessWidget {
  const _ProfileFallback({required this.profile, required this.onSignOut});

  final Profile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return BatshScaffold(
      title: context.l10n.profileTitle,
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.lg,
        BatshSpacing.md,
        BatshSpacing.xxxxl,
      ),
      body: ListView(
        children: [
          _ContractorPanel(
            padding: const EdgeInsets.all(BatshSpacing.lg),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: context.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: context.colorScheme.primary,
                    size: BatshIconSize.xl,
                  ),
                ),
                const SizedBox(height: BatshSpacing.md),
                Text(
                  profile.fullName,
                  style: BatshTypography.titleLg.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Text(
                  context.l10n.profileError,
                  textAlign: TextAlign.center,
                  style: BatshTypography.bodySm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          BatshButton(
            label: context.l10n.signOutButton,
            style: BatshButtonStyle.secondary,
            onPressed: onSignOut,
          ),
          const SizedBox(height: BatshSpacing.sm),
          const _DeleteAccountTile(),
        ],
      ),
    );
  }
}
