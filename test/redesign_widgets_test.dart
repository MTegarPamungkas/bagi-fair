import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/core/widgets/fair_ui.dart';
import 'package:bagi_fair/domain/entities/balance.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/home_overview.dart';
import 'package:bagi_fair/features/home/presentation/widgets/home_balance_card.dart';
import 'package:bagi_fair/features/home/presentation/widgets/home_group_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = AppLocalizations(Locale('id'));

  final now = DateTime(2026, 10, 20);
  final group = Group(
    id: 'group-1',
    name: 'Bali Trip',
    type: GroupType.trip,
    currency: 'IDR',
    ownerId: 'user-1',
    memberCount: 3,
    createdAt: now,
    updatedAt: now,
  );
  final members = [
    GroupMember(
      id: 'm1',
      groupId: group.id,
      userId: 'user-1',
      displayName: 'Budi',
      role: GroupRole.owner,
      joinedAt: now,
    ),
    GroupMember(
      id: 'm2',
      groupId: group.id,
      userId: 'user-2',
      displayName: 'Sinta',
      role: GroupRole.member,
      joinedAt: now,
    ),
  ];

  GroupOverview overviewFor({int owe = 0, int owed = 0}) => GroupOverview(
    group: group,
    members: members,
    summary: GroupBalanceSummary(
      youOweMinor: owe,
      youAreOwedMinor: owed,
      isImpas: owe == 0 && owed == 0,
    ),
    expenseCount: 2,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(430, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('id'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('debt is shown with a minus sign, not a plus', (tester) async {
    await pump(
      tester,
      HomeBalanceCard(
        overview: HomeOverview(
          groups: [overviewFor(owe: 52000)],
          youOweMinor: 52000,
        ),
      ),
    );

    expect(find.text(id.youOwe), findsWidgets);
    expect(find.text('−Rp 52.000'), findsOneWidget);
    expect(find.text('+Rp 52.000'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('credit is shown with a plus sign', (tester) async {
    await pump(
      tester,
      HomeBalanceCard(
        overview: HomeOverview(
          groups: [overviewFor(owed: 250000)],
          youAreOwedMinor: 250000,
        ),
      ),
    );

    expect(find.text('+Rp 250.000'), findsOneWidget);
    expect(find.text(id.youAreOwed), findsWidgets);
  });

  testWidgets('settled group shows the Impas stamp', (tester) async {
    await pump(
      tester,
      HomeBalanceCard(overview: HomeOverview(groups: [overviewFor()])),
    );

    expect(find.text('IMPAS'), findsOneWidget);
    expect(find.text(id.impasTitle), findsOneWidget);
  });

  testWidgets('group ledger row explains who owes whom', (tester) async {
    await pump(
      tester,
      HomeGroupList(
        groups: [overviewFor(owe: 52000)],
        onOpen: (_) {},
      ),
    );

    expect(find.text('Bali Trip'), findsOneWidget);
    expect(find.text(id.youOwe), findsOneWidget);
    expect(find.text('Rp 52,0 rb'), findsOneWidget);
  });

  testWidgets('PageHeader stacks actions below the title on a phone', (
    tester,
  ) async {
    await pump(
      tester,
      PageHeader(
        title: 'Grup kamu',
        subtitle: 'Satu tempat untuk trip, kos, dan nongkrong.',
        actions: [
          OutlinedButton(onPressed: () {}, child: const Text('Gabung grup')),
          FilledButton(onPressed: () {}, child: const Text('Grup baru')),
        ],
      ),
      size: const Size(360, 800),
    );

    expect(find.text('Grup kamu'), findsOneWidget);
    expect(find.text('Grup baru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PerforatedDivider keeps an accessible label', (tester) async {
    await pump(tester, const PerforatedDivider(label: 'Total'));
    expect(find.text('TOTAL'), findsOneWidget);
  });
}
