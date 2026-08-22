import '../logging/app_logger.dart';
import '../supabase/supabase_client.dart';

/// Privacy-safe funnel events. Properties must be non-identifying and should
/// describe an action, not copy or contact details.
class AppAnalytics {
  AppAnalytics._();

  static final _eventNamePattern = RegExp(r'^[a-z0-9_]{1,80}$');
  static final _sensitiveKeyPattern = RegExp(
    r'(?:^|_)(?:id|name|phone|email|city|district|address|description|text|note|url|token|contact|latitude|longitude|location)(?:$|_)',
    caseSensitive: false,
  );

  /// Sanitizes telemetry at the boundary so feature code cannot accidentally
  /// send contact details, raw copy, or stable record identifiers.
  static Map<String, Object?> sanitizeProperties(
    Map<String, Object?> properties,
  ) {
    final sanitized = <String, Object?>{};
    for (final entry in properties.entries.take(20)) {
      final key = entry.key.trim().toLowerCase();
      if (key.isEmpty || _sensitiveKeyPattern.hasMatch(key)) continue;

      final value = entry.value;
      if (value is String) {
        if (value.length > 80 || value.contains('\n')) continue;
        sanitized[key] = value;
      } else if (value is num || value is bool || value == null) {
        sanitized[key] = value;
      }
    }
    return sanitized;
  }

  static Future<void> track(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    final normalizedEventName = eventName.trim().toLowerCase();
    if (!_eventNamePattern.hasMatch(normalizedEventName)) return;

    try {
      final client = SupabaseInit.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('analytics_events').insert({
        'user_id': userId,
        'event_name': normalizedEventName,
        'properties': sanitizeProperties(properties),
      });
    } catch (error, stackTrace) {
      // Analytics must never block a quote, contact handoff, or completion.
      AppLogger.warning(
        'analytics event dropped',
        error: error,
        stackTrace: stackTrace,
        context: {'event': normalizedEventName},
      );
    }
  }
}
