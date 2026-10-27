import 'dart:async';

import 'package:bagi_fair/app/app_shell.dart';
import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bagi_fair/features/auth/presentation/pages/auth_page.dart';
import 'package:bagi_fair/features/expense_form/presentation/bloc/expense_form_bloc.dart';
import 'package:bagi_fair/features/expense_form/presentation/pages/expense_form_page.dart';
import 'package:bagi_fair/features/group_detail/presentation/pages/group_detail_page.dart';
import 'package:bagi_fair/features/groups/presentation/pages/group_form_page.dart';
import 'package:bagi_fair/features/groups/presentation/pages/groups_page.dart';
import 'package:bagi_fair/features/groups/presentation/pages/join_group_page.dart';
import 'package:bagi_fair/features/home/presentation/pages/home_page.dart';
import 'package:bagi_fair/features/notifications/presentation/pages/notifications_page.dart';
import 'package:bagi_fair/features/profile/presentation/pages/profile_page.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/pages/receipt_scan_page.dart';
import 'package:bagi_fair/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(AuthBloc auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(auth.stream),
    redirect: (context, state) {
      final signedIn = auth.state.signedIn;
      final resolving = auth.state.resolving;
      final location = state.matchedLocation;

      if (resolving) {
        return location == '/splash' ? null : '/splash';
      }
      if (!signedIn) {
        if (location == '/auth') return null;
        if (location == '/splash' || location == '/') return '/auth';
        final target = state.uri.toString();
        return '/auth?next=${Uri.encodeComponent(target)}';
      }
      if (location == '/auth') {
        final next = state.uri.queryParameters['next'];
        if (next != null && next.startsWith('/')) return next;
        return '/home';
      }
      if (location == '/splash' || location == '/') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) =>
            AuthPage(nextLocation: state.uri.queryParameters['next']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                builder: (context, state) => const GroupsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/groups/new',
        builder: (context, state) => const GroupFormPage(),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (context, state) => const JoinGroupPage(),
      ),
      GoRoute(
        path: '/groups/:groupId/expenses/new',
        builder: (context, state) => ExpenseFormPage(
          request: ExpenseFormRequest(
            groupId: state.pathParameters['groupId']!,
            receiptId: state.uri.queryParameters['receiptId'],
          ),
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/expenses/:expenseId',
        builder: (context, state) => ExpenseFormPage(
          request: ExpenseFormRequest(
            groupId: state.pathParameters['groupId']!,
            expenseId: state.pathParameters['expenseId'],
          ),
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/scan',
        builder: (context, state) =>
            ReceiptScanPage(groupId: state.pathParameters['groupId']!),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) =>
            GroupDetailPage(groupId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/join/:code',
        builder: (context, state) =>
            JoinGroupPage(initialCode: state.pathParameters['code']),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = context.l10n;
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: FairBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: EmptyState(
                  icon: Icons.explore_off_outlined,
                  title: l10n.t('Halaman tidak ditemukan', 'Page not found'),
                  body: state.uri.toString(),
                  action: FilledButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home_outlined, size: 18),
                    label: Text(l10n.home),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final fair = context.fair;
    return Scaffold(
      backgroundColor: fair.background,
      body: FairBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FairLogo(size: 84),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.appName.toUpperCase(),
                  style: context.texts.labelLarge?.copyWith(
                    letterSpacing: 4.4,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    context.l10n.tagline,
                    textAlign: TextAlign.center,
                    style: context.texts.headlineSmall?.copyWith(height: 1.2),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fair.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
