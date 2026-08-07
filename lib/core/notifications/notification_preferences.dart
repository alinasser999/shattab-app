import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  const NotificationPreferences({
    required this.requests,
    required this.updates,
  });

  final bool requests;
  final bool updates;

  static const _requestsKey = 'shattab.notifications.requests';
  static const _updatesKey = 'shattab.notifications.updates';

  static Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      requests: prefs.getBool(_requestsKey) ?? true,
      updates: prefs.getBool(_updatesKey) ?? true,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_requestsKey, requests);
    await prefs.setBool(_updatesKey, updates);
  }
}
