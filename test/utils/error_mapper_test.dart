import 'package:batsh/core/l10n/strings.dart';
import 'package:batsh/core/utils/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMapper.map', () {
    test('maps auth errors to S.errAuthFailed', () {
      expect(ErrorMapper.map('invalid login credentials'), S.errAuthFailed);
      expect(ErrorMapper.map('Invalid Credentials'), S.errAuthFailed);
      expect(ErrorMapper.map('Email not confirmed'), S.errAuthFailed);
    });

    test('does not infer an OTP outcome without operation context', () {
      expect(ErrorMapper.map('OTP token expired'), S.errServerError);
      expect(ErrorMapper.map('OTP error occurred'), S.errServerError);
      expect(ErrorMapper.map('sms sending failed'), S.errServerError);
      expect(ErrorMapper.map('invalid token'), S.errInvalidData);
    });

    test('maps session errors to S.errSessionExpired', () {
      expect(ErrorMapper.map('session not found'), S.errSessionExpired);
    });

    test('maps network/timeout errors to S.errNetwork', () {
      expect(ErrorMapper.map('Network request failed'), S.errNetwork);
      expect(ErrorMapper.map('timeout exceeded'), S.errNetwork);
      expect(ErrorMapper.map('Connection refused'), S.errNetwork);
      expect(ErrorMapper.map('socket exception'), S.errNetwork);
      expect(ErrorMapper.map('dns lookup failed'), S.errNetwork);
    });

    test('maps permission errors to S.errPermissionDenied', () {
      expect(ErrorMapper.map('permission denied'), S.errPermissionDenied);
      expect(ErrorMapper.map('unauthorized access'), S.errPermissionDenied);
      expect(ErrorMapper.map('policy violation'), S.errPermissionDenied);
      expect(ErrorMapper.map('row level security'), S.errPermissionDenied);
    });

    test('maps not-found errors to S.errNotFound', () {
      expect(ErrorMapper.map('relation not found'), S.errNotFound);
      expect(ErrorMapper.map('does not exist'), S.errNotFound);
    });

    test('maps data/parse errors to S.errInvalidData', () {
      expect(ErrorMapper.map('invalid input'), S.errInvalidData);
      expect(ErrorMapper.map('constraint violation'), S.errInvalidData);
      expect(ErrorMapper.map('format error'), S.errInvalidData);
      expect(ErrorMapper.map('parse failure'), S.errInvalidData);
      expect(ErrorMapper.map('type mismatch'), S.errInvalidData);
    });

    test('maps upload/storage errors to S.errPhotoUpload', () {
      expect(ErrorMapper.map('upload failed'), S.errPhotoUpload);
      expect(ErrorMapper.map('storage quota exceeded'), S.errPhotoUpload);
    });

    test('returns S.errServerError for unknown errors', () {
      expect(
        ErrorMapper.map('something completely unexpected'),
        S.errServerError,
      );
      expect(ErrorMapper.map(''), S.errServerError);
      expect(ErrorMapper.map(Object()), S.errServerError);
    });
  });

  group('ErrorMapper.mapOtp', () {
    test(
      'keeps send and resend failures generic unless they are network errors',
      () {
        for (final operation in [OtpOperation.send, OtpOperation.resend]) {
          expect(
            ErrorMapper.mapOtp('sms_send_failed', operation: operation),
            S.unknownErrorRetry,
          );
          expect(
            ErrorMapper.mapOtp('SMS delivery failed', operation: operation),
            S.unknownErrorRetry,
          );
          expect(
            ErrorMapper.mapOtp('invalid token', operation: operation),
            S.unknownErrorRetry,
          );
          expect(
            ErrorMapper.mapOtp('network timeout', operation: operation),
            S.errNetwork,
          );
        }
      },
    );

    test('uses code-specific copy only for explicit verify outcomes', () {
      expect(
        ErrorMapper.mapOtp('Invalid token', operation: OtpOperation.verify),
        S.errOtpFailed,
      );
      expect(
        ErrorMapper.mapOtp('token is invalid', operation: OtpOperation.verify),
        S.errOtpFailed,
      );
      expect(
        ErrorMapper.mapOtp('invalid_token', operation: OtpOperation.verify),
        S.errOtpFailed,
      );
      expect(
        ErrorMapper.mapOtp(
          'Token has expired or is invalid',
          operation: OtpOperation.verify,
        ),
        S.errOtpExpired,
      );
      expect(
        ErrorMapper.mapOtp('token', operation: OtpOperation.verify),
        S.unknownErrorRetry,
      );
      expect(
        ErrorMapper.mapOtp('invalid code', operation: OtpOperation.verify),
        S.errOtpFailed,
      );
    });
  });
}
