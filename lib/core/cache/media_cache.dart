import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// On-disk store for the app's photography.
///
/// `CachedNetworkImage` otherwise falls back to `DefaultCacheManager`, which
/// keeps **200 objects for 30 days**. Two hundred is a session, not a cache, on
/// a marketplace built out of photographs: a cover, a logo and a dozen
/// portfolio shots per professional means browsing forty of them evicts the
/// first ones before the homeowner has finished comparing — and every eviction
/// is a fresh download on Egyptian mobile data, the slowest and most expensive
/// part of this app.
///
/// A wider budget with a shorter life is the better trade here. Covers and
/// portfolio photos do change — a contractor re-uploads, a project is replaced
/// — and thirty days of a stale cover is a worse failure than one extra fetch.
///
/// This is the *download* cache. It cannot fix a 1600px upload being fetched at
/// 1600px for a 68px tile; that is what `core/utils/image_url.dart` is for, and
/// it stays inert until Supabase image transforms are enabled on the plan.
final CacheManager mediaCacheManager = CacheManager(
  Config(
    'shattab_media',
    maxNrOfCacheObjects: 800,
    stalePeriod: const Duration(days: 14),
  ),
);
