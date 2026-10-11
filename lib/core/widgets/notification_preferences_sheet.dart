import 'dart:async';

import 'package:flutter/material.dart';

import '../notifications/notification_preferences.dart';
import '../l10n/l10n_extension.dart';
import '../theme/batsh_spacing.dart';
import '../theme/batsh_typography.dart';
import 'batsh_sheet.dart';
import 'batsh_error.dart';
import 'batsh_loading.dart';

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
  bool _saving = false;
  bool _loadFailed = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final preferences = await NotificationPreferences.load();
      if (!mounted) return;
      setState(() {
        _requests = preferences.requests;
        _messages = preferences.updates;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _update({bool? requests, bool? messages}) async {
    if (_loading || _saving) return;
    final beforeRequests = _requests, beforeMessages = _messages;
    final nextRequests = requests ?? _requests,
        nextMessages = messages ?? _messages;
    setState(() {
      _saving = true;
      _saveFailed = false;
      _requests = nextRequests;
      _messages = nextMessages;
    });
    try {
      await NotificationPreferences(
        requests: nextRequests,
        updates: nextMessages,
      ).save();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _requests = beforeRequests;
        _messages = beforeMessages;
        _saveFailed = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
              if (_loading) const BatshLoading(size: 24),
              if (_loadFailed) BatshError(compact: true, onRetry: _load),
              if (_saveFailed)
                Text(
                  context.l10n.preferencesSaveFailed,
                  style: BatshTypography.bodySm.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (_saving)
                Semantics(
                  liveRegion: true,
                  child: Text(context.l10n.preferencesSaving),
                ),
              if (!_loadFailed && !_loading)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.notificationsRequests),
                  value: _requests,
                  onChanged: _loading || _saving
                      ? null
                      : (value) => _update(requests: value),
                ),
              if (!_loadFailed && !_loading)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.notificationsMessages),
                  value: _messages,
                  onChanged: _loading || _saving
                      ? null
                      : (value) => _update(messages: value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
