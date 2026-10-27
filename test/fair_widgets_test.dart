import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/features/groups/presentation/widgets/group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Widget child, {Locale locale = const Locale('id')}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  );
}

Group buildGroup({
  String name = 'Trip Bali',
  GroupType type = GroupType.trip,
  int memberCount = 4,
  String description = 'Patungan villa dan bensin.',
}) {
  return Group(
    id: 'group-1',
    name: name,
    description: description,
    emoji: '🏖️',
    type: type,
    currency: 'IDR',
    ownerId: 'user-1',
    memberCount: memberCount,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );
}

void main() {
  group('FairCard', () {
    testWidgets('renders its child and handles taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        harness(FairCard(onTap: () => taps++, child: const Text('Grup Senja'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grup Senja'), findsOneWidget);

      await tester.tap(find.text('Grup Senja'));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('EmptyState', () {
    testWidgets('shows title, body and action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        harness(
          EmptyState(
            icon: Icons.groups_rounded,
            title: 'Belum ada grup',
            body: 'Bikin grup pertama buat mulai bagi-bagi.',
            action: FilledButton(
              onPressed: () => tapped = true,
              child: const Text('Buat grup'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum ada grup'), findsOneWidget);
      expect(find.byIcon(Icons.groups_rounded), findsOneWidget);

      await tester.tap(find.text('Buat grup'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('AmountText', () {
    testWidgets('formats minor units using the currency', (tester) async {
      await tester.pumpWidget(
        harness(const AmountText(minor: 1500000, currency: 'IDR')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rp 1.500.000'), findsOneWidget);
    });
  });

  group('AvatarCircle', () {
    test('builds initials from the first and last name', () {
      expect(AvatarCircle.initialsFor('Rani Putri'), 'RP');
      expect(AvatarCircle.initialsFor('Budi'), 'B');
      expect(AvatarCircle.initialsFor('  '), '?');
    });
  });

  group('GroupCard', () {
    testWidgets('shows who owes what and opens the group', (tester) async {
      final l10n = const AppLocalizations(Locale('id'));
      var opened = false;

      await tester.pumpWidget(
        harness(
          GroupCard(
            group: buildGroup(),
            netMinor: -250000,
            expenseCount: 3,
            onTap: () => opened = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip Bali'), findsOneWidget);
      expect(find.text(l10n.groupTypeName(GroupType.trip)), findsOneWidget);
      expect(find.text(l10n.membersCount(4)), findsOneWidget);
      expect(find.text(l10n.youOwe), findsOneWidget);
      expect(find.byType(AmountText), findsOneWidget);

      await tester.tap(find.text('Trip Bali'));
      await tester.pump();

      expect(opened, isTrue);
    });

    testWidgets('marks a zero balance as impas', (tester) async {
      final l10n = const AppLocalizations(Locale('id'));

      await tester.pumpWidget(
        harness(GroupCard(group: buildGroup(), netMinor: 0, onTap: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.impas), findsOneWidget);
      expect(find.text(l10n.youOwe), findsNothing);
    });

    testWidgets('localizes to English', (tester) async {
      final l10n = const AppLocalizations(Locale('en'));

      await tester.pumpWidget(
        harness(
          GroupCard(
            group: buildGroup(type: GroupType.hangout),
            netMinor: 120000,
            onTap: () {},
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.youAreOwed), findsOneWidget);
      expect(find.text(l10n.groupTypeName(GroupType.hangout)), findsOneWidget);
    });

    testWidgets('fits a narrow phone without overflowing', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        harness(
          GroupCard(
            group: buildGroup(
              name: 'Kos Ceria Bareng Anak Teknik',
              description:
                  'Sewa kos, listrik, wifi, dan galon bareng sebulan sekali.',
            ),
            netMinor: 987654321,
            expenseCount: 42,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Kos Ceria Bareng Anak Teknik'), findsOneWidget);
    });
  });
}
