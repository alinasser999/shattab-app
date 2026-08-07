part of 'profile_screen.dart';

/// Homeowner account surfaces translated from the approved account boards.
///
/// This stays in the shell library so the account can share the existing role
/// switcher, auth confirmation flow, localization context, and profile data
/// without creating a second account architecture.
class HomeownerAccountScreen extends ConsumerWidget {
  const HomeownerAccountScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeowner = ref.watch(homeownerProfileProvider).value;
    final saved = ref.watch(savedContractorIdsProvider);
    final briefs = ref.watch(myBriefsProvider);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final savedCount = saved.maybeWhen(
      data: (items) => '${items.length}',
      orElse: () => '—',
    );
    final requestCount = briefs.maybeWhen(
      data: (items) => '${items.length}',
      orElse: () => '—',
    );

    final content = <Widget>[
      const SizedBox(height: BatshSpacing.sm),
      _HomeownerHeroCard(
        profile: profile,
        homeowner: homeowner,
        requestsCount: requestCount,
        savedCount: savedCount,
        onEdit: () => context.push(Routes.homeownerEditProfile),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _HomeownerSectionHeading(text: context.l10n.homeownerQuickActions),
      const SizedBox(height: BatshSpacing.sm),
      _HomeownerQuickActions(
        onDiscover: () => context.go(Routes.homeownerDiscover),
        onRequests: () => context.go(Routes.homeownerProfileOrders),
        onSaved: () => context.go(Routes.homeownerSaved),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _HomeownerSectionHeading(text: context.l10n.homeownerSettingsPreview),
      const SizedBox(height: BatshSpacing.sm),
      _AccountSettingsPreview(
        onAppearance: () => context.push(Routes.homeownerAppearance),
        onMotion: () => context.push(Routes.homeownerAppearance),
        onLanguage: () => context.push(Routes.homeownerLanguage),
      ),
      const SizedBox(height: BatshSpacing.xl),
      _HomeownerAccountFooter(
        onSettings: () => context.push(Routes.homeownerSettings),
        onSignOut: () => _showHomeownerLogoutSheet(context, ref),
        onDelete: () => _showHomeownerDeleteSheet(context, ref),
      ),
      const SizedBox(height: BatshSpacing.xxl),
    ];

    Widget list = ListView(
      padding: EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshBottomNav.contentBottomInset(context),
      ),
      children: content,
    );
    if (!reduced) {
      list = list
          .animate()
          .fadeIn(duration: 300.ms, curve: BatshMotion.easeOut)
          .slideY(begin: 0.025, end: 0, curve: BatshMotion.easeOut);
    }

    return BatshScaffold(
      title: context.l10n.profileTitle,
      actions: [
        _AccountRoleSwitcher(role: UserRole.homeowner),
        const SizedBox(width: BatshSpacing.sm),
      ],
      padding: EdgeInsets.zero,
      animateEntrance: false,
      backgroundColor: context.colorScheme.surface,
      body: list,
    );
  }
}

class _HomeownerHeroCard extends StatelessWidget {
  const _HomeownerHeroCard({
    required this.profile,
    required this.homeowner,
    required this.requestsCount,
    required this.savedCount,
    required this.onEdit,
  });

  final Profile profile;
  final HomeownerProfile? homeowner;
  final String requestsCount;
  final String savedCount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName.trim().isEmpty ? '—' : profile.fullName;
    final area = homeowner?.district?.trim().isNotEmpty == true
        ? homeowner!.district!
        : homeowner?.city?.trim().isNotEmpty == true
        ? homeowner!.city!
        : context.l10n.homeownerAreaFallback;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXxl,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BatshRadius.brXxl,
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 158,
                  width: double.infinity,
                  child: _HomeownerHeroImage(),
                ),
                _HomeownerProfilePanel(
                  profile: profile,
                  name: name,
                  area: area,
                  requestsCount: requestsCount,
                  savedCount: savedCount,
                  onEdit: onEdit,
                ),
              ],
            ),
            PositionedDirectional(
              top: 112,
              start: 0,
              end: 0,
              child: Center(
                child: _HomeownerAvatar(
                  profile: profile,
                  name: name,
                  onEdit: onEdit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeownerHeroImage extends StatelessWidget {
  const _HomeownerHeroImage();

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/images/featured_card_template.png',
      fit: BoxFit.cover,
      excludeFromSemantics: true,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: mockupHeroImage,
          fit: BoxFit.cover,
          memCacheWidth: 900,
          placeholder: (_, _) => fallback,
          errorWidget: (_, _, _) => fallback,
        ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.22),
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          top: BatshSpacing.sm,
          end: BatshSpacing.sm,
          child: _HomeownerHeroTag(
            icon: Icons.home_outlined,
            label: context.l10n.homeownerAccountRole,
          ),
        ),
      ],
    );
  }
}

