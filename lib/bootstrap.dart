import 'package:bagi_fair/app/app.dart';
import 'package:bagi_fair/core/config/app_config.dart';
import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/data/services/notification_service.dart';
import 'package:bagi_fair/data/sync/sync_engine.dart';
import 'package:bagi_fair/app/connection_error_app.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Boots storage, the Supabase client, dependency injection, notifications and
/// the sync engine before the first frame.
///
/// There is no demo database: Bagi Fair is backed by the linked Supabase
/// project. If the client cannot even be constructed (bad URL or key) the app
/// shows an honest connection screen instead of silently faking data.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = LocalStore();
  await store.init();

  if (!AppConfig.hasSupabase) {
    runApp(
      const ConnectionErrorApp(
        message:
            'SUPABASE_URL / SUPABASE_ANON_KEY belum diatur. '
            'Jalankan dengan --dart-define-from-file=env.json.',
      ),
    );
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (error, stackTrace) {
    debugPrint('Supabase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(ConnectionErrorApp(message: error.toString()));
    return;
  }

  await configureDependencies(
    store: store,
    client: Supabase.instance.client,
  );
  await getIt<NotificationService>().init();
  await getIt<SyncEngine>().start();

  runApp(const BagiFairApp());
}
