import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/core/money/money.dart';

void main() {
  group('Money.format', () {
    test('formatea con símbolo y miles', () {
      expect(const Money(123450).format(), 'S/ 1,234.50');
      expect(const Money(1000).format(), 'S/ 10.00');
      expect(const Money.zero().format(), 'S/ 0.00');
    });

    test('negativos llevan el signo delante', () {
      expect(const Money(-500).format(), '-S/ 5.00');
    });

    test('sin símbolo', () {
      expect(const Money(99).format(withSymbol: false), '0.99');
    });
  });

  group('Money.tryParse', () {
    final cases = <String, int?>{
      '10': 1000,
      '10.5': 1050,
      '10.50': 1050,
      '10,50': 1050,
      '1,234.50': 123450,
      '1.234,50': 123450,
      '1,234': 123400,
      'S/ 25.00': 2500,
      '  7 ': 700,
      '0.05': 5,
      '': null,
      'abc': null,
      '10.555': null,
      '-5': null,
    };
    for (final MapEntry(key: input, value: expected) in cases.entries) {
      test('"$input" → $expected', () {
        expect(Money.tryParse(input)?.cents, expected);
      });
    }
  });

  test('aritmética y comparación', () {
    const a = Money(1000);
    const b = Money(250);
    expect((a - b).cents, 750);
    expect((a + b).cents, 1250);
    expect(a > b, isTrue);
    expect(Money.sum([a, b, b]).cents, 1500);
    expect(-a, const Money(-1000));
  });

  test('fromSoles redondea al céntimo', () {
    expect(Money.fromSoles(0.1 + 0.2).cents, 30);
    expect(Money.fromSoles(19.999).cents, 2000);
  });
}
