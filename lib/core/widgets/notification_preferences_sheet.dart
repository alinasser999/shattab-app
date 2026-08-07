import 'dart:async';

import 'package:flutter/material.dart';

import '../notifications/notification_preferences.dart';
import '../l10n/l10n_extension.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import 'batsh_sheet.dart';

Future<void> showNotificationPreferencesSheet(BuildContext context) {
  return BatshSheet.show<void>(
    context,
    builder: (_) => const BatshNotificationPreferencesSheet(),
  );
}

class BatshNotificationPreferencesSheet extends StatefulWidget {
  const BatshNotificationPreferencesSheet({super.key});

  @override
  State<BatshNotificationPreferencesSheet> createState() =>
      _BatshNotificationPreferencesSheetState();
}

class _BatshNotificationPreferencesSheetState
    extends State<BatshNotificationPreferencesSheet> {
  bool _requests = true;
  bool _messages = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final preferences = await NotificationPreferences.load();
      if (!mounted) return;
      setState(() {
        _requests = preferences.requests;
        _messages = preferences.updates;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _update({bool? requests, bool? messages}) {
    setState(() {
      if (requests != null) _requests = requests;
      if (messages != null) _messages = messages;
    });
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      await NotificationPreferences(
        requests: _requests,
        updates: _messages,
      ).save();
    } catch (_) {
      // Preferences are a convenience; a storage failure must not block the UI.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.sm,
          BatshSpacing.lg,
          BatshSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.notificationsTitle,
              textAlign: TextAlign.center,
              style: BatshTypography.titleLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.xxs),
            Text(
              context.l10n.notificationsSubtitle,
              textAlign: TextAlign.center,
              style: BatshTypography.bodySm.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.notificationsRequests),
              value: _requests,
              onChanged: _loading ? null : (value) => _update(requests: value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.notificationsMessages),
              value: _messages,
              onChanged: _loading ? null : (value) => _update(messages: value),
            ),
          ],
        ),
      ),
    );
  }
}
