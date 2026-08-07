import 'dart:typed_data';

import 'package:batsh/core/utils/upload_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts a non-empty image payload within the limit', () {
    expect(
      () => UploadPolicy.validateImageBytes(Uint8List(128)),
      returnsNormally,
    );
  });

  test('rejects empty image payloads', () {
    expect(
      () => UploadPolicy.validateImageBytes(Uint8List(0)),
      throwsA(
        isA<UploadPolicyException>().having(
          (error) => error.code,
          'code',
          'empty_image',
        ),
      ),
    );
  });

  test('rejects image payloads larger than the shared limit', () {
    expect(
      () => UploadPolicy.validateImageLength(UploadPolicy.maxImageBytes + 1),
      throwsA(
        isA<UploadPolicyException>().having(
          (error) => error.code,
          'code',
          'image_too_large',
        ),
      ),
    );
  });
}
