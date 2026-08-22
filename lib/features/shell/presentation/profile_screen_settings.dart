part of 'profile_screen.dart';

class ContractorSettingsScreen extends ConsumerWidget {
  const ContractorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final listing = profile == null
        ? null
        : ref.watch(contractorByIdProvider(profile.id)).value;
    final verificationStatus = ref.watch(verificationStatusProvider).value;

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
          _ContractorSettingsSectionLabel(context.l10n.settingsAccountSection),
          const SizedBox(height: BatshSpacing.sm),
          _SettingsGroup(
            children: [
              _VerificationTile(
                verified: listing?.verified ?? false,
                status: verificationStatus,
              ),
              const _LanguageTile(),
            ],
          ),
          const SizedBox(height: BatshSpacing.xl),
          _ContractorSettingsSectionLabel(
            context.l10n.settingsPreferencesSection,
          ),
          const SizedBox(height: BatshSpacing.sm),
          _SettingsGroup(
            children: [const _AppearanceTile(), const _NotificationsTile()],
          ),
          const SizedBox(height: BatshSpacing.xl),
          _ContractorSettingsSectionLabel(context.l10n.settingsSupportSection),
          const SizedBox(height: BatshSpacing.sm),
          _SettingsGroup(
            children: [
              const _HelpTile(),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: context.l10n.privacyPolicy,
                trailing: Icon(
                  Icons.chevron_left,
                  color: context.colorScheme.onSurfaceVariant,
                  size: BatshIconSize.md,
                ),
                onTap: () => context.push(Routes.contractorPrivacy),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                label: context.l10n.termsOfService,
                trailing: Icon(
                  Icons.chevron_left,
                  color: context.colorScheme.onSurfaceVariant,
                  size: BatshIconSize.md,
                ),
                onTap: () => context.push(Routes.contractorTerms),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xl),
          _ContractorSettingsSectionLabel(
            context.l10n.settingsAccountManagementSection,
          ),
          const SizedBox(height: BatshSpacing.sm),
          _LogoutRow(onTap: () => _confirmSignOut(context, ref)),
          const SizedBox(height: BatshSpacing.sm),
          const _DeleteAccountTile(),
        ],
      ),
    );
  }
}

class _ContractorSettingsSectionLabel extends StatelessWidget {
  const _ContractorSettingsSectionLabel(this.text);

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
            style: BatshTypography.titleLg.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact grouped settings with hairline dividers between rows.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 64,
            color: context.colorScheme.outlineVariant,
          ),
        );
      }
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
        child: ColoredBox(
          color: context.colorScheme.surfaceContainerLowest,
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
        borderRadius: BatshRadius.brXl,
        boxShadow: BatshShadows.soft,
      ),
      child: Material(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: context.colorScheme.error.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.lg,
              vertical: BatshSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BatshRadius.brMd,
                  ),
                  child: Icon(
                    Icons.logout,
                    color: context.colorScheme.error,
                    size: BatshIconSize.md,
                  ),
                ),
                const SizedBox(width: BatshSpacing.gutter),
                Expanded(
                  child: Text(
                    context.l10n.signOutButton,
                    style: BatshTypography.bodyLg.copyWith(
                      color: context.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: context.colorScheme.error,
                  size: BatshIconSize.md,
                ),
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
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surfaceContainerLowest,
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
                  color: context.colorScheme.primaryFixed.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BatshRadius.brMd,
                ),
                child: Icon(
                  icon,
                  color: context.colorScheme.primary,
                  size: BatshIconSize.md,
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
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
                          color: context.colorScheme.onSurfaceVariant,
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

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isEnglish = locale.languageCode == 'en';

    return _SettingsTile(
      icon: isEnglish ? Icons.language : Icons.translate,
      label: context.l10n.languageTitle,
      subtitle: context.l10n.languageSubtitle,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.primaryContainer,
          borderRadius: BatshRadius.brSm,
        ),
        child: Text(
          isEnglish
              ? context.l10n.languageEnglish
              : context.l10n.languageArabic,
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () => context.push(Routes.contractorLanguage),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({required this.verified, this.status});

  final bool verified;
  final VerificationStatus? status;

  @override
  Widget build(BuildContext context) {
    final pending = status == VerificationStatus.pending;
    final rejected = status == VerificationStatus.rejected;
    final label = verified
        ? context.l10n.verifiedStatus
        : pending
        ? context.l10n.verificationPending
        : rejected
        ? context.l10n.unverifiedStatus
        : context.l10n.unverifiedStatus;
    final color = verified
        ? context.colorScheme.success
        : pending
        ? context.colorScheme.warning
        : context.colorScheme.primary;
    return _SettingsTile(
      icon: verified ? Icons.verified_rounded : Icons.verified_user_outlined,
      label: context.l10n.verifyTileLabel,
      subtitle: context.l10n.verifySubtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: BatshTypography.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: BatshSpacing.xs),
          Icon(
            Icons.chevron_left_rounded,
            color: context.colorScheme.onSurfaceVariant,
            size: BatshIconSize.md,
          ),
        ],
      ),
      onTap: verified || pending
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VerificationScreen()),
            ),
    );
  }
}

