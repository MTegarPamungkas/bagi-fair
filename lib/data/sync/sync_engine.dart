import 'dart:async';

import 'package:bagi_fair/data/datasources/cloud_gateway.dart';
import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:bagi_fair/domain/entities/sync_status.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/repositories/mutation_queue.dart';
import 'package:bagi_fair/domain/repositories/sync_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

class SyncEngine implements SyncRepository, MutationQueue {
  SyncEngine({
    required this._store,
    required this._gateway,
    required this._auth,
    required this._connectivity,
    this._uuid = const Uuid(),
  });

  final LocalStore _store;
  final CloudGateway _gateway;
  final AuthRepository _auth;
  final Connectivity _connectivity;
  final Uuid _uuid;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  static const List<String> syncTables = [
    'groups',
    'group_members',
    'expenses',
    'settlements',
    'activities',
    'receipts',
    'notifications',
    'profiles',
  ];

  SyncStatus _status = const SyncStatus();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<int>? _pendingSubscription;
  StreamSubscription<void>? _changeSubscription;
  Timer? _syncDebounce;
  Timer? _pullDebounce;
  bool _online = true;
  bool _running = false;
  bool _started = false;

  @override
  bool get isDemo => _gateway.isDemo;

  @override
  SyncStatus get current => _status;

  @override
  Stream<SyncStatus> watchStatus() async* {
    yield _status;
    yield* _statusController.stream;
  }

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;

    _pendingSubscription = _store.watchOutboxCount().listen((count) {
      if (_gateway.isDemo) return;
      _setStatus(_status.copyWith(pendingCount: count));
    });

