import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'upload_policy.dart';

/// Normalizes user-selected photos before they reach object storage.
///
/// ImagePicker's quality and dimension hints are not consistent across web
/// browsers and native platforms. Keeping this boundary here means every
/// upload path gets the same predictable output and the original file is not
/// retained when the compressor succeeds.
class ImageCompression {
  const ImageCompression._();

  static const int defaultMaxDimension = 1600;
  static const int defaultQuality = 82;

  static Future<Uint8List> prepare(
    Uint8List source, {
    int maxDimension = defaultMaxDimension,
    int quality = defaultQuality,
  }) async {
    // Reject the original payload before handing it to a platform codec. This
    // keeps a malformed or oversized selection from consuming unnecessary
    // memory in every repository upload boundary.
    UploadPolicy.validateImageBytes(source);

    try {
      final encoded = await FlutterImageCompress.compressWithList(
        source,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: quality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (encoded.isEmpty) {
        return _safeOriginalOrThrow(source);
      }

      // Always keep the normalized JPEG. Upload callers use image/jpeg and a
      // .jpg object key, so returning the original PNG here would make the
      // stored bytes and content type disagree.
      final result = Uint8List.fromList(encoded);
      UploadPolicy.validateImageBytes(result);
      return result;
    } catch (_) {
      // A platform codec can reject a rare image format. Only keep the
      // original when it is already a JPEG; otherwise do not upload bytes
      // whose format disagrees with the promised image/jpeg content type.
      return _safeOriginalOrThrow(source);
    }
  }

  static Uint8List _safeOriginalOrThrow(Uint8List source) {
    if (!_looksLikeJpeg(source)) {
      throw const UploadPolicyException('image_compression_failed');
    }
    UploadPolicy.validateImageBytes(source);
    return source;
  }

  static bool _looksLikeJpeg(Uint8List bytes) =>
      bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;
}
