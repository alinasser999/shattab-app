import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small, local-only persistence for interruption-safe form drafts.
///
/// Drafts deliberately contain text and selections only. Local photo bytes
/// are not copied into preferences; the picker remains responsible for media.
class FormDraftStore {
  const FormDraftStore._();

  static const _prefix = 'shattab_form_draft_v1:';

  static Future<Map<String, dynamic>?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } on Object {
      await prefs.remove('$_prefix$key');
      return null;
    }
  }

  static Future<void> write(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(value));
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }
}
