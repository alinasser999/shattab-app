import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../env/env.dart';
import '../supabase/supabase_provider.dart';
import 'media_storage.dart';
import 'r2_media_storage.dart';
import 'supabase_media_storage.dart';

final mediaStorageProvider = Provider<MediaStorageService>((ref) {
  final supabase = SupabaseMediaStorage(ref.watch(supabaseClientProvider));
  final httpClient = http.Client();
  ref.onDispose(httpClient.close);

  final signerUrl = Env.r2SignerUrl;
  final publicBaseUrl = Env.r2PublicBaseUrl;
  final enabledCategories = _parseCategories(Env.r2PublicMediaCategories);
  final r2 = CloudflareR2MediaStorage(
    supabase: ref.watch(supabaseClientProvider),
    httpClient: httpClient,
    signerUrl: Env.r2PublicMediaEnabled ? (signerUrl ?? '') : '',
    publicBaseUrl: Env.r2PublicMediaEnabled ? (publicBaseUrl ?? '') : '',
    enabledCategories: enabledCategories,
  );

  return _MediaStorageRouter(supabase: supabase, r2: r2);
});

Set<MediaCategory> _parseCategories(Set<String> names) => {
  for (final category in MediaCategory.values)
    if (category.canUsePublicR2 && names.contains(category.wireName)) category,
};

class _MediaStorageRouter implements MediaStorageService {
  _MediaStorageRouter({required this.supabase, required this.r2});

  final SupabaseMediaStorage supabase;
  final CloudflareR2MediaStorage r2;

  @override
  Future<MediaUploadResult> uploadPublic({
    required MediaCategory category,
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String? supabasePath,
    bool upsert = true,
  }) async {
    if (r2.isEnabled && r2.supports(category)) {
      try {
        return await r2.uploadPublic(
          category: category,
          userId: userId,
          bytes: bytes,
          fileName: fileName,
          contentType: contentType,
          upsert: upsert,
        );
      } on MediaStorageUnavailableException {
        // The R2 boundary was unavailable before an upload URL was issued.
        // Keep the existing Supabase path usable during a rollout incident.
      }
    }
    return supabase.uploadPublic(
      category: category,
      userId: userId,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      supabasePath: supabasePath,
      upsert: upsert,
    );
  }

  @override
  Future<void> deletePublicReference(
    String url, {
    required MediaCategory category,
  }) async {
    if (r2.ownsUrl(url)) {
      await r2.deletePublicReference(url);
      return;
    }
    await supabase.deletePublicReference(url, category: category);
  }

  @override
  Future<void> purgeOwnedPublicMedia() async {
    await r2.purgeOwnedPublicMedia();
  }
}
