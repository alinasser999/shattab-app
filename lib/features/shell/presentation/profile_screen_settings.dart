part of 'profile_screen.dart';

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
        rows.add(
          const Divider(
            height: 1,
            thickness: 1,
            indent: 64,
            color: BatshColors.outlineVariant,
          ),
        );
      }
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BatshRadius.brXl,
        boxShadow: BatshShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: BatshRadius.brXl,
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
        borderRadius: BatshRadius.brXl,
        boxShadow: BatshShadows.soft,
      ),
      child: Material(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: BatshColors.error.withValues(alpha: 0.08),
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
                    color: BatshColors.error.withValues(alpha: 0.1),
                    borderRadius: BatshRadius.brMd,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: BatshColors.error,
                    size: BatshIconSize.md,
                  ),
                ),
                const SizedBox(width: BatshSpacing.gutter),
                Expanded(
                  child: Text(
                    S.signOutButton,
                    style: BatshTypography.bodyLg.copyWith(
                      color: BatshColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_left,
                  color: BatshColors.error,
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
                child: Icon(
                  icon,
                  color: BatshColors.primary,
                  size: BatshIconSize.md,
                ),
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
    final isDark =
        themeMode == ThemeMode.dark ||
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

/// Where the published legal documents live.
///
/// Both stores require a reachable privacy-policy URL, and App Store guideline
/// 1.2 expects the terms (the EULA covering user-generated content) to be
/// reachable from inside the app, not only from the store listing. The source
/// documents are in `docs/legal/` — host them and point these at the result.
const String _privacyPolicyUrl = 'https://shattab.app/privacy';
const String _termsUrl = 'https://shattab.app/terms';

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
      BatshSnack.error(context, S.couldNotOpenApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.support_agent_outlined,
      label: S.helpSupport,
      subtitle: S.helpSubtitle,
      trailing: const Icon(
        Icons.chevron_left,
        color: BatshColors.onSurfaceVariant,
        size: BatshIconSize.md,
      ),
      onTap: () => _open(context),
    );
  }
}

/// Opens a published legal document in the browser.
class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  Future<void> _open(BuildContext context) async {
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      BatshSnack.error(context, S.couldNotOpenApp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      label: label,
      trailing: const Icon(
        Icons.chevron_left,
        color: BatshColors.onSurfaceVariant,
        size: BatshIconSize.md,
      ),
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
                decoration: InputDecoration(
                  hintText: S.deleteAccountConfirmHint,
                ),
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
              child: Text(
                S.deleteAccount,
                style: const TextStyle(color: BatshColors.error),
              ),
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
      trailing: const Icon(
        Icons.chevron_left,
        color: BatshColors.onSurfaceVariant,
        size: BatshIconSize.md,
      ),
      onTap: _confirm,
    );
  }
}
