import 'package:bagi_fair/core/utils/money_formatter.dart';

abstract final class CurrencyConverter {
  static int toBase(
    int amountMinor, {
    required String fromCurrency,
    required String toCurrency,
    required double rate,
  }) {
    if (fromCurrency == toCurrency) return amountMinor;
    final major = MoneyFormatter.majorUnits(
      amountMinor,
      currency: fromCurrency,
    );
    return MoneyFormatter.toMinor(major * rate, currency: toCurrency);
  }

  static double impliedRate({
    required int amountMinor,
    required String currency,
    required int amountBaseMinor,
    required String baseCurrency,
  }) {
    if (amountMinor == 0) return 1;
    final source = MoneyFormatter.majorUnits(amountMinor, currency: currency);
    final base = MoneyFormatter.majorUnits(
      amountBaseMinor,
      currency: baseCurrency,
    );
    if (source == 0) return 1;
    return base / source;
  }
}
