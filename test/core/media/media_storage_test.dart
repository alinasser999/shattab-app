import 'package:flutter_test/flutter_test.dart';

import 'package:batsh/core/media/media_storage.dart';

void main() {
  test('only reviewed public categories can opt into R2', () {
    expect(MediaCategory.avatar.canUsePublicR2, isTrue);
    expect(MediaCategory.contractorLogo.canUsePublicR2, isTrue);
    expect(MediaCategory.postMedia.canUsePublicR2, isTrue);
    expect(MediaCategory.portfolioPhoto.canUsePublicR2, isTrue);
    expect(MediaCategory.briefPhoto.canUsePublicR2, isFalse);
    expect(MediaCategory.verificationDocument.canUsePublicR2, isFalse);
    expect(MediaCategory.paymentProof.canUsePublicR2, isFalse);
  });

  test('wire names preserve the existing Supabase bucket contract', () {
    expect(MediaCategory.postMedia.wireName, 'post-media');
    expect(MediaCategory.verificationDocument.supabaseBucket, 'verification-docs');
    expect(MediaCategory.paymentProof.supabaseBucket, 'payment-proofs');
  });
}
