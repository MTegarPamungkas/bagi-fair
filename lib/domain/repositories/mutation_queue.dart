import 'package:bagi_fair/domain/entities/outbox_item.dart';

/// Anything repositories can use to persist a mutation even when offline.
abstract interface class MutationQueue {
  bool get isDemo;

  Future<void> enqueue({
    required String table,
    required String rowId,
    required OutboxOperation operation,
    required Map<String, dynamic> payload,
  });

  void requestSync();
}
