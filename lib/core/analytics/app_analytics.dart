import '../logging/app_logger.dart';
import '../supabase/supabase_client.dart';

/// Privacy-safe funnel events. Properties must be non-identifying and should
/// describe an action, not copy or contact details.
class AppAnalytics {
  AppAnalytics._();

  static Future<void> track(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    try {
      final client = SupabaseInit.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client.from('analytics_events').insert({
        'user_id': userId,
        'event_name': eventName,
        'properties': properties,
      });
    } catch (error, stackTrace) {
      // Analytics must never block a quote, contact handoff, or completion.
      AppLogger.warning(
        'analytics event dropped',
        error: error,
        stackTrace: stackTrace,
        context: {'event': eventName},
      );
    }
  }
}
