import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/image_compression.dart';
import '../utils/upload_policy.dart';
import 'media_storage.dart';

/// Flutter-side client for the server-only R2 signing boundary.
///
/// R2 credentials never appear here. The Worker authenticates the current
/// Supabase access token, returns a short-lived PUT URL, and returns the
/// stable public URL that is stored in the existing database fields.
class CloudflareR2MediaStorage {
  CloudflareR2MediaStorage({
    required SupabaseClient supabase,
    required http.Client httpClient,
    required String signerUrl,
    required String publicBaseUrl,
    required Set<MediaCategory> enabledCategories,
    required bool uploadsEnabled,
  }) : _supabase = supabase,
       _http = httpClient,
       _signerUrl = signerUrl.replaceFirst(RegExp(r'/+$'), ''),
       _publicBaseUrl = publicBaseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _enabledCategories = enabledCategories,
       _uploadsEnabled = uploadsEnabled;

  final SupabaseClient _supabase;
  final http.Client _http;
  final String _signerUrl;
  final String _publicBaseUrl;
  final Set<MediaCategory> _enabledCategories;
  final bool _uploadsEnabled;

  /// Whether the R2 boundary is *reachable* — signer and public host are
  /// configured — regardless of the rollout flag.
  ///
  /// Deliberately independent of [canUpload]. Turning the rollout off must not
  /// strand media already in the bucket: if this went false with the flag,
  /// [ownsUrl] would stop recognising every stored R2 URL, deletes would route
  /// to Supabase where the object does not exist, and account deletion would
  /// silently leave the user's photos public forever.
  bool get isEnabled => _signerUrl.isNotEmpty && _publicBaseUrl.isNotEmpty;

  /// Whether *new* uploads should go to R2. This is the rollout switch.
  bool get canUpload =>
      isEnabled && _uploadsEnabled && _enabledCategories.isNotEmpty;

  bool supports(MediaCategory category) =>
      _enabledCategories.contains(category);

  bool ownsUrl(String rawUrl) {
    final base = Uri.tryParse(_publicBaseUrl);
    final value = Uri.tryParse(rawUrl);
    if (base == null || value == null) return false;
    final basePath = _basePath(base.path);
    final valuePath = _basePath(value.path);
    return base.scheme == value.scheme &&
        base.host == value.host &&
        base.port == value.port &&
        (valuePath == basePath || valuePath.startsWith('$basePath/'));
  }

  Future<MediaUploadResult> uploadPublic({
    required MediaCategory category,
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    bool upsert = true,
  }) async {
    if (!canUpload || !supports(category)) {
      throw const MediaStorageException('r2_category_disabled');
    }
    final isImage = contentType.startsWith('image/');
    final uploadBytes = isImage ? await ImageCompression.prepare(bytes) : bytes;
    final uploadContentType = isImage ? 'image/jpeg' : contentType;
    UploadPolicy.validateImageBytes(uploadBytes);
    if (userId.trim().isEmpty) {
      throw const MediaStorageException('missing_user_id');
    }

    final response = await _post(
      '/v1/media/upload-url',
      body: {
        'category': category.wireName,
        'file_name': fileName,
        'content_type': uploadContentType,
        'content_length': uploadBytes.length,
        'upsert': upsert,
      },
    );
    final uploadUrl = response['upload_url'] as String?;
    final publicUrl = response['public_url'] as String?;
    final objectKey = response['object_key'] as String?;
    if (uploadUrl == null || publicUrl == null || objectKey == null) {
      throw const MediaStorageException('r2_invalid_upload_response');
    }

    final signedHeaders =
        (response['headers'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ) ??
        <String, String>{};

    // The signer now signs content-length, so a mismatch here would surface as
    // an opaque SignatureDoesNotMatch from R2. Fail early with a name that says
    // what actually went wrong.
    int? signedLength;
    for (final entry in signedHeaders.entries) {
      if (entry.key.toLowerCase() == 'content-length') {
        signedLength = int.tryParse(entry.value);
      }
    }
    if (signedLength != null && signedLength != uploadBytes.length) {
      throw const MediaStorageException('r2_content_length_mismatch');
    }

    final uploadHeaders = <String, String>{
      'Content-Type': uploadContentType,
      // Content-Length is omitted deliberately: package:http derives it from
      // the body, and setting it by hand risks a duplicate or conflicting
      // header on the very value the signature covers.
      for (final entry in signedHeaders.entries)
        if (entry.key.toLowerCase() != 'content-length') entry.key: entry.value,
    };

    late final http.Response uploadResponse;
    try {
      uploadResponse = await _http
          .put(Uri.parse(uploadUrl), headers: uploadHeaders, body: uploadBytes)
          .timeout(const Duration(seconds: 45));
    } catch (error) {
      throw MediaStorageException('r2_upload_unreachable', cause: error);
    }
    if (uploadResponse.statusCode < 200 || uploadResponse.statusCode >= 300) {
      throw MediaStorageException(
        'r2_upload_failed',
        message: 'HTTP ${uploadResponse.statusCode}',
      );
    }
    try {
      final finalized = await _post(
        '/v1/media/finalize',
        body: {'object_key': objectKey, 'content_type': uploadContentType},
      );
      final finalizedUrl = finalized['public_url'] as String?;
      if (finalizedUrl == null) {
        throw const MediaStorageException('r2_invalid_finalize_response');
      }
      return MediaUploadResult(
        url: finalizedUrl,
        objectKey: objectKey,
        provider: MediaProvider.cloudflareR2,
      );
    } catch (error) {
      // Best-effort cleanup prevents an invalid or partially finalized object
      // from becoming an orphan in the public bucket.
      try {
        await _post('/v1/media/delete', body: {'public_url': publicUrl});
      } catch (_) {
        // The original error is more useful to the caller.
      }
      rethrow;
    }
  }

  Future<void> deletePublicReference(String url) async {
    if (!ownsUrl(url)) return;
    await _post('/v1/media/delete', body: {'public_url': url});
  }

  Future<void> purgeOwnedPublicMedia() async {
    if (!isEnabled) return;
    await _post('/v1/media/purge-user', body: const {});
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw const MediaStorageException('not_authenticated');
    }
    late final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse('$_signerUrl$path'),
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (error) {
      throw MediaStorageUnavailableException(
        'r2_signer_unreachable',
        cause: error,
      );
    }
    if (response.statusCode >= 500) {
      throw MediaStorageUnavailableException(
        'r2_signer_unavailable',
        message: 'HTTP ${response.statusCode}',
      );
    }
    Map<String, dynamic> decoded;
    try {
      decoded = (jsonDecode(response.body) as Map).cast<String, dynamic>();
    } catch (error) {
      throw MediaStorageException('r2_invalid_signer_response', cause: error);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MediaStorageException(
        (decoded['code'] as String?) ?? 'r2_signer_rejected',
        message: decoded['message'] as String?,
      );
    }
    return decoded;
  }

  static String _basePath(String path) =>
      path == '/' ? '' : path.replaceFirst(RegExp(r'/+$'), '');
}
