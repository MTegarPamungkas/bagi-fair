import 'dart:typed_data';

import 'package:bagi_fair/domain/entities/receipt_scan.dart';

class CloudUnavailableException implements Exception {
  const CloudUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AiRateLimitException implements Exception {
  const AiRateLimitException({required this.retryAfterSeconds});

  final int retryAfterSeconds;

  @override
  String toString() => 'AI quota reached; retry in $retryAfterSeconds seconds';
}

/// The server rejected a write because of a row-level security policy.
///
/// Modelled separately from a network error so the sync engine can decide
/// whether an operation should be retried as an update (for example, marking
/// someone else's notification as read).
class CloudPermissionException implements Exception {
  const CloudPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class CloudGateway {
  bool get isDemo;

  Future<void> upsert(String table, Map<String, dynamic> row);

  /// Inserts a new row without an upsert.
  ///
  /// Required for rows the caller must not be able to read back (for example a
  /// notification addressed to another member): PostgREST's upsert needs
  /// SELECT access to the conflict target, while a plain INSERT only needs the
  /// INSERT policy.
  Future<void> insert(String table, Map<String, dynamic> row);

  /// Updates only the supplied columns of an existing row.
  Future<void> patch(String table, String id, Map<String, dynamic> values);

  Future<void> softDelete(String table, String id, DateTime updatedAt);

  Future<List<Map<String, dynamic>>> pull(
    String table, {
    DateTime? since,
    int limit = 300,
  });

  Stream<void> watchChanges(List<String> tables);

  Future<String> createInvite(String groupId, {int days = 7});

  Future<void> joinGroup(String code);

  Future<ReceiptScan> scanReceipt({
    required Uint8List bytes,
    required String mimeType,
    required String groupId,
    required String localeCode,
  });

  Future<String?> uploadReceipt({
    required String groupId,
    required String receiptId,
    required Uint8List bytes,
  });

  Future<void> setNotificationRead(String id, DateTime readAt);
}
