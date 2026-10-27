import 'dart:async';

import 'package:bagi_fair/app/app_router.dart';
import 'package:bagi_fair/core/config/app_config.dart';
import 'package:bagi_fair/core/di/injection_container.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/data/services/app_links_service.dart';
import 'package:bagi_fair/domain/entities/app_settings.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:bagi_fair/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

class BagiFairApp extends StatefulWidget {
  const BagiFairApp({super.key});

  @override
  State<BagiFairApp> createState() => _BagiFairAppState();
}

class _BagiFairAppState extends State<BagiFairApp> {
  late final GoRouter _router = createRouter(getIt<AuthBloc>());
  StreamSubscription<String>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenInviteLinks();
  }

  void _listenInviteLinks() {
    final links = getIt<AppLinksService>();
    _linkSubscription = links.inviteCodes.listen(_handleInviteCode);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final code = await links.initialInviteCode();
      if (code != null) _handleInviteCode(code);
    });
  }

  void _handleInviteCode(String code) {
    if (!mounted) return;
    final location = '/join/$code';
    if (_router.state.matchedLocation == location) return;
    if (getIt<AuthBloc>().state.signedIn) {
      _router.push(location);
    } else {
      _router.go(location);
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: getIt<SettingsBloc>()),
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<SyncBloc>.value(value: getIt<SyncBloc>()),
      ],
      child: BlocBuilder<SettingsBloc, AppSettings>(
        builder: (context, settings) {
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: switch (settings.themeMode) {
              AppThemeMode.system => ThemeMode.system,
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
            },
            locale: Locale(settings.localeCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            scrollBehavior: const _FairScrollBehavior(),
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.3,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

class _FairScrollBehavior extends MaterialScrollBehavior {
  const _FairScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
