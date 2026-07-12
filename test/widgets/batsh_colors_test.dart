import 'package:batsh/core/theme/batsh_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BatshColors', () {
    test('primary is terracotta 0xFF9E3D18', () {
      expect(BatshColors.primary.toARGB32(), 0xFF9E3D18);
    });

    test('surface / background is warm cream 0xFFFFF8F3', () {
      expect(BatshColors.surface.toARGB32(), 0xFFFFF8F3);
      expect(BatshColors.background.toARGB32(), 0xFFFFF8F3);
    });

    test('onPrimary is white', () {
      expect(BatshColors.onPrimary.toARGB32(), 0xFFFFFFFF);
    });

    test('whatsApp is brand green', () {
      expect(BatshColors.whatsApp.toARGB32(), 0xFF25D366);
    });

    test('scheme returns a valid ColorScheme with correct primary', () {
      final scheme = BatshColors.scheme;
      expect(scheme.primary.toARGB32(), 0xFF9E3D18);
      expect(scheme.surface.toARGB32(), 0xFFFFF8F3);
    });
  });
}
