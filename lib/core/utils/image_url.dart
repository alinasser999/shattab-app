import '../env/env.dart';

/// Rewrites a Supabase Storage public URL to request a server-resized image.
///
/// Why this exists: photos are uploaded at up to 1600px (PhotoPicker downscales
/// to `maxWidth: 1600, imageQuality: 85`) but are frequently displayed in a
/// 260px card or a 44px avatar. `memCacheWidth` only bounds the *decode* size —
/// the full bytes still cross the network. On Egyptian mobile data that is both
/// the slowest part of the app and the largest line on the egress bill.
///
/// Supabase serves transformed images from a different path:
/// - `/storage/v1/object/public/{bucket}/{path}` — original
/// - `/storage/v1/render/image/public/{bucket}/{path}?width=..&quality=..`
///
/// Returns [url] unchanged when:
///   - transforms are disabled (see [Env.imageTransformsEnabled]) — image
///     transformation is a paid Supabase feature, so this stays off until the
///     project is on a plan that supports it, otherwise every image 404s;
///   - the URL is not a Supabase Storage public object URL. This matters:
///     Google OAuth avatars are hosted on googleusercontent.com and rewriting
///     them would break them.
String sizedImageUrl(String url, {required int width, int quality = 75}) {
  if (!Env.imageTransformsEnabled) return url;

  const marker = '/storage/v1/object/public/';
  if (!url.contains(marker)) return url;

  // Already carrying a query string — leave it alone rather than emitting a URL
  // with two of them.
  if (url.contains('?')) return url;

  return '${url.replaceFirst(marker, '/storage/v1/render/image/public/')}'
      '?width=$width&quality=$quality';
}

bool isDisplayableImageUrl(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return false;
  final uri = Uri.tryParse(raw);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}
