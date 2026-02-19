/// Formats a [value] as BRL currency (R$ 1.234,56).
String formatCurrency(double value) {
  final isNegative = value < 0;
  final absValue = value.abs();
  final intPart = absValue.truncate();
  final decPart =
      ((absValue - intPart) * 100).round().toString().padLeft(2, '0');

  // Format with thousands separator
  final intStr = intPart.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < intStr.length; i++) {
    if (i > 0 && (intStr.length - i) % 3 == 0) buffer.write('.');
    buffer.write(intStr[i]);
  }

  return '${isNegative ? '- ' : ''}R\$ $buffer,$decPart';
}
