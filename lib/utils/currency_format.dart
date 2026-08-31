import 'package:intl/intl.dart';

class CurrencyFormat {
  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compactFormatter = NumberFormat('#,##0.##', 'en_US');
  static final RegExp _trailingZerosRegex = RegExp(r'0+$');
  static final RegExp _trailingDotRegex = RegExp(r'\.$');

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
      str = str.replaceAll(_trailingZerosRegex, '').replaceAll(_trailingDotRegex, '');
    }
    return str;
  }

  /// Checks if the expression has a binary operator and pending calculation
  static bool hasPendingCalculation(String text) {
    final clean = text.replaceAll(',', '').trim();
    if (clean.length < 2) return false;
    final body = clean.startsWith('-') ? clean.substring(1) : clean;
    return body.contains('+') || body.contains('-');
  }

  /// Safely parse arithmetic expressions (+, -, decimals, with comma stripping and 2-decimal precision rounding)
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
            total = (total * 100).round() / 100;
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
        total = (total * 100).round() / 100;
      }
      return total < 0 ? 0.0 : total;
    } catch (_) {
      return 0.0;
    }
  }

  /// Unified state machine for handling keypad / keyboard input on currency expressions
  static String processKeyInput({
    required String currentExpression,
    required String key,
    bool isInitialState = false,
  }) {
    String current = currentExpression.replaceAll(',', '');

    if (key == '⌫') {
      if (current.isNotEmpty) {
        current = current.substring(0, current.length - 1);
        if (current.isEmpty) {
          current = '0';
        }
      } else {
        current = '0';
      }
      return current;
    }

    if (key == '+' || key == '-') {
      if (current.endsWith('+') || current.endsWith('-')) {
        return current.substring(0, current.length - 1) + key;
      } else {
        if (hasPendingCalculation(current)) {
          final result = parseExpression(current);
          return '${formatRaw(result)}$key';
        } else {
          return current + key;
        }
      }
    }

    if (key == '.') {
      if (isInitialState) {
        return '0.';
      }
      final segments = current.split(RegExp(r'[+\-]'));
      final lastSegment = segments.isNotEmpty ? segments.last : '';
      if (!lastSegment.contains('.')) {
        if (lastSegment.isEmpty) {
          return '${current}0.';
        } else {
          return '$current.';
        }
      }
      return current;
    }

    // Number keys: '0'..'9'
    if (current == '0' || isInitialState) {
      return key;
    } else {
      final segments = current.split(RegExp(r'[+\-]'));
      final lastSegment = segments.isNotEmpty ? segments.last : '';
      if (lastSegment.contains('.')) {
        final decimals = lastSegment.split('.').last;
        if (decimals.length >= 2) {
          return current; // Max 2 decimal digits
        }
      }
      if (current.length < 16) {
        return current + key;
      }
      return current;
    }
  }

  /// Escapes CSV string cell containing quotes, commas, or newlines
  static String escapeCsvField(String? field) {
    if (field == null || field.isEmpty) return '""';
    final escaped = field.replaceAll('"', '""');
    return '"$escaped"';
  }
}

