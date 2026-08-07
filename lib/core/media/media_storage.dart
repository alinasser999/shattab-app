import 'dart:typed_data';

/// Storage categories are deliberately explicit so a private document cannot
/// be moved to public media by accident.
enum MediaCategory {
  avatar,
  contractorLogo,
  postMedia,
  portfolioPhoto,
  briefPhoto,
  verificationDocument,
  paymentProof,
}

extension MediaCategoryWire on MediaCategory {
  String get wireName => switch (this) {
        MediaCategory.avatar => 'avatars',
        MediaCategory.contractorLogo => 'contractor-logos',
        MediaCategory.postMedia => 'post-media',
        MediaCategory.portfolioPhoto => 'portfolio-photos',
        MediaCategory.briefPhoto => 'brief-photos',
        MediaCategory.verificationDocument => 'verification-docs',
        MediaCategory.paymentProof => 'payment-proofs',
      };

  String get supabaseBucket => wireName;

  bool get canUsePublicR2 => switch (this) {
        MediaCategory.avatar ||
        MediaCategory.contractorLogo ||
        MediaCategory.postMedia ||
        MediaCategory.portfolioPhoto => true,
        MediaCategory.briefPhoto ||
        MediaCategory.verificationDocument ||
        MediaCategory.paymentProof => false,
      };
}

enum MediaProvider {
  supabase,
  cloudflareR2,
}

class MediaUploadResult {
  const MediaUploadResult({
    required this.url,
    required this.provider,
    this.objectKey,
  });

  final String url;
  final MediaProvider provider;
  final String? objectKey;
}

abstract interface class MediaStorageService {
  /// Uploads a media item that is already approved for public display.
  Future<MediaUploadResult> uploadPublic({
    required MediaCategory category,
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String? supabasePath,
    bool upsert = true,
  });

  /// Deletes a public reference when the current app workflow owns it.
  Future<void> deletePublicReference(
    String url, {
    required MediaCategory category,
  });

  /// Removes public R2 media owned by the current user before account
  /// deletion. Supabase-owned media is removed by the existing RPC.
  Future<void> purgeOwnedPublicMedia();
}

class MediaStorageException implements Exception {
  const MediaStorageException(this.code, {this.message, this.cause});

  final String code;
  final String? message;
  final Object? cause;

  @override
  String toString() =>
      'MediaStorageException($code${message == null ? '' : ': $message'})';
}

/// Indicates that the optional R2 boundary was not reachable before an
/// upload URL was issued. The router may safely use Supabase in this case.
class MediaStorageUnavailableException extends MediaStorageException {
  const MediaStorageUnavailableException(
    super.code, {
    super.message,
    super.cause,
  });
}
