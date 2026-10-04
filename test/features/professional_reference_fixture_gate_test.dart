import 'package:batsh/features/discovery/domain/professional_reference_fixture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reference media stays disabled without the development define',
    () {
      expect(professionalReferenceEnabled, isFalse);
      expect(
        ProfessionalReferenceFixture.isAllowedMediaPath(
          ProfessionalReferenceFixture.livingRoomImage,
        ),
        isFalse,
      );
      expect(
        ProfessionalReferenceFixture.isAllowedMediaPath(
          'assets/images/unapproved.png',
        ),
        isFalse,
      );
    },
    skip: professionalReferenceEnabled,
  );
}
