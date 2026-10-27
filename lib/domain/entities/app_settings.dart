import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.localeCode = 'id',
    this.defaultCurrency = 'IDR',
    this.notificationsEnabled = true,
    this.politeReminders = true,
  });

  final AppThemeMode themeMode;
  final String localeCode;
  final String defaultCurrency;
  final bool notificationsEnabled;
  final bool politeReminders;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? localeCode,
    String? defaultCurrency,
    bool? notificationsEnabled,
    bool? politeReminders,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      politeReminders: politeReminders ?? this.politeReminders,
    );
  }

  Map<String, dynamic> toJson() => {
    'theme_mode': themeMode.name,
    'locale_code': localeCode,
    'default_currency': defaultCurrency,
    'notifications_enabled': notificationsEnabled,
    'polite_reminders': politeReminders,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (mode) => mode.name == json['theme_mode'],
        orElse: () => AppThemeMode.system,
      ),
      localeCode: json['locale_code'] == 'en' ? 'en' : 'id',
      defaultCurrency: (json['default_currency'] as String?) ?? 'IDR',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      politeReminders: json['polite_reminders'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    localeCode,
    defaultCurrency,
    notificationsEnabled,
    politeReminders,
  ];
}
