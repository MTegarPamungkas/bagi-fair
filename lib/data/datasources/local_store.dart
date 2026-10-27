import 'dart:async';
import 'dart:convert';

import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Local source of truth and offline outbox.
///
/// Every repository reads from here first. Server pulls write through the same
/// boxes, so realtime changes and local edits share one observable cache.
class LocalStore {
  static const List<String> dataTables = [
    'profiles',
    'groups',
    'group_members',
    'group_invites',
    'expenses',
    'settlements',
    'activities',
    'receipts',
    'notifications',
  ];

  static const String ownerMetaKey = 'local_owner_id';

  final Map<String, Box<String>> _boxes = {};
  late Box<dynamic> _meta;
  late Box<String> _outbox;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init({String? directory, String name = 'bagi_fair'}) async {
    if (_initialized) return;
    if (directory == null) {
      await Hive.initFlutter(name);
    } else {
      Hive.init(directory);
    }

    _meta = await Hive.openBox<dynamic>('fair_meta');
    for (final table in dataTables) {
      _boxes[table] = await Hive.openBox<String>('fair_$table');
    }
    _outbox = await Hive.openBox<String>('fair_outbox');
    _initialized = true;
  }

  Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }

  Box<String> _box(String table) {
    final box = _boxes[table];
    if (box == null) {
      throw StateError('Unknown local table: $table');
    }
    return box;
  }

  Map<String, dynamic>? get(String table, String id) {
    final raw = _box(table).get(id);
    if (raw == null) return null;
    return _decode(raw);
  }

  List<Map<String, dynamic>> all(String table) {
    final result = <Map<String, dynamic>>[];
    for (final raw in _box(table).values) {
      final decoded = _decode(raw);
      if (decoded != null) result.add(decoded);
    }
    return result;
  }

  Stream<List<Map<String, dynamic>>> watch(String table) {
    final box = _box(table);

    List<Map<String, dynamic>> read() {
      final result = <Map<String, dynamic>>[];
      for (final raw in box.values) {
        final decoded = _decode(raw);
        if (decoded != null) result.add(decoded);
      }
      return result;
    }

    return Stream.multi((controller) {
      controller.add(read());
      final subscription = box.watch().listen((_) => controller.add(read()));
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> put(
    String table,
    Map<String, dynamic> row, {
    bool pending = false,
  }) async {
    final payload = Map<String, dynamic>.from(row);
    if (pending) {
      payload['is_pending'] = true;
    } else {
      payload.remove('is_pending');
    }
    await _box(table).put(row['id'] as String, jsonEncode(payload));
  }

  Future<void> putMany(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final box = _box(table);
    final entries = <String, String>{};
    for (final row in rows) {
      final id = row['id']?.toString() ?? row['code']?.toString();
      if (id == null) continue;
      entries[id] = jsonEncode(row);
    }
    if (entries.isNotEmpty) await box.putAll(entries);
  }

  Future<void> delete(String table, String id) => _box(table).delete(id);

  Future<void> clearTable(String table) => _box(table).clear();

  Future<void> clearAllData() async {
    for (final table in dataTables) {
      await _box(table).clear();
    }
    await _outbox.clear();
    await _meta.clear();
  }

  /// Starts a fresh local scope for [userId], keeping device preferences.
  Future<void> ensureUserScope(String userId, {bool force = false}) async {
    final owner = getMeta(ownerMetaKey);
    if (owner == userId && !force) return;
    if (owner != null || force) {
      await clearUserData();
    }
    await setMeta(ownerMetaKey, userId);
  }

  Future<void> clearUserData() async {
    for (final table in dataTables) {
      await _box(table).clear();
    }
    await _outbox.clear();

    final keys = _meta.keys.map((key) => key.toString()).toList();
    for (final key in keys) {
      if (key.startsWith('sync_cursor_') ||
          key.startsWith('demo_') ||
          key == ownerMetaKey) {
        await _meta.delete(key);
      }
    }
  }

  dynamic getMeta(String key) => _meta.get(key);

  Future<void> setMeta(String key, Object? value) => _meta.put(key, value);

  Future<void> removeMeta(String key) => _meta.delete(key);

  // -------------------------------------------------------------------------
  // Outbox
  // -------------------------------------------------------------------------

  Future<void> enqueue(OutboxItem item) =>
      _outbox.put(item.id, jsonEncode(item.toJson()));

  Future<void> enqueueAll(List<OutboxItem> items) async {
    if (items.isEmpty) return;
    await _outbox.putAll({
      for (final item in items) item.id: jsonEncode(item.toJson()),
    });
  }

  List<OutboxItem> outboxItems() {
    final result = <OutboxItem>[];
    for (final raw in _outbox.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          result.add(OutboxItem.fromJson(decoded));
        }
      } catch (_) {
        // Ignore a corrupt queue row; it must never block the app.
      }
    }
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  Set<String> pendingRowIds() => {for (final item in outboxItems()) item.rowId};

  Future<void> removeOutbox(String id) => _outbox.delete(id);

  Stream<int> watchOutboxCount() {
    return Stream.multi((controller) {
      controller.add(_outbox.length);
      final subscription = _outbox.watch().listen((_) {
        controller.add(_outbox.length);
      });
      controller.onCancel = subscription.cancel;
    });
  }

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
