import 'package:flutter_test/flutter_test.dart';
import 'package:cently/utils/currency_format.dart';

void main() {
  group('CurrencyFormat Detailed Unit Tests', () {
    test('format and formatCompact handles various numeric magnitudes', () {
      expect(CurrencyFormat.format(0), '¥0.00');
      expect(CurrencyFormat.format(0, showSymbol: false), '0.00');
      expect(CurrencyFormat.format(0.5), '¥0.50');
      expect(CurrencyFormat.format(99.99), '¥99.99');
      expect(CurrencyFormat.format(1000), '¥1,000.00');
      expect(CurrencyFormat.format(1000000.75), '¥1,000,000.75');

      expect(CurrencyFormat.formatCompact(0), '¥0');
      expect(CurrencyFormat.formatCompact(0, showSymbol: false), '0');
      expect(CurrencyFormat.formatCompact(12.5), '¥12.5');
      expect(CurrencyFormat.formatCompact(12.0), '¥12');
      expect(CurrencyFormat.formatCompact(1234.56), '¥1,234.56');
    });

    test('formatRaw produces unformatted numeric strings without trailing zeros or commas', () {
      expect(CurrencyFormat.formatRaw(0.0), '0');
      expect(CurrencyFormat.formatRaw(5.0), '5');
      expect(CurrencyFormat.formatRaw(1250.0), '1250');
      expect(CurrencyFormat.formatRaw(1250.5), '1250.5');
      expect(CurrencyFormat.formatRaw(1250.50), '1250.5');
      expect(CurrencyFormat.formatRaw(1250.55), '1250.55');
      expect(CurrencyFormat.formatRaw(999999.99), '999999.99');
    });

    test('parseExpression handles single values, arithmetic, and edge cases', () {
      // 1. Basic parsing
      expect(CurrencyFormat.parseExpression('0'), 0.0);
      expect(CurrencyFormat.parseExpression(''), 0.0);
      expect(CurrencyFormat.parseExpression('   '), 0.0);
      expect(CurrencyFormat.parseExpression('128.5'), 128.5);
      expect(CurrencyFormat.parseExpression('1,280.50'), 1280.5);

      // 2. Arithmetic addition and subtraction
      expect(CurrencyFormat.parseExpression('10+20'), 30.0);
      expect(CurrencyFormat.parseExpression('100-35'), 65.0);
      expect(CurrencyFormat.parseExpression('10.5+20.25+5.25'), 36.0);
      expect(CurrencyFormat.parseExpression('100-20-30'), 50.0);

      // 3. Floating point precision (e.g. 0.1 + 0.2 == 0.3)
      expect(CurrencyFormat.parseExpression('0.1+0.2'), 0.3);
      expect(CurrencyFormat.parseExpression('0.7+0.1'), 0.8);

      // 4. Trailing operators and dots (graceful truncation)
      expect(CurrencyFormat.parseExpression('50+'), 50.0);
      expect(CurrencyFormat.parseExpression('50-'), 50.0);
      expect(CurrencyFormat.parseExpression('50.'), 50.0);
      expect(CurrencyFormat.parseExpression('50+-'), 50.0);

      // 5. Negative clamping (bookkeeping amounts >= 0)
      expect(CurrencyFormat.parseExpression('10-50'), 0.0);
      expect(CurrencyFormat.parseExpression('-50'), 0.0);
    });

    test('processKeyInput state machine transitions', () {
      // 1. Initial State: Typing a digit replaces initial amount
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '100', key: '5', isInitialState: true),
        '5',
      );

      // 2. Initial State: Typing dot resets to '0.'
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '100', key: '.', isInitialState: true),
        '0.',
      );

      // 3. Normal digits and leading zero prevention
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '0', key: '8'),
        '8',
      );
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '8', key: '0'),
        '80',
      );

      // 4. Decimal point handling
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '5', key: '.'),
        '5.',
      );
      // Duplicate dot is ignored
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '5.', key: '.'),
        '5.',
      );
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '5.2', key: '.'),
        '5.2',
      );
      // Max 2 decimal digits
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '5.25', key: '8'),
        '5.25',
      );

      // 5. Operator inputs
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '20', key: '+'),
        '20+',
      );
      // Operator replacement
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '20+', key: '-'),
        '20-',
      );
      // Chained intermediate calculation
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '20+30', key: '+'),
        '50+',
      );

      // 6. Backspace handling
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '123', key: '⌫'),
        '12',
      );
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '1', key: '⌫'),
        '0',
      );
      expect(
        CurrencyFormat.processKeyInput(currentExpression: '0', key: '⌫'),
        '0',
      );
    });

    test('hasPendingCalculation and escapeCsvField edge cases', () {
      expect(CurrencyFormat.hasPendingCalculation('100'), false);
      expect(CurrencyFormat.hasPendingCalculation('100+'), true);
      expect(CurrencyFormat.hasPendingCalculation('100+50'), true);
      expect(CurrencyFormat.hasPendingCalculation('-50'), false);
      expect(CurrencyFormat.hasPendingCalculation(''), false);

      expect(CurrencyFormat.escapeCsvField('normal'), '"normal"');
      expect(CurrencyFormat.escapeCsvField('has,comma'), '"has,comma"');
      expect(CurrencyFormat.escapeCsvField('has"quote"'), '"has""quote"""');
      expect(CurrencyFormat.escapeCsvField(''), '""');
      expect(CurrencyFormat.escapeCsvField(null), '""');
    });
  });
}
