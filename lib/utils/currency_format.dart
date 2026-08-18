import 'package:intl/intl.dart';

class CurrencyFormat {
  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compactFormatter = NumberFormat('#,##0.##', 'en_US');

  static String format(double amount, {bool showSymbol = true}) {
    final formatted = _formatter.format(amount);
    return showSymbol ? '¥$formatted' : formatted;
  }

  static String formatCompact(double amount, {bool showSymbol = true}) {
    final formatted = _compactFormatter.format(amount);
    return showSymbol ? '¥$formatted' : formatted;
  }

  /// Format amount without thousand separators for calculators and text inputs (e.g. 1000, 1250.5, 1250.55)
  static String formatRaw(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    String str = amount.toStringAsFixed(2);
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return str;
  }

  /// Safely parse arithmetic expressions (+, -, decimals, with comma stripping)
  static double parseExpression(String input) {
    try {
      String clean = input.replaceAll(',', '').trim();
      if (clean.isEmpty) return 0.0;

      while (clean.endsWith('+') || clean.endsWith('-') || clean.endsWith('.')) {
        clean = clean.substring(0, clean.length - 1).trim();
      }
      if (clean.isEmpty) return 0.0;

      double total = 0.0;
      String currentNum = '';
      String currentOp = '+';

      for (int i = 0; i < clean.length; i++) {
        final char = clean[i];
        if (char == '+' || (char == '-' && i > 0 && clean[i - 1] != '+' && clean[i - 1] != '-')) {
          if (currentNum.isNotEmpty) {
            final val = double.tryParse(currentNum) ?? 0.0;
            total = (currentOp == '+') ? (total + val) : (total - val);
            currentNum = '';
          }
          currentOp = char;
        } else {
          currentNum += char;
        }
      }
      if (currentNum.isNotEmpty) {
        final val = double.tryParse(currentNum) ?? 0.0;
        total = (currentOp == '+') ? (total + val) : (total - val);
      }
      return total < 0 ? 0.0 : total;
    } catch (_) {
      return 0.0;
    }
  }
}

