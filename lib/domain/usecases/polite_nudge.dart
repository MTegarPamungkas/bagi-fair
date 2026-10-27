import 'package:bagi_fair/core/utils/money_formatter.dart';

abstract final class PoliteNudge {
  static String build({
    required String fromName,
    required String toName,
    required String groupName,
    required int amountMinor,
    required String currency,
    required String localeCode,
  }) {
    final amount = MoneyFormatter.format(
      amountMinor,
      currency: currency,
      localeCode: localeCode,
    );
    if (localeCode == 'en') {
      return 'Hi $toName! 👋 Just a gentle reminder from $fromName: '
          'the $groupName group has $amount waiting to be settled. '
          'If you have already paid, mark it as settled so everyone is even. '
          'No pressure, and thank you! 🙌';
    }
    return 'Halo $toName! 👋 Colek halus dari $fromName: di grup $groupName '
        'tercatat $amount yang belum diselesaikan. Kalau sudah transfer, '
        'tandai lunas ya biar semua impas. Santai, tidak buru-buru. '
        'Makasih banyak! 🙌';
  }

  static String summary({
    required String groupName,
    required int totalMinor,
    required String currency,
    required String localeCode,
    required List<(String, int)> transfers,
  }) {
    final buffer = StringBuffer();
    if (localeCode == 'en') {
      buffer.writeln('🍕 *Bagi Fair · $groupName*');
      buffer.writeln(
        'Total ${MoneyFormatter.format(totalMinor, currency: currency, localeCode: localeCode)}',
      );
      if (transfers.isEmpty) {
        buffer.writeln('Everyone is even. Impas! ✅');
      } else {
        buffer.writeln('Simplest way to settle up:');
        for (final transfer in transfers) {
          buffer.writeln(
            '• ${transfer.$1}: '
            '${MoneyFormatter.format(transfer.$2, currency: currency, localeCode: localeCode)}',
          );
        }
      }
      buffer.write('Shared from Bagi Fair — fair splits, no drama.');
    } else {
      buffer.writeln('🍕 *Bagi Fair · $groupName*');
      buffer.writeln(
        'Total ${MoneyFormatter.format(totalMinor, currency: currency, localeCode: localeCode)}',
      );
      if (transfers.isEmpty) {
        buffer.writeln('Semua sudah impas. ✅');
      } else {
        buffer.writeln('Cara paling simpel buat lunasin:');
        for (final transfer in transfers) {
          buffer.writeln(
            '• ${transfer.$1}: '
            '${MoneyFormatter.format(transfer.$2, currency: currency, localeCode: localeCode)}',
          );
        }
      }
      buffer.write('Dibagikan dari Bagi Fair — bagi adil, tanpa baper.');
    }
    return buffer.toString();
  }
}
