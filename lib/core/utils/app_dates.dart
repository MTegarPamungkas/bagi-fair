import 'package:intl/intl.dart';

abstract final class AppDates {
  static String short(DateTime date, {String localeCode = 'id'}) {
    final locale = localeCode == 'en' ? 'en_US' : 'id_ID';
    return DateFormat('d MMM', locale).format(date.toLocal());
  }

  static String medium(DateTime date, {String localeCode = 'id'}) {
    final locale = localeCode == 'en' ? 'en_US' : 'id_ID';
    return DateFormat('d MMM yyyy', locale).format(date.toLocal());
  }

  static String full(DateTime date, {String localeCode = 'id'}) {
    final locale = localeCode == 'en' ? 'en_US' : 'id_ID';
    return DateFormat('EEEE, d MMMM yyyy', locale).format(date.toLocal());
  }

  static String monthYear(DateTime date, {String localeCode = 'id'}) {
    final locale = localeCode == 'en' ? 'en_US' : 'id_ID';
    return DateFormat('MMMM yyyy', locale).format(date.toLocal());
  }

  static String relative(
    DateTime date, {
    String localeCode = 'id',
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(date);
    final isId = localeCode != 'en';
    if (diff.inMinutes < 1) return isId ? 'baru saja' : 'just now';
    if (diff.inMinutes < 60) {
      return isId ? '${diff.inMinutes} mnt lalu' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isId ? '${diff.inHours} jam lalu' : '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) return isId ? 'kemarin' : 'yesterday';
    if (diff.inDays < 7) {
      return isId ? '${diff.inDays} hari lalu' : '${diff.inDays}d ago';
    }
    return short(date, localeCode: localeCode);
  }
}
