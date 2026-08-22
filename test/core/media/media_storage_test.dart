import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:batsh/core/media/media_storage.dart';
import 'package:batsh/core/media/r2_media_storage.dart';

CloudflareR2MediaStorage buildR2({
  required bool uploadsEnabled,
  String signerUrl = 'https://signer.example.workers.dev',
  String publicBaseUrl = 'https://media.example.com',
}) => CloudflareR2MediaStorage(
  supabase: SupabaseClient('https://example.supabase.co', 'anon-key'),
  httpClient: http.Client(),
  signerUrl: signerUrl,
  publicBaseUrl: publicBaseUrl,
  enabledCategories: const {MediaCategory.avatar},
  uploadsEnabled: uploadsEnabled,
);

void main() {
  test('the public R2 allowlist matches the Worker allowlist exactly', () {
    // The Worker keeps the same literal list in
    // `infra/media-signer/test/validation.test.ts`. Two hand-synced copies is
    // the price of a Worker and a Flutter app not sharing a constant; pinning
    // both means drift fails a build instead of widening what is public.
    final public =
        MediaCategory.values
            .where((category) => category.canUsePublicR2)
            .map((category) => category.wireName)
            .toList()
          ..sort();
    expect(public, [
      'avatars',
      'contractor-logos',
      'portfolio-photos',
      'post-media',
    ]);
  });

  group('turning the rollout off must not strand media already in R2', () {
    test('uploads stop but the boundary stays reachable', () {
      final off = buildR2(uploadsEnabled: false);
      expect(off.canUpload, isFalse, reason: 'new uploads must go to Supabase');
      expect(
        off.isEnabled,
        isTrue,
        reason: 'delete and purge must still reach the signer',
      );
    });

    test('stored R2 URLs are still recognised as ours', () {
      const stored = 'https://media.example.com/public/avatars/u1/a.jpg';
      // The regression this guards: when the flag also blanked the public base
      // URL, ownsUrl returned false here, deletes were routed to Supabase where
      // the object does not exist, and account deletion left the photo public.
      expect(buildR2(uploadsEnabled: false).ownsUrl(stored), isTrue);
      expect(buildR2(uploadsEnabled: true).ownsUrl(stored), isTrue);
      expect(
        buildR2(uploadsEnabled: true).ownsUrl('https://evil.example/a.jpg'),
        isFalse,
      );
    });

    test('an unconfigured signer disables the boundary entirely', () {
      final unset = buildR2(
        uploadsEnabled: true,
        signerUrl: '',
        publicBaseUrl: '',
      );
      expect(unset.isEnabled, isFalse);
      expect(unset.canUpload, isFalse);
    });
  });

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
    expect(
      MediaCategory.verificationDocument.supabaseBucket,
      'verification-docs',
    );
    expect(MediaCategory.paymentProof.supabaseBucket, 'payment-proofs');
  });
}
