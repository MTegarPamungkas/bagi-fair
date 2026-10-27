import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/usecases/auth_usecases.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/auth/presentation/pages/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// A configured repository with no network. The auth screen never needs a live
/// Supabase project to be widget-tested.
class _FakeAuthRepository implements AuthRepository {
  @override
  bool get isConfigured => true;

  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> watchUser() => const Stream<AppUser?>.empty();

  @override
  Future<AppUser> signInWithEmail(String email, String password) async =>
      throw const AuthException('invalid_credentials');

  @override
  Future<AppUser?> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  const id = AppLocalizations(Locale('id'));
  const en = AppLocalizations(Locale('en'));

  late AuthBloc bloc;

  setUp(() {
    final repository = _FakeAuthRepository();
    bloc = AuthBloc(
      WatchAuthUser(repository),
      SignInWithEmail(repository),
      SignUpWithEmail(repository),
      SignOut(repository),
      repository,
    );
  });

  tearDown(() => bloc.close());

  Future<void> pumpAuthPage(
    WidgetTester tester, {
    Locale locale = const Locale('id'),
    Size size = const Size(430, 1180),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: BlocProvider.value(value: bloc, child: const AuthPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the email sign-in form without Google or demo entry', (
    tester,
  ) async {
    await pumpAuthPage(tester);

    expect(find.text(id.signIn), findsNWidgets(3));
    expect(find.byKey(const Key('auth-email')), findsOneWidget);
    expect(find.byKey(const Key('auth-password')), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsNothing);
    expect(find.text('Coba mode demo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validates empty credentials before hitting the network', (
    tester,
  ) async {
    await pumpAuthPage(tester);

    await tester.tap(find.widgetWithText(FilledButton, id.signIn));
    await tester.pumpAndSettle();

    expect(find.text(id.emailRequired), findsOneWidget);
    expect(find.text(id.passwordRequired), findsOneWidget);
  });

  testWidgets('switches to the sign-up form with a name field', (tester) async {
    await pumpAuthPage(tester);

    await tester.tap(find.text(id.signUp).first);
    await tester.pumpAndSettle();

    expect(find.text(id.displayName), findsOneWidget);
    expect(find.widgetWithText(FilledButton, id.createAccount), findsOneWidget);
  });

  testWidgets('renders the two-column layout on wide screens', (tester) async {
    await pumpAuthPage(tester, size: const Size(1280, 900));

    expect(find.text(id.welcomeBody), findsWidgets);
    expect(find.text(id.signIn), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes the auth screen to English', (tester) async {
    await pumpAuthPage(tester, locale: const Locale('en'));

    expect(find.text(en.signIn), findsNWidgets(3));
    expect(find.text(en.welcomeTitle), findsWidgets);
  });
}
