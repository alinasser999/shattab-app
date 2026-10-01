import 'package:flutter/services.dart';

/// Converts Arabic-Indic and Persian digits to their ASCII equivalents.
String normalizeLocalizedDigits(String value) {
  const asciiDigits = '0123456789';
  final result = StringBuffer();
  for (final rune in value.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      result.write(asciiDigits[rune - 0x0660]);
    } else if (rune >= 0x06f0 && rune <= 0x06f9) {
      result.write(asciiDigits[rune - 0x06f0]);
    } else {
      result.writeCharCode(rune);
    }
  }
  return result.toString();
}

/// Returns only ASCII digits after normalizing localized numeral input.
String asciiDigitsOnly(String value) =>
    normalizeLocalizedDigits(value).replaceAll(RegExp(r'[^0-9]'), '');

/// Normalizes an Egyptian phone number to E.164 (`+20xxxxxxxxxx`).
String normalizeEgyptPhone(String raw) {
  var digits = asciiDigitsOnly(raw);
  if (digits.startsWith('0020')) digits = digits.substring(4);
  if (digits.startsWith('20')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return '+20$digits';
}

/// Keeps phone/OTP fields numeric while accepting Arabic and Persian keyboards.
class LocalizedDigitsOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = asciiDigitsOnly(newValue.text);
    if (normalized == newValue.text) return newValue;

    int offsetFor(int offset) {
      if (offset < 0) return -1;
      final safeOffset = offset > newValue.text.length
          ? newValue.text.length
          : offset;
      return asciiDigitsOnly(newValue.text.substring(0, safeOffset)).length;
    }

    return TextEditingValue(
      text: normalized,
      selection: TextSelection(
        baseOffset: offsetFor(newValue.selection.baseOffset),
        extentOffset: offsetFor(newValue.selection.extentOffset),
        affinity: newValue.selection.affinity,
        isDirectional: newValue.selection.isDirectional,
      ),
      composing: TextRange.empty,
    );
  }
}
