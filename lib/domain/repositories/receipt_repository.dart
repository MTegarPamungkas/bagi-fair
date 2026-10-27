import 'dart:typed_data';

import 'package:bagi_fair/domain/entities/receipt.dart';
import 'package:bagi_fair/domain/entities/receipt_scan.dart';

abstract interface class ReceiptRepository {
  Stream<List<Receipt>> watchReceipts(String groupId);

  Future<Receipt?> getReceipt(String receiptId);

  Future<void> saveReceipt(Receipt receipt);

  Future<ReceiptScan> scan({
    required Uint8List bytes,
    required String mimeType,
    required String groupId,
    required String localeCode,
  });

  Future<String?> uploadImage({
    required String groupId,
    required String receiptId,
    required Uint8List bytes,
  });
}