class _HomeownerHeroTag extends StatelessWidget {
  const _HomeownerHeroTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsetsDirectional.fromSTEB(
        BatshSpacing.sm,
        BatshSpacing.xs,
        BatshSpacing.sm,
        BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BatshRadius.brFull,
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: BatshIconSize.sm, color: Colors.white),
          const SizedBox(width: BatshSpacing.xs),
          Text(
            label,
            style: BatshTypography.labelMd.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeownerProfilePanel extends StatelessWidget {
  const _HomeownerProfilePanel({
    required this.profile,
    required this.name,
    required this.area,
    required this.requestsCount,
    required this.savedCount,
    required this.onEdit,
  });

  final Profile profile;
  final String name;
  final String area;
  final String requestsCount;
  final String savedCount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _HomeownerArchitecturePainter()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.md,
            52,
            BatshSpacing.md,
            BatshSpacing.md,
          ),
          child: Column(
            children: [
              Text(
                context.l10n.greetingMorning,
                style: BatshTypography.labelLg.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: BatshSpacing.xxs),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: BatshTypography.headlineMd.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: BatshSpacing.xxs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_work_outlined,
                    size: BatshIconSize.sm,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: BatshSpacing.xs),
                  Text(
                    '${context.l10n.homeownerAccountRole} • $area',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.bodySm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BatshSpacing.sm),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: BatshIconSize.sm),
                label: Text(context.l10n.homeownerEditProfileAction),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  foregroundColor: context.colorScheme.primary,
                  side: BorderSide(
                    color: context.colorScheme.primary.withValues(alpha: 0.55),
                  ),
                  shape: const StadiumBorder(),
                  textStyle: BatshTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: BatshSpacing.md),
              _HomeownerStatsRail(requests: requestsCount, saved: savedCount),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeownerAvatar extends StatelessWidget {
  const _HomeownerAvatar({
    required this.profile,
    required this.name,
    required this.onEdit,
  });

  final Profile profile;
  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    const initial = 'm';
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colorScheme.surfaceContainerLowest,
                width: 5,
              ),
              boxShadow: BatshShadows.soft,
            ),
            child: profile.avatarUrl?.trim().isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: profile.avatarUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _HomeownerInitial(initial),
                  )
                : _HomeownerInitial(initial),
          ),
          PositionedDirectional(
            bottom: -3,
            end: -3,
            child: Material(
              color: context.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onEdit,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: BatshIconSize.sm,
                    color: Colors.white,
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

class _HomeownerInitial extends StatelessWidget {
  const _HomeownerInitial(this.initial);
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: BatshTypography.headlineLg.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HomeownerStatsRail extends StatelessWidget {
  const _HomeownerStatsRail({required this.requests, required this.saved});

  final String requests;
  final String saved;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BatshRadius.brLg,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _HomeownerStat(
                icon: Icons.assignment_outlined,
                value: requests,
                label: context.l10n.myRequests,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            Expanded(
              child: _HomeownerStat(
                icon: Icons.bookmark_border,
                value: saved,
                label: context.l10n.mySaved,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeownerStat extends StatelessWidget {
  const _HomeownerStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: BatshIconSize.md,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: BatshSpacing.xs),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: BatshTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeownerQuickActions extends StatelessWidget {
  const _HomeownerQuickActions({
    required this.onDiscover,
    required this.onRequests,
    required this.onSaved,
  });

  final VoidCallback onDiscover;
  final VoidCallback onRequests;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    // The action group lives inside a vertical ListView, so its asymmetric
    // columns need an explicit height before Expanded can divide the space.
    return SizedBox(
      height: 212,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: _HomeownerActionCard(
              icon: Icons.explore_outlined,
              title: context.l10n.discoverContractors,
              subtitle: context.l10n.homeownerDiscoverSubtitle,
              primary: true,
              onTap: onDiscover,
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            flex: 10,
            child: Column(
              children: [
                Expanded(
                  child: _HomeownerActionCard(
                    icon: Icons.assignment_outlined,
                    title: context.l10n.myRequests,
                    subtitle: context.l10n.homeownerRequestsSubtitle,
                    onTap: onRequests,
                  ),
                ),
                const SizedBox(height: BatshSpacing.sm),
                Expanded(
                  child: _HomeownerActionCard(
                    icon: Icons.bookmark_border,
                    title: context.l10n.mySaved,
                    subtitle: context.l10n.homeownerSavedSubtitle,
                    onTap: onSaved,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeownerActionCard extends StatelessWidget {
  const _HomeownerActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final compact = !primary;
    final foreground = primary
        ? context.colorScheme.onPrimary
        : context.colorScheme.onSurface;
    final muted = primary
        ? context.colorScheme.onPrimary.withValues(alpha: 0.78)
        : context.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: '$title، $subtitle',
      child: Material(
        color: primary
            ? context.colorScheme.primary
            : context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: compact
                ? const EdgeInsetsDirectional.fromSTEB(
                    BatshSpacing.sm,
                    BatshSpacing.xs,
                    BatshSpacing.sm,
                    BatshSpacing.xs,
                  )
                : const EdgeInsets.all(BatshSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: compact ? 30 : 38,
                  height: compact ? 30 : 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.16)
                        : context.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: foreground,
                    size: compact ? BatshIconSize.sm : BatshIconSize.md,
                  ),
                ),
                Text(
                  title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (compact
                              ? BatshTypography.labelMd
                              : BatshTypography.titleMd)
                          .copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                ),
                Text(
                  subtitle,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (compact
                              ? BatshTypography.labelSm
                              : BatshTypography.labelSm)
                          .copyWith(color: muted),
                ),
                Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    size: compact ? BatshIconSize.sm : BatshIconSize.md,
                    color: foreground,
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

class _AccountSettingsPreview extends ConsumerWidget {
  const _AccountSettingsPreview({
    required this.onAppearance,
    required this.onMotion,
    required this.onLanguage,
  });

  final VoidCallback onAppearance;
  final VoidCallback onMotion;
  final VoidCallback onLanguage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final motion = ref.watch(motionModeProvider);
    final locale = ref.watch(localeProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        children: [
          _AccountPreviewRow(
            icon: mode == ThemeMode.dark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            label: context.l10n.homeownerAppearanceRow,
            value: switch (mode) {
              ThemeMode.light => context.l10n.appearanceDay,
              ThemeMode.dark => context.l10n.appearanceDark,
              ThemeMode.system => context.l10n.appearanceSystem,
            },
            onTap: onAppearance,
          ),
          _AccountRowDivider(),
          _AccountPreviewRow(
            icon: motion == MotionMode.off
                ? Icons.motion_photos_off_outlined
                : Icons.graphic_eq_outlined,
            label: context.l10n.homeownerMotionRow,
            value: ref.read(motionModeProvider.notifier).label,
            onTap: onMotion,
          ),
          _AccountRowDivider(),
          _AccountPreviewRow(
            icon: Icons.translate_outlined,
            label: context.l10n.homeownerLanguageRow,
            value: locale.languageCode == 'en'
                ? context.l10n.languageEnglish
                : context.l10n.languageArabic,
            onTap: onLanguage,
          ),
        ],
      ),
    );
  }
}

class _AccountPreviewRow extends StatelessWidget {
  const _AccountPreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label، $value',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.md,
            vertical: BatshSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryContainer,
                  borderRadius: BatshRadius.brMd,
                ),
                child: Icon(
                  icon,
                  size: BatshIconSize.md,
                  color: context.colorScheme.primary,
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: BatshTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                value,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
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

class _AccountRowDivider extends StatelessWidget {
  const _AccountRowDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: 64,
    color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
  );
}

class _HomeownerAccountFooter extends StatelessWidget {
  const _HomeownerAccountFooter({
    required this.onSettings,
    required this.onSignOut,
    required this.onDelete,
  });

  final VoidCallback onSettings;
  final VoidCallback onSignOut;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HomeownerSectionHeading(
          text: context.l10n.homeownerAccountExperienceSection,
        ),
        const SizedBox(height: BatshSpacing.sm),
        _HomeownerPreferenceRow(
          icon: Icons.tune_outlined,
          label: context.l10n.homeownerSettingsRow,
          subtitle: context.l10n.homeownerSettingsSubtitle,
          onTap: onSettings,
        ),
        const SizedBox(height: BatshSpacing.xs),
        _HomeownerPreferenceRow(
          icon: Icons.notifications_none_rounded,
          label: context.l10n.notificationsTitle,
          subtitle: context.l10n.notificationsSubtitle,
          onTap: () => _showNotificationPreferences(context),
        ),
        const SizedBox(height: BatshSpacing.xs),
        _HomeownerPreferenceRow(
          icon: Icons.logout_rounded,
          label: context.l10n.signOutButton,
          subtitle: context.l10n.homeownerLogoutSubtitle,
          destructive: true,
          onTap: onSignOut,
        ),
        const SizedBox(height: BatshSpacing.xs),
        _HomeownerPreferenceRow(
          icon: Icons.delete_outline_rounded,
          label: context.l10n.deleteAccount,
          subtitle: context.l10n.homeownerDeleteSubtitle,
          destructive: true,
          onTap: onDelete,
        ),
      ],
    );
  }

  Future<void> _showNotificationPreferences(BuildContext context) async {
    await showNotificationPreferencesSheet(context);
  }
}

class _HomeownerPreferenceRow extends StatelessWidget {
  const _HomeownerPreferenceRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive
        ? context.colorScheme.error
        : context.colorScheme.primary;
    return Material(
      color: context.colorScheme.surfaceContainerLowest,
      borderRadius: BatshRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.md,
            vertical: BatshSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BatshRadius.brMd,
                ),
                child: Icon(icon, color: accent, size: BatshIconSize.md),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: BatshTypography.bodyMd.copyWith(
                        color: destructive
                            ? context.colorScheme.error
                            : context.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                color: context.colorScheme.onSurfaceVariant,
                size: BatshIconSize.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeownerSectionHeading extends StatelessWidget {
  const _HomeownerSectionHeading({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          CustomPaint(
            size: const Size(22, 22),
            painter: _HomeownerHeadingMotifPainter(
              color: context.colorScheme.primary,
            ),
          ),
          const SizedBox(width: BatshSpacing.xs),
          Text(
            text,
            style: BatshTypography.titleLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeownerArchitecturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFFDDA47F).withValues(alpha: 0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final w = size.width;
    final h = size.height;

    final arch = Path()
      ..moveTo(18, h * 0.92)
      ..lineTo(18, h * 0.35)
      ..quadraticBezierTo(18, h * 0.12, 42, h * 0.12)
      ..quadraticBezierTo(66, h * 0.12, 66, h * 0.35)
      ..lineTo(66, h * 0.92);
    canvas.drawPath(arch, line);
    canvas.save();
    canvas.translate(8, 0);
    canvas.scale(0.83, 1);
    canvas.drawPath(arch, line);
    canvas.restore();

    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(w - 64 + i * 14, 16),
        Offset(w - 64 + i * 14, 58),
        line,
      );
      canvas.drawLine(
        Offset(w - 78, 30 + i * 14),
        Offset(w - 36, 30 + i * 14),
        line,
      );
    }
    canvas.drawLine(Offset(0, h - 26), Offset(w * 0.34, h - 26), line);
    canvas.drawLine(Offset(w * 0.66, h - 26), Offset(w, h - 26), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeownerHeadingMotifPainter extends CustomPainter {
  const _HomeownerHeadingMotifPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final r = size.width * 0.22;
    canvas.drawRect(Rect.fromLTWH(r, r, r, r), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - r * 2, r, r, r), paint);
    canvas.drawLine(
      Offset(r, size.height - r),
      Offset(size.width - r, size.height - r),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeownerHeadingMotifPainter oldDelegate) =>
      oldDelegate.color != color;
}

class HomeownerSettingsScreen extends ConsumerWidget {
  const HomeownerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BatshScaffold(
      title: context.l10n.accountSettingsTitle,
      leading: IconButton(
        tooltip: context.l10n.back,
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.sm,
          BatshSpacing.md,
          BatshSpacing.xxxxl,
        ),
        children: [
          _HomeownerSectionHeading(
            text: context.l10n.homeownerSettingsExperienceSection,
          ),
          const SizedBox(height: BatshSpacing.sm),
          _HomeownerSettingsGroup(
            children: [
              _HomeownerSettingsRow(
                icon: Icons.light_mode_outlined,
                label: context.l10n.homeownerAppearanceAndMotionTitle,
                subtitle: context.l10n.homeownerAppearanceAndMotionSubtitle,
                onTap: () => context.push(Routes.homeownerAppearance),
                trailing: const Icon(Icons.chevron_left_rounded),
              ),
              _HomeownerSettingsRow(
                icon: Icons.translate_outlined,
                label: context.l10n.languageTitle,
                subtitle: context.l10n.languageSubtitle,
                onTap: () => context.push(Routes.homeownerLanguage),
                trailing: Text(
                  ref.watch(localeProvider).languageCode == 'en'
                      ? context.l10n.languageEnglish
                      : context.l10n.languageArabic,
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xl),
          _HomeownerSectionHeading(text: context.l10n.homeownerLegalSection),
          const SizedBox(height: BatshSpacing.sm),
          _HomeownerSettingsGroup(
            children: [
              _HomeownerSettingsRow(
                icon: Icons.privacy_tip_outlined,
                label: context.l10n.privacyPolicy,
                subtitle: context.l10n.homeownerPrivacySubtitle,
                onTap: () => context.push(Routes.homeownerPrivacy),
                trailing: const Icon(Icons.chevron_left_rounded),
              ),
              _HomeownerSettingsRow(
                icon: Icons.description_outlined,
                label: context.l10n.termsOfService,
                subtitle: context.l10n.homeownerTermsSubtitle,
                onTap: () => context.push(Routes.homeownerTerms),
                trailing: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xl),
          _HomeownerSectionHeading(text: context.l10n.homeownerAccountSection),
          const SizedBox(height: BatshSpacing.sm),
          _HomeownerSettingsGroup(
            children: [
              _HomeownerSettingsRow(
                icon: Icons.delete_outline_rounded,
                label: context.l10n.deleteAccount,
                subtitle: context.l10n.homeownerDeleteSubtitle,
                destructive: true,
                onTap: () => _showHomeownerDeleteSheet(context, ref),
                trailing: const Icon(Icons.chevron_left_rounded),
              ),
              _HomeownerSettingsRow(
                icon: Icons.logout_rounded,
                label: context.l10n.signOutButton,
                subtitle: context.l10n.homeownerLogoutSubtitle,
                destructive: true,
                onTap: () => _showHomeownerLogoutSheet(context, ref),
                trailing: const Icon(Icons.chevron_left_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeownerSettingsGroup extends StatelessWidget {
  const _HomeownerSettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) rows.add(const _AccountRowDivider());
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.58),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BatshRadius.brXl,
        child: Column(children: rows),
      ),
    );
  }
}

class _HomeownerSettingsRow extends StatelessWidget {
  const _HomeownerSettingsRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Widget trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? context.colorScheme.error
        : context.colorScheme.primary;
    return Semantics(
      button: true,
      label: '$label، $subtitle',
      child: Material(
        color: context.colorScheme.surfaceContainerLowest,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.md,
              vertical: BatshSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BatshRadius.brMd,
                  ),
                  child: Icon(icon, color: color, size: BatshIconSize.md),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: BatshTypography.bodyMd.copyWith(
                          color: destructive
                              ? context.colorScheme.error
                              : context.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
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
                const SizedBox(width: BatshSpacing.sm),
                IconTheme(
                  data: IconThemeData(
                    color: destructive
                        ? context.colorScheme.error
                        : context.colorScheme.onSurfaceVariant,
                    size: BatshIconSize.md,
                  ),
                  child: trailing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeownerAppearanceScreen extends ConsumerWidget {
  const HomeownerAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final motionMode = ref.watch(motionModeProvider);

    return BatshScaffold(
      title: context.l10n.homeownerAppearanceAndMotionTitle,
      leading: IconButton(
        tooltip: context.l10n.back,
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.sm,
          BatshSpacing.md,
          BatshSpacing.xxxxl,
        ),
        children: [
          _HomeownerSectionHeading(text: context.l10n.appearanceTitle),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            context.l10n.appearanceSubtitle,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            children: [
              for (final option in [
                (ThemeMode.light, context.l10n.appearanceDay),
                (ThemeMode.dark, context.l10n.appearanceDark),
                (ThemeMode.system, context.l10n.appearanceSystem),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: BatshSpacing.xs,
                    ),
                    child: _HomeownerThemeChoice(
                      mode: option.$1,
                      label: option.$2,
                      selected: option.$1 == themeMode,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(option.$1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xl),
          _HomeownerSectionHeading(text: context.l10n.homeownerMotionTitle),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            context.l10n.homeownerMotionSubtitle,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          _HomeownerMotionSelector(
            selected: motionMode,
            onChanged: (next) =>
                ref.read(motionModeProvider.notifier).set(next),
          ),
          const SizedBox(height: BatshSpacing.md),
          _HomeownerInfoPanel(
            icon: Icons.accessibility_new_outlined,
            text: context.l10n.homeownerMotionAccessibility,
          ),
          const SizedBox(height: BatshSpacing.xl),
          BatshButton(
            label: context.l10n.homeownerSaveSettings,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _HomeownerThemeChoice extends StatelessWidget {
  const _HomeownerThemeChoice({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = mode == ThemeMode.dark;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brLg,
        child: AnimatedContainer(
          duration: BatshMotion.fast,
          padding: const EdgeInsets.all(BatshSpacing.xs),
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xFF2D2924)
                : context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brLg,
            border: Border.all(
              color: selected
                  ? context.colorScheme.primary
                  : context.colorScheme.outlineVariant.withValues(alpha: 0.65),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 92,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF181511)
                        : context.colorScheme.surfaceContainerLow,
                    borderRadius: BatshRadius.brMd,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: BatshSpacing.xs),
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: dark
                              ? Colors.white.withValues(alpha: 0.6)
                              : context.colorScheme.primary,
                          borderRadius: BatshRadius.brFull,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.xs),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              _PreviewLine(dark: dark, widthFactor: 0.92),
                              _PreviewLine(dark: dark, widthFactor: 0.68),
                              _PreviewLine(dark: dark, widthFactor: 0.82),
                              const Spacer(),
                              Container(
                                height: 11,
                                width: 38,
                                decoration: BoxDecoration(
                                  color: dark
                                      ? context.colorScheme.primary
                                      : context.colorScheme.primary,
                                  borderRadius: BatshRadius.brFull,
                                ),
                              ),
                              const SizedBox(height: 7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: BatshSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelMd.copyWith(
                  color: dark ? Colors.white : context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  size: BatshIconSize.sm,
                  color: context.colorScheme.primary,
                )
              else
                const SizedBox(height: BatshIconSize.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.dark, required this.widthFactor});
  final bool dark;
  final double widthFactor;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 5,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: (dark ? Colors.white : context.colorScheme.onSurface)
              .withValues(alpha: 0.18),
          borderRadius: BatshRadius.brFull,
        ),
      ),
    ),
  );
}

class _HomeownerMotionSelector extends StatelessWidget {
  const _HomeownerMotionSelector({
    required this.selected,
    required this.onChanged,
  });
  final MotionMode selected;
  final ValueChanged<MotionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (MotionMode.full, context.l10n.motionFull),
      (MotionMode.reduced, context.l10n.motionReduced),
      (MotionMode.off, context.l10n.motionOff),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: option.$1 == selected,
                label: option.$2,
                child: InkWell(
                  onTap: () => onChanged(option.$1),
                  child: AnimatedContainer(
                    duration: BatshMotion.fast,
                    constraints: const BoxConstraints(minHeight: 48),
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: option.$1 == selected
                          ? context.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BatshRadius.brMd,
                    ),
                    child: Text(
                      option.$2,
                      style: BatshTypography.labelMd.copyWith(
                        color: option.$1 == selected
                            ? context.colorScheme.onPrimary
                            : context.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
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

class _HomeownerInfoPanel extends StatelessWidget {
  const _HomeownerInfoPanel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BatshRadius.brLg,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: context.colorScheme.primary),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: BatshTypography.bodySm.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeownerLanguageScreen extends ConsumerStatefulWidget {
  const HomeownerLanguageScreen({super.key});

  @override
  ConsumerState<HomeownerLanguageScreen> createState() =>
      _HomeownerLanguageScreenState();
}

class _HomeownerLanguageScreenState
    extends ConsumerState<HomeownerLanguageScreen> {
  late String _selected = ref.read(localeProvider).languageCode;

  @override
  Widget build(BuildContext context) {
    return BatshScaffold(
      title: context.l10n.languageTitle,
      leading: IconButton(
        tooltip: context.l10n.back,
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.sm,
          BatshSpacing.md,
          BatshSpacing.xxxxl,
        ),
        children: [
          _HomeownerSectionHeading(text: context.l10n.homeownerLanguageChoose),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            context.l10n.languageSubtitle,
            style: BatshTypography.bodySm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          _HomeownerLanguageOption(
            code: 'ar',
            title: context.l10n.languageArabic,
            subtitle: context.l10n.homeownerLanguageArabicHint,
            selected: _selected == 'ar',
            onTap: () => setState(() => _selected = 'ar'),
          ),
          const SizedBox(height: BatshSpacing.xs),
          _HomeownerLanguageOption(
            code: 'en',
            title: context.l10n.languageEnglish,
            subtitle: context.l10n.homeownerLanguageEnglishHint,
            selected: _selected == 'en',
            onTap: () => setState(() => _selected = 'en'),
          ),
          const SizedBox(height: BatshSpacing.xl),
          _HomeownerSectionHeading(text: context.l10n.homeownerLanguagePreview),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _HomeownerDirectionPreview(
                  direction: TextDirection.ltr,
                  label: context.l10n.homeownerLanguageLtr,
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: _HomeownerDirectionPreview(
                  direction: TextDirection.rtl,
                  label: context.l10n.homeownerLanguageRtl,
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xl),
          BatshButton(
            label: context.l10n.homeownerSaveLanguage,
            onPressed: () {
              ref
                  .read(localeProvider.notifier)
                  .setLocale(
                    _selected == 'en'
                        ? const Locale('en', 'US')
                        : const Locale('ar', 'EG'),
                  );
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}

class _HomeownerLanguageOption extends StatelessWidget {
  const _HomeownerLanguageOption({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brLg,
          child: AnimatedContainer(
            duration: BatshMotion.fast,
            padding: const EdgeInsets.all(BatshSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BatshRadius.brLg,
              border: Border.all(
                color: selected
                    ? context.colorScheme.primary
                    : context.colorScheme.outlineVariant.withValues(
                        alpha: 0.65,
                      ),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: BatshTypography.titleMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: BatshTypography.labelSm.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                selected
                    ? Icon(
                        Icons.check_circle,
                        color: context.colorScheme.primary,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        color: context.colorScheme.outline,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeownerDirectionPreview extends StatelessWidget {
  const _HomeownerDirectionPreview({
    required this.direction,
    required this.label,
  });

  final TextDirection direction;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.sm),
        child: Directionality(
          textDirection: direction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.primary,
                ),
              ),
              const SizedBox(height: BatshSpacing.xs),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerLow,
                  borderRadius: BatshRadius.brSm,
                ),
                child: Row(
                  children: [
                    Icon(
                      direction == TextDirection.rtl
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_forward_rounded,
                      size: BatshIconSize.sm,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: context.colorScheme.onSurface.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BatshRadius.brFull,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum HomeownerLegalDocument { privacy, terms }

class HomeownerLegalScreen extends StatelessWidget {
  const HomeownerLegalScreen({super.key, required this.document});

  final HomeownerLegalDocument document;

  @override
  Widget build(BuildContext context) {
    final privacy = document == HomeownerLegalDocument.privacy;
    final sections = privacy
        ? [
            (
              context.l10n.homeownerPrivacySection1Title,
              context.l10n.homeownerPrivacySection1Body,
            ),
            (
              context.l10n.homeownerPrivacySection2Title,
              context.l10n.homeownerPrivacySection2Body,
            ),
            (
              context.l10n.homeownerPrivacySection3Title,
              context.l10n.homeownerPrivacySection3Body,
            ),
            (
              context.l10n.homeownerPrivacySection4Title,
              context.l10n.homeownerPrivacySection4Body,
            ),
            (
              context.l10n.homeownerPrivacySection5Title,
              context.l10n.homeownerPrivacySection5Body,
            ),
          ]
        : [
            (
              context.l10n.homeownerTermsSection1Title,
              context.l10n.homeownerTermsSection1Body,
            ),
            (
              context.l10n.homeownerTermsSection2Title,
              context.l10n.homeownerTermsSection2Body,
            ),
            (
              context.l10n.homeownerTermsSection3Title,
              context.l10n.homeownerTermsSection3Body,
            ),
            (
              context.l10n.homeownerTermsSection4Title,
              context.l10n.homeownerTermsSection4Body,
            ),
            (
              context.l10n.homeownerTermsSection5Title,
              context.l10n.homeownerTermsSection5Body,
            ),
          ];

    return BatshScaffold(
      title: privacy ? context.l10n.privacyPolicy : context.l10n.termsOfService,
      leading: IconButton(
        tooltip: context.l10n.back,
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_forward_rounded),
      ),
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.sm,
          BatshSpacing.md,
          BatshSpacing.xxxxl,
        ),
        children: [
          _HomeownerLegalHeader(
            icon: privacy ? Icons.shield_outlined : Icons.description_outlined,
            title: privacy
                ? context.l10n.privacyPolicy
                : context.l10n.termsOfService,
          ),
          const SizedBox(height: BatshSpacing.md),
          Text(
            privacy
                ? context.l10n.homeownerPrivacyIntro
                : context.l10n.homeownerTermsIntro,
            textAlign: TextAlign.center,
            style: BatshTypography.bodyMd.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
          for (final section in sections) ...[
            _HomeownerLegalSection(title: section.$1, body: section.$2),
            const SizedBox(height: BatshSpacing.sm),
          ],
          const SizedBox(height: BatshSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _openHomeownerSupport(context),
            icon: const Icon(Icons.support_agent_outlined),
            label: Text(context.l10n.homeownerContactSupport),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: context.colorScheme.primary,
              side: BorderSide(color: context.colorScheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BatshRadius.brLg),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeownerLegalHeader extends StatelessWidget {
  const _HomeownerLegalHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BatshRadius.brXl,
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorScheme.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(icon, color: context.colorScheme.primary, size: 28),
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BatshTypography.titleLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeownerLegalSection extends StatelessWidget {
  const _HomeownerLegalSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.52),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BatshSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: BatshTypography.titleMd.copyWith(
                color: context.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              body,
              style: BatshTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeownerDeleteSheet extends StatefulWidget {
  const _HomeownerDeleteSheet({required this.onConfirm});
  final Future<void> Function() onConfirm;

  @override
  State<_HomeownerDeleteSheet> createState() => _HomeownerDeleteSheetState();
}

class _HomeownerDeleteSheetState extends State<_HomeownerDeleteSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = context.l10n.deleteAccountConfirmWord;
    final canConfirm = _controller.text.trim() == word;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.xs,
          BatshSpacing.lg,
          BatshSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BatshRadius.brFull,
              ),
            ),
            const SizedBox(height: BatshSpacing.md),
            _HomeownerSheetIcon(
              icon: Icons.delete_outline_rounded,
              color: context.colorScheme.error,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              context.l10n.deleteAccountTitle,
              style: BatshTypography.titleLg.copyWith(
                color: context.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              context.l10n.deleteAccountBody,
              textAlign: TextAlign.center,
              style: BatshTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.md),
            TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              enabled: !_busy,
              decoration: InputDecoration(
                hintText: context.l10n.deleteAccountConfirmHint,
                filled: true,
                fillColor: context.colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BatshRadius.brLg,
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: BatshSpacing.xs),
              Text(
                _error!,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: BatshSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !canConfirm || _busy
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final profileError = context.l10n.profileError;
                        setState(() {
                          _busy = true;
                          _error = null;
                        });
                        try {
                          await widget.onConfirm();
                          if (mounted) navigator.pop();
                        } catch (_) {
                          if (mounted) {
                            setState(() {
                              _busy = false;
                              _error = profileError;
                            });
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: context.colorScheme.error,
                  foregroundColor: context.colorScheme.onError,
                  shape: RoundedRectangleBorder(borderRadius: BatshRadius.brLg),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.deleteAccount),
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(context.l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeownerLogoutSheet extends StatelessWidget {
  const _HomeownerLogoutSheet({required this.onConfirm});
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.xs,
          BatshSpacing.lg,
          BatshSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BatshRadius.brFull,
              ),
            ),
            const SizedBox(height: BatshSpacing.md),
            _HomeownerSheetIcon(
              icon: Icons.logout_rounded,
              color: context.colorScheme.primary,
            ),
            const SizedBox(height: BatshSpacing.sm),
            Text(
              context.l10n.homeownerLogoutTitle,
              style: BatshTypography.titleLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              context.l10n.homeownerLogoutBody,
              style: BatshTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BatshSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await onConfirm();
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(context.l10n.signOutButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: context.colorScheme.primary,
                  foregroundColor: context.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BatshRadius.brLg),
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.l10n.homeownerStaySignedIn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeownerSheetIcon extends StatelessWidget {
  const _HomeownerSheetIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

Future<void> _showHomeownerDeleteSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: context.colorScheme.surfaceContainerLowest,
    builder: (_) => _HomeownerDeleteSheet(
      onConfirm: () => ref.read(authRepositoryProvider).deleteAccount(),
    ),
  );
}

Future<void> _showHomeownerLogoutSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    backgroundColor: context.colorScheme.surfaceContainerLowest,
    builder: (_) => _HomeownerLogoutSheet(
      onConfirm: () => ref.read(authRepositoryProvider).signOut(),
    ),
  );
}

Future<void> _openHomeownerSupport(BuildContext context) async {
  final uri = Uri.parse('https://wa.me/$_supportPhone');
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    BatshSnack.error(context, context.l10n.couldNotOpenApp);
  }
}
