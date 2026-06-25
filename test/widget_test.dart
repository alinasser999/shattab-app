import 'package:batsh/core/theme/batsh_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Theme colors expose terracotta primary', () {
    expect(BatshColors.primary.toARGB32(), 0xFF9E3D18);
    expect(BatshColors.background.toARGB32(), 0xFFFFF8F3);
  });
}
