import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:bagi_fair/domain/entities/sync_status.dart';

abstract interface class SyncRepository {
  SyncStatus get current;

  Stream<SyncStatus> watchStatus();

  Future<void> syncNow();

  Future<void> pullChanges();

  List<OutboxItem> pendingItems();

  Future<void> start();

  Future<void> dispose();
}
