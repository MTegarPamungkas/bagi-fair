import 'dart:async';
import 'dart:convert';

import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/domain/entities/app_settings.dart';
import 'package:bagi_fair/domain/entities/user_profile.dart';
import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:bagi_fair/domain/repositories/mutation_queue.dart';
import 'package:bagi_fair/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._store) {
    final raw = _store.getMeta('settings');
    if (raw is Map) {
      _current = AppSettings.fromJson(Map<String, dynamic>.from(raw));
    } else if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _current = AppSettings.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Keep defaults when the stored blob is unreadable.
      }
    }
  }

  final LocalStore _store;
  final StreamController<AppSettings> _controller =
      StreamController<AppSettings>.broadcast();
  AppSettings _current = const AppSettings();

  @override
  AppSettings get current => _current;

  @override
  Stream<AppSettings> watch() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> save(AppSettings settings) async {
    _current = settings;
    await _store.setMeta('settings', settings.toJson());
    _controller.add(settings);
  }
}

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._store, this._queue);

  final LocalStore _store;
  final MutationQueue _queue;

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _store.watch('profiles').map((rows) {
      for (final row in rows) {
        if ((row['user_id'] ?? row['id']) == userId) {
          return UserProfile.fromJson(row);
        }
      }
      return null;
    });
  }

  @override
  Future<UserProfile?> getProfile(String userId) async {
    for (final row in _store.all('profiles')) {
      if ((row['user_id'] ?? row['id']) == userId) {
        return UserProfile.fromJson(row);
      }
    }
    return null;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final row = profile.toJson()..['id'] = profile.id;
    await _store.put('profiles', row, pending: !_queue.isDemo);
    await _queue.enqueue(
      table: 'profiles',
      rowId: profile.id,
      operation: OutboxOperation.upsert,
      payload: row,
    );
  }
}
