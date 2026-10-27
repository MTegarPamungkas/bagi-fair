import 'dart:convert';
import 'dart:typed_data';

import 'package:bagi_fair/core/utils/app_dates.dart';
import 'package:bagi_fair/core/utils/money_formatter.dart';
import 'package:bagi_fair/domain/entities/balance.dart';
import 'package:bagi_fair/domain/repositories/export_repository.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportRepositoryImpl implements ExportRepository {
  @override
  Future<void> exportCsv(GroupExportRequest request) async {
    final names = {
      for (final member in request.members) member.userId: member.displayName,
    };
    final buffer = StringBuffer();
    buffer.writeln(
      'group,date,title,payer,amount,currency,split_mode,participants,shares',
    );
    for (final expense in request.expenses) {
      final participants = expense.shares
          .map((share) => names[share.userId] ?? share.userId)
          .join(' | ');
      final shares = expense.shares
          .map(
            (share) =>
                '${names[share.userId] ?? share.userId}=${MoneyFormatter.format(share.amountMinor, currency: request.group.currency)}',
          )
          .join(' | ');
      buffer.writeln(
        [
          _csv(request.group.name),
          _csv(
            AppDates.medium(expense.occurredAt, localeCode: request.localeCode),
          ),
          _csv(expense.title),
          _csv(names[expense.paidBy] ?? expense.paidBy),
          MoneyFormatter.majorUnits(
            expense.amountMinor,
            currency: expense.currency,
          ).toStringAsFixed(
            MoneyFormatter.decimalsFor(expense.currency) == 0 ? 0 : 2,
          ),
          expense.currency,
          expense.splitMode.name,
          _csv(participants),
          _csv(shares),
        ].join(','),
      );
    }
    buffer.writeln();
    buffer.writeln('member,net,paid,owed');
    for (final balance in request.summary.balances) {
      buffer.writeln(
        [
          _csv(names[balance.userId] ?? balance.userId),
          MoneyFormatter.majorUnits(
            balance.netMinor,
            currency: request.group.currency,
          ),
          MoneyFormatter.majorUnits(
            balance.paidMinor,
            currency: request.group.currency,
          ),
          MoneyFormatter.majorUnits(
            balance.owedMinor,
            currency: request.group.currency,
          ),
        ].join(','),
      );
    }
    buffer.writeln();
    buffer.writeln('settle_up_from,settle_up_to,amount');
    for (final transfer in request.summary.transfers) {
      buffer.writeln(
        [
          _csv(names[transfer.fromUserId] ?? transfer.fromUserId),
          _csv(names[transfer.toUserId] ?? transfer.toUserId),
          MoneyFormatter.majorUnits(
            transfer.amountMinor,
            currency: request.group.currency,
          ),
        ].join(','),
      );
    }
    await FileSaver.instance.saveFile(
      name: 'bagi-fair-${_slug(request.group.name)}',
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  @override
  Future<void> exportPdf(GroupExportRequest request) async {
    final names = {
      for (final member in request.members) member.userId: member.displayName,
    };
    final document = pw.Document();
    final currency = request.group.currency;
    final brand = PdfColor.fromHex('#0B8A60');
    final ink = PdfColor.fromHex('#10231C');
    final muted = PdfColor.fromHex('#5B7169');
    final line = PdfColor.fromHex('#DCE8E2');

    pw.TextStyle style({
      double size = 10,
      PdfColor? color,
      pw.FontWeight weight = pw.FontWeight.normal,
    }) {
      return pw.TextStyle(
        fontSize: size,
        color: color ?? ink,
        fontWeight: weight,
      );
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: line)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'BAGI FAIR',
                style: style(
                  size: 14,
                  color: brand,
                  weight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                AppDates.medium(DateTime.now(), localeCode: request.localeCode),
                style: style(size: 9, color: muted),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber}/${context.pagesCount} · Bagi adil, tanpa baper.',
            style: style(size: 8, color: muted),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Text(
            request.group.name,
            style: style(size: 24, weight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            request.group.description,
            style: style(size: 10, color: muted),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _box(
                'Total pengeluaran',
                MoneyFormatter.format(
                  request.summary.totalExpenseMinor,
                  currency: currency,
                  localeCode: request.localeCode,
                ),
                style,
                brand,
              ),
              pw.SizedBox(width: 10),
              _box('Anggota', '${request.members.length} orang', style, brand),
              pw.SizedBox(width: 10),
              _box(
                'Status',
                request.summary.isImpas ? 'Impas' : 'Ada sisa',
                style,
                brand,
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Ringkasan per orang',
            style: style(size: 13, weight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _table(
            headers: const ['Nama', 'Dibayar', 'Bagian', 'Status'],
            rows: [
              for (final balance in request.summary.balances)
                [
                  names[balance.userId] ?? balance.userId,
                  MoneyFormatter.format(
                    balance.paidMinor,
                    currency: currency,
                    localeCode: request.localeCode,
                  ),
                  MoneyFormatter.format(
                    balance.owedMinor,
                    currency: currency,
                    localeCode: request.localeCode,
                  ),
                  _statusLabel(balance, currency, request.localeCode),
                ],
            ],
            style: style,
            line: line,
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Cara paling simpel buat lunasin',
            style: style(size: 13, weight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (request.summary.transfers.isEmpty)
            pw.Text(
              'Semua sudah impas. Tidak ada transfer.',
              style: style(size: 10, color: muted),
            )
          else
            _table(
              headers: const ['Dari', 'Ke', 'Nominal'],
              rows: [
                for (final transfer in request.summary.transfers)
                  [
                    names[transfer.fromUserId] ?? transfer.fromUserId,
                    names[transfer.toUserId] ?? transfer.toUserId,
                    MoneyFormatter.format(
                      transfer.amountMinor,
                      currency: currency,
                      localeCode: request.localeCode,
                    ),
                  ],
              ],
              style: style,
              line: line,
            ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Pengeluaran',
            style: style(size: 13, weight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _table(
            headers: const [
              'Tanggal',
              'Judul',
              'Dibayar oleh',
              'Nominal',
              'Bagianmu',
            ],
            rows: [
              for (final expense in request.expenses)
                [
                  AppDates.short(
                    expense.occurredAt,
                    localeCode: request.localeCode,
                  ),
                  expense.title,
                  names[expense.paidBy] ?? expense.paidBy,
                  MoneyFormatter.format(
                    expense.amountMinor,
                    currency: expense.currency,
                    localeCode: request.localeCode,
                  ),
                  MoneyFormatter.format(
                    expense
                            .shareFor(request.currentUserId ?? '')
                            ?.amountMinor ??
                        0,
                    currency: currency,
                    localeCode: request.localeCode,
                  ),
                ],
            ],
            style: style,
            line: line,
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Dibuat ${AppDates.full(DateTime.now(), localeCode: request.localeCode)} · Bagi Fair',
            style: style(size: 8, color: muted),
          ),
        ],
      ),
    );

    final bytes = await document.save();
    await FileSaver.instance.saveFile(
      name: 'bagi-fair-${_slug(request.group.name)}',
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  String _statusLabel(MemberBalance balance, String currency, String locale) {
    if (balance.netMinor == 0) return 'Impas';
    if (balance.netMinor > 0) {
      return 'Ditagih ${MoneyFormatter.format(balance.netMinor, currency: currency, localeCode: locale)}';
    }
    return 'Utang ${MoneyFormatter.format(-balance.netMinor, currency: currency, localeCode: locale)}';
  }

  pw.Widget _box(
    String label,
    String value,
    pw.TextStyle Function({double size, PdfColor? color, pw.FontWeight weight})
    style,
    PdfColor brand,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F5F9F7'),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: style(size: 8, color: brand)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: style(size: 12, weight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required pw.TextStyle Function({
      double size,
      PdfColor? color,
      pw.FontWeight weight,
    })
    style,
    required PdfColor line,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: style(size: 9, weight: pw.FontWeight.bold),
      cellStyle: style(size: 9),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EAF2EE'),
        border: pw.Border(bottom: pw.BorderSide(color: line)),
      ),
      cellDecoration: (index, data, rowNumber) => pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: line, width: 0.4)),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      border: null,
    );
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'grup' : slug;
  }
}
