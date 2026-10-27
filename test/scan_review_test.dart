import 'package:bagi_fair/core/localization/app_localizations.dart';
import 'package:bagi_fair/core/theme/app_theme.dart';
import 'package:bagi_fair/domain/entities/receipt.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/bloc/receipt_scan_bloc.dart';
import 'package:bagi_fair/features/receipt_scan/presentation/widgets/scan_review_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const l10n = AppLocalizations(Locale('id'));

  testWidgets('review stage renders AI values as editable fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final merchant = TextEditingController(text: 'Warung Sederhana');
    final tax = TextEditingController(text: '5.000');
    final service = TextEditingController(text: '2.500');
    addTearDown(merchant.dispose);
    addTearDown(tax.dispose);
    addTearDown(service.dispose);

    final state = ReceiptScanState(
      loading: false,
      manual: true,
      merchant: 'Warung Sederhana',
      currency: 'IDR',
      items: const [
        ReceiptItem(
          id: 'i1',
          name: 'Nasi goreng',
          quantity: 2,
          unitPriceMinor: 25000,
          totalMinor: 50000,
        ),
        ReceiptItem(
          id: 'i2',
          name: 'Es teh',
          unitPriceMinor: 5000,
          totalMinor: 5000,
        ),
      ],
      taxMinor: 5000,
      serviceMinor: 2500,
      confidence: 0.92,
      occurredAt: DateTime(2026, 10, 27),
    );

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
            child: ScanReviewStage(
              state: state,
              merchant: merchant,
              tax: tax,
              service: service,
              onPickAgain: () {},
              onEvent: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nasi goreng'), findsOneWidget);
    expect(find.text('Es teh'), findsOneWidget);
    expect(find.text('Warung Sederhana'), findsOneWidget);
    expect(find.text('Rp 62.500'), findsOneWidget);
    expect(find.text(l10n.receiptItems), findsOneWidget);
    expect(find.text(l10n.tax), findsOneWidget);
    expect(find.text(l10n.service), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
