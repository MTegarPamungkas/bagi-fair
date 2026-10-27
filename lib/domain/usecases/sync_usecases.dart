import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:bagi_fair/domain/entities/sync_status.dart';
import 'package:bagi_fair/domain/repositories/sync_repository.dart';

class WatchSyncStatus {
  const WatchSyncStatus(this._repository);

  final SyncRepository _repository;

  Stream<SyncStatus> call() => _repository.watchStatus();
}

class GetSyncStatus {
  const GetSyncStatus(this._repository);

  final SyncRepository _repository;

  SyncStatus call() => _repository.current;
}

class SyncNow {
  const SyncNow(this._repository);

  final SyncRepository _repository;

  Future<void> call() => _repository.syncNow();
}

class GetPendingChanges {
  const GetPendingChanges(this._repository);

  final SyncRepository _repository;

  List<OutboxItem> call() => _repository.pendingItems();
}
