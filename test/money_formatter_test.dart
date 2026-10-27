import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyFormatter.format', () {
    test('formats IDR with Indonesian thousands separators', () {
      expect(MoneyFormatter.format(1500000), 'Rp 1.500.000');
      expect(MoneyFormatter.format(0), 'Rp 0');
    });

    test('formats decimal currencies from minor units', () {
      expect(
        MoneyFormatter.format(1250, currency: 'USD', localeCode: 'en'),
        r'$ 12.50',
      );
      // Indonesian locale uses a comma for decimals even for USD.
      expect(MoneyFormatter.format(1250, currency: 'USD'), r'$ 12,50');
      expect(MoneyFormatter.format(123456, currency: 'EUR'), '€ 1.234,56');
    });

    test('keeps the sign explicit when asked', () {
      expect(MoneyFormatter.format(250000, signed: true), '+Rp 250.000');
      expect(MoneyFormatter.format(-250000, signed: true), '−Rp 250.000');
    });

    test('compacts large amounts per locale', () {
      expect(MoneyFormatter.format(1500000, compact: true), contains('1,5'));
      expect(
        MoneyFormatter.format(2500000, compact: true, localeCode: 'en'),
        contains('2.5'),
      );
      expect(MoneyFormatter.format(1500000, compact: true), contains('jt'));
      expect(
        MoneyFormatter.format(1500000, compact: true, localeCode: 'en'),
        contains('M'),
      );
    });
  });

  group('MoneyFormatter currency configuration', () {
    test('only IDR, JPY, KRW and VND are zero-decimal', () {
      for (final code in ['IDR', 'JPY', 'KRW', 'VND']) {
        expect(MoneyFormatter.decimalsFor(code), 0, reason: code);
      }
      for (final code in ['USD', 'EUR', 'SGD', 'MYR']) {
        expect(MoneyFormatter.decimalsFor(code), 2, reason: code);
      }
    });

    test('converts major and minor units without drift', () {
      expect(MoneyFormatter.toMinor(1500.4, currency: 'IDR'), 1500);
      expect(MoneyFormatter.toMinor(12.5, currency: 'USD'), 1250);
      expect(MoneyFormatter.majorUnits(1500000), 1500000);
      expect(MoneyFormatter.majorUnits(1250, currency: 'USD'), 12.5);
    });

    test('input() round-trips through parse()', () {
      expect(MoneyFormatter.input(1500000), '1.500.000');
      expect(MoneyFormatter.parse(MoneyFormatter.input(1500000)), 1500000);
      expect(
        MoneyFormatter.parse(
          MoneyFormatter.input(1250, currency: 'USD'),
          currency: 'USD',
        ),
        1250,
      );
    });
  });

  group('MoneyFormatter.parse', () {
    test('accepts plain and grouped rupiah', () {
      expect(MoneyFormatter.parse('1500000'), 1500000);
      expect(MoneyFormatter.parse('1.500.000'), 1500000);
      expect(MoneyFormatter.parse('Rp 25.000'), 25000);
    });

    test('honours ribu/juta shorthand including decimals', () {
      expect(MoneyFormatter.parse('250rb'), 250000);
      expect(MoneyFormatter.parse('1,5jt'), 1500000);
      expect(MoneyFormatter.parse('1.5jt'), 1500000);
      expect(MoneyFormatter.parse('2 juta'), 2000000);
      expect(MoneyFormatter.parse('1.500rb'), 1500000);
    });

    test('parses decimal currencies with either separator style', () {
      expect(MoneyFormatter.parse(r'$12.50', currency: 'USD'), 1250);
      expect(MoneyFormatter.parse('12,50', currency: 'USD'), 1250);
      expect(MoneyFormatter.parse('1.234,56', currency: 'EUR'), 123456);
      expect(MoneyFormatter.parse('1,234.56', currency: 'SGD'), 123456);
    });

    test('rejects empty or non-numeric input', () {
      expect(MoneyFormatter.parse(''), isNull);
      expect(MoneyFormatter.parse('   '), isNull);
      expect(MoneyFormatter.parse('abc'), isNull);
    });
  });

  test('percent renders whole percentages', () {
    expect(MoneyFormatter.percent(0.25), '25%');
  });
}
