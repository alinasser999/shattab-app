import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to environment variables loaded from `.env`.
/// Call [Env.load] before runApp.
class Env {
  const Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  /// Reads a boolean feature flag, treating "not loaded yet" as off.
  ///
  /// [_required] throws on a missing value and should: the app cannot run
  /// without Supabase credentials, and failing loudly at boot beats failing
  /// obscurely later. A flag is the opposite case. `sizedImageUrl` is now
  /// consulted inside a widget build, so every widget test — none of which
  /// call [load] — reached dotenv before initialisation and had a
  /// `NotInitializedError` thrown up through the widget tree. An unset `.env`
  /// means the feature is off, which is exactly what it should mean.
  static bool _flag(String key) {
    if (!dotenv.isInitialized) return false;
    return dotenv.env[key]?.toLowerCase() == 'true';
  }

  static String _required(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required env var "$key". Copy .env.example to .env and fill it in.',
      );
    }
    return value;
  }

  static String get supabaseUrl => _required('SUPABASE_URL');
  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');

  /// Local-only debug authentication is opt-in and never available in release
  /// builds. Credentials live in the ignored `.env`, not in source control.
  static bool get debugAuthEnabled => _flag('DEBUG_AUTH_ENABLED');

  static String? get debugAuthEmail => _optional('DEBUG_AUTH_EMAIL');

  static String? get debugAuthPassword => _optional('DEBUG_AUTH_PASSWORD');

  /// Sentry DSN. Deliberately optional, not [_required]: a missing DSN disables
  /// crash reporting rather than refusing to boot. Contributors without one, and
  /// the test suite, must still be able to run the app.
  static String? get sentryDsn {
    final value = dotenv.env['SENTRY_DSN'];
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Whether to request server-resized images from Supabase Storage.
  ///
  /// Off by default because image transformation is a paid Supabase feature:
  /// enabling it on a plan that lacks it makes every photo 404. Flip to true in
  /// `.env` once the project is upgraded. See `core/utils/image_url.dart`.
  static bool get imageTransformsEnabled => _flag('SUPABASE_IMAGE_TRANSFORMS');

  /// R2 is opt-in. A missing signer or public hostname keeps the app on the
  /// existing Supabase Storage path instead of producing a broken upload.
  static bool get r2PublicMediaEnabled => _flag('R2_PUBLIC_MEDIA_ENABLED');

  static String? get r2SignerUrl => _optional('R2_SIGNER_URL');

  static String? get r2PublicBaseUrl => _optional('R2_PUBLIC_BASE_URL');

  static Set<String> get r2PublicMediaCategories => {
    for (final category
        in (dotenv.env['R2_PUBLIC_MEDIA_CATEGORIES'] ?? '').split(','))
      if (category.trim().isNotEmpty) category.trim(),
  };

  static String? _optional(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
