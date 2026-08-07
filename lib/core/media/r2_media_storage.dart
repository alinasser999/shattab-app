import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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
  }) : _supabase = supabase,
       _http = httpClient,
       _signerUrl = signerUrl.replaceFirst(RegExp(r'/+$'), ''),
       _publicBaseUrl = publicBaseUrl.replaceFirst(RegExp(r'/+$'), ''),
       _enabledCategories = enabledCategories;

  final SupabaseClient _supabase;
  final http.Client _http;
  final String _signerUrl;
  final String _publicBaseUrl;
  final Set<MediaCategory> _enabledCategories;

  bool get isEnabled =>
      _signerUrl.isNotEmpty &&
      _publicBaseUrl.isNotEmpty &&
      _enabledCategories.isNotEmpty;

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
    if (!isEnabled || !supports(category)) {
      throw const MediaStorageException('r2_category_disabled');
    }
    UploadPolicy.validateImageBytes(bytes);
    if (userId.trim().isEmpty) {
      throw const MediaStorageException('missing_user_id');
    }

    final response = await _post(
      '/v1/media/upload-url',
      body: {
        'category': category.wireName,
        'file_name': fileName,
        'content_type': contentType,
        'content_length': bytes.length,
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
    final uploadHeaders = <String, String>{
      'Content-Type': contentType,
      ...signedHeaders,
    };

    late final http.Response uploadResponse;
    try {
      uploadResponse = await _http
          .put(Uri.parse(uploadUrl), headers: uploadHeaders, body: bytes)
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
        body: {'object_key': objectKey, 'content_type': contentType},
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
