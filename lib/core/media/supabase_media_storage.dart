import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/image_compression.dart';
import '../utils/upload_policy.dart';
import 'media_storage.dart';

class SupabaseMediaStorage implements MediaStorageService {
  SupabaseMediaStorage(this._client);

  final SupabaseClient _client;

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
    final isImage = contentType.startsWith('image/');
    final uploadBytes = isImage ? await ImageCompression.prepare(bytes) : bytes;
    final uploadContentType = isImage ? 'image/jpeg' : contentType;
    UploadPolicy.validateImageBytes(uploadBytes);
    final path = supabasePath ?? '$userId/$fileName';
    final storage = _client.storage.from(category.supabaseBucket);
    await storage.uploadBinary(
      path,
      uploadBytes,
      fileOptions: FileOptions(upsert: upsert, contentType: uploadContentType),
    );
    return MediaUploadResult(
      url: storage.getPublicUrl(path),
      provider: MediaProvider.supabase,
    );
  }

  @override
  Future<void> deletePublicReference(
    String url, {
    required MediaCategory category,
  }) async {
    final path = _storagePathFromUrl(url, category.supabaseBucket);
    if (path == null) return;
    await _client.storage.from(category.supabaseBucket).remove([path]);
  }

  @override
  Future<void> purgeOwnedPublicMedia() async {
    // The existing delete_my_account RPC removes all Supabase objects under
    // the user's id. There is no second client-side cleanup query to add.
  }

  static String? _storagePathFromUrl(String rawUrl, String bucket) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return null;
    final segments = uri.pathSegments;
    final publicIndex = segments.indexOf('public');
    if (publicIndex == -1 || publicIndex + 2 >= segments.length) return null;
    if (segments[publicIndex + 1] != bucket) return null;
    final path = segments.sublist(publicIndex + 2).join('/');
    return path.isEmpty ? null : path;
  }
}