    try {
      final results = await _connectivity.checkConnectivity();
      _online = !_isOffline(results);
    } catch (_) {
      _online = true;
    }

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final wasOnline = _online;
      _online = !_isOffline(results);
      if (!_online) {
        _setStatus(
          _status.copyWith(
            phase: SyncPhase.offline,
            message: 'Offline — perubahan masuk antrean.',
          ),
        );
      } else if (!wasOnline) {
        requestSync();
      }
    });

    _authSubscription = _auth.watchUser().listen((user) {
      if (user == null) {
        _setStatus(
          _gateway.isDemo
              ? SyncStatus.demo
              : _status.copyWith(phase: SyncPhase.offline),
        );
      } else {
        requestSync();
      }
    });

    if (_gateway.isDemo) {
      _setStatus(SyncStatus.demo);
      return;
    }

    _changeSubscription = _gateway
        .watchChanges(syncTables)
        .listen((_) => _schedulePull());

    if (_auth.currentUser == null) {
      _setStatus(_status.copyWith(phase: SyncPhase.offline));
      return;
    }
    if (_online) {
      requestSync();
    } else {
      _setStatus(_status.copyWith(phase: SyncPhase.offline));
    }
  }

  void _setStatus(SyncStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  @override
  void requestSync() {
    if (_gateway.isDemo) {
      _setStatus(SyncStatus.demo);
      return;
    }
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 600), syncNow);
  }

  void _schedulePull() {
    if (_gateway.isDemo) return;
    _pullDebounce?.cancel();
    _pullDebounce = Timer(
      const Duration(milliseconds: 350),
      () => pullChanges(),
    );
  }

  @override
  Future<void> syncNow() async {
    if (_gateway.isDemo) {
      _setStatus(SyncStatus.demo);
      return;
    }
    if (_running) return;
    if (!_online) {
      _setStatus(_status.copyWith(phase: SyncPhase.offline));
      return;
    }
    if (_auth.currentUser == null) return;

    _running = true;
    _setStatus(_status.copyWith(phase: SyncPhase.syncing, clearMessage: true));
    try {
      final pushed = await _pushOutbox();
      if (!pushed) {
        // Keep the concrete error from _pushOutbox visible. Previously this
        // was overwritten with "idle" and the pending row looked synced.
        return;
      }
      await pullChanges();
      if (_status.phase == SyncPhase.error) return;
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.idle,
          lastSyncedAt: DateTime.now(),
          pendingCount: _store.outboxItems().length,
          clearMessage: true,
        ),
      );
    } catch (error) {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.error,
          message: 'Sinkronisasi tertunda: $error',
          pendingCount: _store.outboxItems().length,
        ),
      );
    } finally {
      _running = false;
    }
  }

  Future<bool> _pushOutbox() async {
    final items = _store.outboxItems();
    for (final item in items) {
      try {
        await _applyOutboxItem(item);
        await _store.removeOutbox(item.id);
      } catch (error) {
        _setStatus(
          _status.copyWith(
            phase: SyncPhase.error,
            message: error is CloudPermissionException
                ? 'Akses data ditolak oleh server. Coba sinkronkan lagi.'
                : error.toString(),
            pendingCount: _store.outboxItems().length,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _applyOutboxItem(OutboxItem item) async {
    switch (item.operation) {
      case OutboxOperation.delete:
        await _gateway.softDelete(item.table, item.rowId, DateTime.now());
      case OutboxOperation.patch:
        await _gateway.patch(item.table, item.rowId, item.payload);
        await _markLocalSynced(item, item.payload);
      case OutboxOperation.insert:
        await _gateway.insert(item.table, item.payload);
        await _markLocalSynced(item, item.payload);
      case OutboxOperation.upsert:
        try {
          await _gateway.upsert(item.table, item.payload);
          await _markLocalSynced(item, item.payload);
        } on CloudPermissionException {
          // Older builds queued "mark notification read" as an upsert. An
          // upsert re-runs the INSERT policy, which fails when the notification
          // belongs to us but was authored by a friend (actor_id != auth.uid()).
          // Downgrade that queue item to a column update on our own row.
          if (_canDowngradeToReadPatch(item)) {
            final values = <String, dynamic>{
              'read_at': item.payload['read_at'],
            };
            await _gateway.patch(item.table, item.rowId, values);
            await _markLocalSynced(item, values);
            return;
          }
          // Older builds also queued outbound notifications as upserts. The
          // sender cannot SELECT the row addressed to a friend, so retry it as
          // a plain insert (idempotent on a duplicate id).
          if (_canDowngradeToInsert(item)) {
            await _gateway.insert(item.table, item.payload);
            await _markLocalSynced(item, item.payload);
            return;
          }
          rethrow;
        }
    }
  }

  bool _canDowngradeToReadPatch(OutboxItem item) {
    return item.table == 'notifications' &&
        item.payload['user_id'] == _auth.currentUser?.id &&
        item.payload['read_at'] != null;
  }

  bool _canDowngradeToInsert(OutboxItem item) {
    return item.table == 'notifications' &&
        item.payload['user_id'] != _auth.currentUser?.id;
  }

  Future<void> _markLocalSynced(
    OutboxItem item,
    Map<String, dynamic> values,
  ) async {
    final local = _store.get(item.table, item.rowId);
    if (local == null) return;
    await _store.put(item.table, {...local, ...values}, pending: false);
  }

  @override
  Future<void> pullChanges() async {
    if (_gateway.isDemo || !_online || _auth.currentUser == null) return;

    final pending = _store.pendingRowIds();
    try {
      for (final table in syncTables) {
        final cursorRaw = _store.getMeta('sync_cursor_$table');
        DateTime? cursor = cursorRaw is String
            ? DateTime.tryParse(cursorRaw)
            : null;

        while (true) {
          final rows = await _gateway.pull(table, since: cursor, limit: 300);
          if (rows.isEmpty) break;

          DateTime? newest = cursor;
          for (final row in rows) {
            final id = row['id']?.toString();
            if (id == null) continue;
            final updated = DateTime.tryParse(
              row['updated_at']?.toString() ?? '',
            );
            if (updated != null &&
                (newest == null || updated.isAfter(newest))) {
              newest = updated;
            }
            if (pending.contains(id)) continue;
            if (row['deleted_at'] != null) {
              await _store.delete(table, id);
              continue;
            }
            if (table == 'profiles' && row['user_id'] != null) {
              row['id'] = row['user_id'];
            }
            await _store.put(table, row);
          }

          if (newest != null) {
            await _store.setMeta(
              'sync_cursor_$table',
              newest.toUtc().toIso8601String(),
            );
            if (cursor != null && !newest.isAfter(cursor)) break;
            cursor = newest;
          }
          if (rows.length < 300) break;
        }
      }
    } catch (error) {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.error,
          message: 'Gagal memuat perubahan: $error',
        ),
      );
    }
  }

  @override
  Future<void> enqueue({
    required String table,
    required String rowId,
    required OutboxOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    if (_gateway.isDemo) return;
    final item = OutboxItem(
      id: _uuid.v4(),
      table: table,
      rowId: rowId,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _store.enqueue(item);
    _setStatus(_status.copyWith(pendingCount: _store.outboxItems().length));
    requestSync();
  }

  @override
  List<OutboxItem> pendingItems() => _store.outboxItems();

  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
  }

  @override
  Future<void> dispose() async {
    _syncDebounce?.cancel();
    _pullDebounce?.cancel();
    await _connectivitySubscription?.cancel();
    await _authSubscription?.cancel();
    await _pendingSubscription?.cancel();
    await _changeSubscription?.cancel();
    await _statusController.close();
  }
}
