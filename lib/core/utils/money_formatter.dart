import 'package:intl/intl.dart';

/// Formatting and parsing for money values.
///
/// The domain stores integer minor units (rupiah, cents, yen...) so split
/// calculations never drift because of floating point rounding.
abstract final class MoneyFormatter {
  static const Map<String, String> symbols = {
    'IDR': 'Rp',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'SGD': r'S$',
    'MYR': 'RM',
    'JPY': '¥',
    'KRW': '₩',
    'AUD': r'A$',
    'THB': '฿',
    'VND': '₫',
    'CNY': '¥',
  };

  static const Map<String, String> names = {
    'IDR': 'Rupiah Indonesia',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'SGD': 'Singapore Dollar',
    'MYR': 'Malaysian Ringgit',
    'JPY': 'Japanese Yen',
    'KRW': 'Korean Won',
    'AUD': 'Australian Dollar',
    'THB': 'Thai Baht',
    'VND': 'Vietnamese Dong',
    'CNY': 'Chinese Yuan',
  };

  static const List<String> supportedCurrencies = [
    'IDR',
    'USD',
    'EUR',
    'SGD',
    'MYR',
    'JPY',
    'KRW',
    'AUD',
    'GBP',
    'THB',
    'VND',
    'CNY',
  ];

  /// Currencies without decimal subunits.
  static const Set<String> zeroDecimalCurrencies = {'IDR', 'JPY', 'KRW', 'VND'};

  static int decimalsFor(String currency) =>
      zeroDecimalCurrencies.contains(currency.toUpperCase()) ? 0 : 2;

  static double majorUnits(int minorUnits, {String currency = 'IDR'}) {
    final decimals = decimalsFor(currency);
    if (decimals == 0) return minorUnits.toDouble();
    return minorUnits / 100;
  }

  static int toMinor(num major, {String currency = 'IDR'}) {
    final decimals = decimalsFor(currency);
    return decimals == 0 ? major.round() : (major * 100).round();
  }

  static String symbolFor(String currency) =>
      symbols[currency.toUpperCase()] ?? currency.toUpperCase();

  static String format(
    int minorUnits, {
    String currency = 'IDR',
    String localeCode = 'id',
    bool signed = false,
    bool compact = false,
    bool withSymbol = true,
  }) {
    final locale = localeCode == 'en' ? 'en_US' : 'id_ID';
    final decimals = decimalsFor(currency);
    final value = majorUnits(minorUnits, currency: currency);
    final symbol = symbolFor(currency);

    if (compact) {
      return _compact(
        value,
        symbol: withSymbol ? symbol : '',
        localeCode: localeCode,
        signed: signed,
        minor: minorUnits,
      );
    }

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: withSymbol ? '$symbol ' : '',
      decimalDigits: decimals,
    );
    final text = formatter.format(value.abs());
    final prefix = signed
        ? (minorUnits > 0 ? '+' : (minorUnits < 0 ? '−' : ''))
        : (minorUnits < 0 ? '−' : '');
    return '$prefix$text'.trim();
  }

  static String _compact(
    double value, {
    required String symbol,
    required String localeCode,
    required bool signed,
    required int minor,
  }) {
    final abs = value.abs();
    final (divisor, suffixId, suffixEn) = switch (abs) {
      >= 1000000000 => (1000000000.0, ' M', 'B'),
      >= 1000000 => (1000000.0, ' jt', 'M'),
      >= 1000 => (1000.0, ' rb', 'K'),
      _ => (1.0, '', ''),
    };
    final scaled = abs / divisor;
    final digits = divisor == 1 ? 0 : (scaled >= 10 ? 1 : 1);
    final number = NumberFormat.decimalPatternDigits(
      locale: localeCode == 'en' ? 'en_US' : 'id_ID',
      decimalDigits: digits,
    ).format(scaled);
    final suffix = localeCode == 'en' ? suffixEn : suffixId;
    final prefix = signed
        ? (minor > 0 ? '+' : (minor < 0 ? '−' : ''))
        : (minor < 0 ? '−' : '');
    final spacedSymbol = symbol.isEmpty ? '' : '$symbol ';
    return '$prefix$spacedSymbol$number$suffix'.trim();
  }

  /// Accepts `1.500.000`, `1500000`, `1,5jt`, `250rb`, `$12.50`.
  static int? parse(String raw, {String currency = 'IDR'}) {
    var text = raw.trim().toLowerCase();
    if (text.isEmpty) return null;

    var multiplier = 1;
    if (text.contains('jt') || text.contains('juta')) {
      multiplier = 1000000;
    } else if (text.contains('rb') || text.contains('ribu')) {
      multiplier = 1000;
    }
    text = text.replaceAll(RegExp(r'(juta|jt|ribu|rb)$'), '');

    // Keep separators so `1,5jt` (one and a half million) survives.
    final cleaned = text.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (cleaned.isEmpty) return null;

    if (decimalsFor(currency) > 0) {
      final normalized = _normalizeDecimal(cleaned);
      final value = normalized == null ? null : double.tryParse(normalized);
      if (value == null) return null;
      return toMinor(value * multiplier, currency: currency);
    }

    if (multiplier == 1) {
      final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
      final value = digits.isEmpty ? null : int.tryParse(digits);
      return value;
    }

    // Shorthand such as `1,5jt` / `2.5rb` needs the decimal preserved. At the
    // same time `1.500rb` must still mean 1,500 thousand, not 1.5 thousand.
    final normalized = _normalizeDecimal(cleaned);
    final value = normalized == null ? null : double.tryParse(normalized);
    if (value == null) return null;
    return (value * multiplier).round();
  }

  /// Turns locale-ish input into a Dart `double`-parseable string.
  ///
  /// Both `1.234,56` (Indonesian) and `1,234.56` (English) are understood:
  /// the separator that appears last is the decimal one.
  static String? _normalizeDecimal(String cleaned) {
    final lastDot = cleaned.lastIndexOf('.');
    final lastComma = cleaned.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      return lastComma > lastDot
          ? cleaned.replaceAll('.', '').replaceAll(',', '.')
          : cleaned.replaceAll(',', '');
    }
    if (lastComma >= 0) {
      final parts = cleaned.split(',');
      return parts.length > 2
          ? cleaned.replaceAll(',', '')
          : cleaned.replaceAll(',', '.');
    }
    if (lastDot >= 0) {
      final parts = cleaned.split('.');
      return parts.length > 2 || (parts.length == 2 && parts[1].length == 3)
          ? cleaned.replaceAll('.', '')
          : cleaned;
    }
    return cleaned;
  }

  /// Formats an amount for a text field, without the currency symbol.
  static String input(int minorUnits, {String currency = 'IDR'}) {
    final decimals = decimalsFor(currency);
    if (decimals == 0) {
      return NumberFormat.decimalPattern('id_ID').format(minorUnits);
    }
    return NumberFormat.decimalPatternDigits(
      locale: 'id_ID',
      decimalDigits: decimals,
    ).format(majorUnits(minorUnits, currency: currency));
  }

  static String percent(double ratio, {String localeCode = 'id'}) {
    final formatter = NumberFormat.decimalPercentPattern(
      locale: localeCode == 'en' ? 'en_US' : 'id_ID',
      decimalDigits: 0,
    );
    return formatter.format(ratio.clamp(0, 9.99));
  }
}
