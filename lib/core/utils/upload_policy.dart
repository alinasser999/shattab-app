import 'dart:typed_data';

class UploadPolicy {
  const UploadPolicy._();

  static const maxImageBytes = 10 * 1024 * 1024;

  static void validateImageBytes(Uint8List bytes) {
    validateImageLength(bytes.length);
  }

  static void validateImageLength(int length) {
    if (length <= 0) throw const UploadPolicyException('empty_image');
    if (length > maxImageBytes) {
      throw const UploadPolicyException('image_too_large');
    }
  }
}

class UploadPolicyException implements Exception {
  const UploadPolicyException(this.code);
  final String code;

  @override
  String toString() => 'UploadPolicyException($code)';
}