class _AppearanceTile extends ConsumerWidget {
  const _AppearanceTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return _SettingsTile(
      icon: mode == ThemeMode.dark
          ? Icons.dark_mode_outlined
          : Icons.light_mode_outlined,
      label: context.l10n.homeownerAppearanceAndMotionTitle,
      subtitle: context.l10n.homeownerAppearanceAndMotionSubtitle,
      trailing: _AppearanceSelector(
        mode: mode,
        onChanged: (next) =>
            ref.read(themeModeProvider.notifier).setThemeMode(next),
      ),
      onTap: () => context.push(Routes.contractorAppearance),
    );
  }
}

class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.appearanceTitle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AppearanceChoice(
            label: context.l10n.appearanceDay,
            selected: mode == ThemeMode.light,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _AppearanceChoice(
            label: context.l10n.appearanceDark,
            selected: mode == ThemeMode.dark,
            onTap: () => onChanged(ThemeMode.dark),
          ),
          _AppearanceChoice(
            label: context.l10n.appearanceSystem,
            selected: mode == ThemeMode.system,
            onTap: () => onChanged(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _AppearanceChoice extends StatelessWidget {
  const _AppearanceChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BatshRadius.brSm,
      child: AnimatedContainer(
        duration: BatshMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.colorScheme.primary : Colors.transparent,
          borderRadius: BatshRadius.brSm,
        ),
        child: Text(
          label,
          style: BatshTypography.labelSm.copyWith(
            color: selected
                ? context.colorScheme.onPrimary
                : context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NotificationsTile extends StatelessWidget {
  const _NotificationsTile();

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.notifications_none_rounded,
      label: context.l10n.notificationsTitle,
      subtitle: context.l10n.notificationsSubtitle,
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: context.colorScheme.onSurfaceVariant,
        size: BatshIconSize.md,
      ),
      onTap: () => _showNotificationSheet(context),
    );
  }

  Future<void> _showNotificationSheet(BuildContext context) async {
    await showNotificationPreferencesSheet(context);
  }
}

class _NotificationPreferencesSheet extends StatefulWidget {
  const _NotificationPreferencesSheet();

  @override
  State<_NotificationPreferencesSheet> createState() =>
      _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState
    extends State<_NotificationPreferencesSheet> {
  bool _requests = true;
  bool _messages = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.sm,
          BatshSpacing.lg,
          BatshSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.notificationsTitle,
              style: BatshTypography.titleLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.notificationsRequests),
              value: _requests,
              onChanged: (value) => setState(() => _requests = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.notificationsMessages),
              value: _messages,
              onChanged: (value) => setState(() => _messages = value),
            ),
          ],
        ),
      ),
    );
  }
}

/// Support number for the "المساعدة والدعم" tile. ponytail: single knob —
/// set this to the real Shattab support WhatsApp before launch.
const String _supportPhone = shattabSupportPhone;

/// Where the published legal documents live.
///
/// Both stores require a reachable privacy-policy URL, and App Store guideline
/// 1.2 expects the terms (the EULA covering user-generated content) to be
/// reachable from inside the app, not only from the store listing. The source
/// documents are in `docs/legal/` — host them and point these at the result.
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
      BatshSnack.error(context, context.l10n.couldNotOpenApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.support_agent_outlined,
      label: context.l10n.helpSupport,
      subtitle: context.l10n.helpSubtitle,
      trailing: Icon(
        Icons.chevron_left,
        color: context.colorScheme.onSurfaceVariant,
        size: BatshIconSize.md,
      ),
      onTap: () => _open(context),
    );
  }
}

/// Opens a published legal document in the browser.

/// Permanent account deletion — required in-app by Google Play for any app
/// that creates accounts in-app.
///
/// Guarded by typed confirmation rather than a plain "are you sure": this
/// erases briefs, quotes, posts, photos and reviews with no recovery path, and
/// a misplaced tap in a settings list should not be able to trigger it. The
/// work happens server-side in `delete_my_account()` so the account
/// cannot end up half-deleted.
class _DeleteAccountTile extends ConsumerWidget {
  const _DeleteAccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = context.colorScheme.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BatshRadius.brXl,
        boxShadow: BatshShadows.soft,
      ),
      child: Material(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showHomeownerDeleteSheet(context, ref),
          splashColor: accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.lg,
              vertical: BatshSpacing.md,
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
                  child: Icon(
                    Icons.delete_forever_outlined,
                    color: accent,
                    size: BatshIconSize.md,
                  ),
                ),
                const SizedBox(width: BatshSpacing.gutter),
                Expanded(
                  child: Text(
                    context.l10n.deleteAccount,
                    style: BatshTypography.bodyLg.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_left, color: accent, size: BatshIconSize.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
