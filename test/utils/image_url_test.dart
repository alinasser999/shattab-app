import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/core/utils/image_url.dart';

/// `sizedImageUrl` reads Env.imageTransformsEnabled, which reads dotenv, so the
/// tests drive the flag by populating dotenv directly rather than loading a file.
/// `loadFromString` is the in-memory entry point in flutter_dotenv 6 (the older
/// `testLoad` was removed).
void _setTransforms({required bool enabled}) {
  dotenv.loadFromString(
    envString: 'SUPABASE_IMAGE_TRANSFORMS=${enabled ? 'true' : 'false'}',
  );
}

const _supabaseUrl =
    'https://ajqdutehxpbbflzdovhw.supabase.co/storage/v1/object/public/post-media/u1/a.jpg';

void main() {
  group('sizedImageUrl', () {
    test('rewrites a Supabase public object URL to the render endpoint', () {
      _setTransforms(enabled: true);

      expect(
        sizedImageUrl(_supabaseUrl, width: 800),
        'https://ajqdutehxpbbflzdovhw.supabase.co/storage/v1/render/image/public/'
        'post-media/u1/a.jpg?width=800&quality=75',
      );
    });

    test('honours a custom quality', () {
      _setTransforms(enabled: true);

      expect(sizedImageUrl(_supabaseUrl, width: 200, quality: 50),
          endsWith('?width=200&quality=50'));
    });

    test('returns the URL untouched when transforms are disabled', () {
      // Image transformation is a paid Supabase feature. Rewriting while the
      // project is on a plan without it would 404 every photo in the app.
      _setTransforms(enabled: false);

      expect(sizedImageUrl(_supabaseUrl, width: 800), _supabaseUrl);
    });

    test('leaves non-Supabase hosts alone', () {
      // Google OAuth avatars live on googleusercontent.com. Rewriting them
      // would point at a Supabase path that does not exist.
      _setTransforms(enabled: true);
      const google = 'https://lh3.googleusercontent.com/a/ACg8ocK=s96-c';

      expect(sizedImageUrl(google, width: 96), google);
    });

    test('leaves a URL that already carries a query string alone', () {
      _setTransforms(enabled: true);
      const signed = '$_supabaseUrl?token=abc';

      expect(sizedImageUrl(signed, width: 800), signed);
    });
  });
}
