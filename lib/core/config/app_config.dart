import 'package:flutter/foundation.dart';

/// Compile-time configuration.
///
/// Bagi Fair is a cloud product: the linked Supabase project is the source of
/// truth and every member reads and writes through it. The public anon key is
/// baked in as a default so a plain `flutter run` (or a deployed web build) is
/// connected without extra flags — RLS is what protects the data, never the
/// secrecy of this key.
///
/// Override the project for a fork with:
/// `flutter run --dart-define-from-file=env.json`
abstract final class AppConfig {
  static const String appName = 'Bagi Fair';
  static const String taglineId = 'Bagi adil, tanpa baper.';
  static const String taglineEn = 'Fair splits, no drama.';
  static const String appScheme = String.fromEnvironment(
    'APP_SCHEME',
    defaultValue: 'bagifair',
  );
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tkjjpmwwvlvgydutnpls.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrampwbXd3dmx2Z3lkdXRucGxzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwNzkwMTgsImV4cCI6MjEwODY1NTAxOH0.fJ9QciBRERyyyDdaeh8cNi_x-cn1tPcm0HpWmqU0XaM',
  );
  static const String inviteHost = String.fromEnvironment(
    'INVITE_HOST',
    defaultValue: 'bagifair.app',
  );

  static const int aiRateLimitPerHour = 10;
  static const int maxReceiptUploadBytes = 6 * 1024 * 1024;

  static bool get hasSupabase =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static String get webBaseUrl {
    if (kIsWeb) return Uri.base.resolve('.').toString();
    return 'https://$inviteHost/';
  }

  static String inviteLink(String code) {
    if (kIsWeb) {
      final base = webBaseUrl.endsWith('/') ? webBaseUrl : '$webBaseUrl/';
      // The web build uses GoRouter's hash strategy and GitHub Pages cannot
      // rewrite arbitrary paths, so the route lives after the '#'.
      return '$base#/join/$code';
    }
    return 'https://$inviteHost/join/$code';
  }
}
