import 'dart:convert';
import 'dart:typed_data';

import 'package:bagi_fair/data/datasources/cloud_gateway.dart';
import 'package:bagi_fair/domain/entities/receipt_scan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCloudGateway implements CloudGateway {
  SupabaseCloudGateway(this._client);

  final SupabaseClient _client;

  static const Map<String, String> _conflictColumns = {
    'group_members': 'group_id,user_id',
    'profiles': 'user_id',
  };

  static const Map<String, Set<String>> _localOnlyColumns = {
    'groups': {'my_role', 'is_pending', 'member_count'},
    'group_members': {'is_pending'},
    'expenses': {'is_pending'},
    'settlements': {'is_pending'},
    'activities': {'is_pending'},
    'receipts': {'is_pending'},
    'notifications': {'is_pending'},
    'profiles': {'id', 'is_pending'},
  };

  @override
  bool get isDemo => false;

  Map<String, dynamic> _clean(String table, Map<String, dynamic> row) {
    final clean = Map<String, dynamic>.from(row);
    for (final column in _localOnlyColumns[table] ?? const <String>{}) {
      clean.remove(column);
    }
    clean.remove('is_pending');
    return clean;
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> row) async {
    final clean = _clean(table, row);
    try {
      await _client
          .from(table)
          .upsert(clean, onConflict: _conflictColumns[table]);
    } on PostgrestException catch (error) {
      _rethrow(error);
    }
  }

  @override
  Future<void> insert(String table, Map<String, dynamic> row) async {
    final clean = _clean(table, row);
    try {
      // No `resolution` preference: a plain INSERT only evaluates the INSERT
      // policy. Upserting a notification for another member fails because the
      // sender cannot SELECT the conflict target.
      await _client.from(table).insert(clean);
    } on PostgrestException catch (error) {
      // Replaying an outbox insert must be idempotent.
      if (error.code == '23505') return;
      _rethrow(error);
    }
  }

  @override
  Future<void> patch(
    String table,
    String id,
    Map<String, dynamic> values,
  ) async {
    final clean = _clean(table, values)..remove('id');
    if (clean.isEmpty) return;
    try {
      await _client.from(table).update(clean).eq('id', id);
    } on PostgrestException catch (error) {
      _rethrow(error);
    }
  }

  Never _rethrow(PostgrestException error) {
    if (error.code == '42501') {
      throw CloudPermissionException(error.message);
    }
    throw error;
  }

  @override
  Future<void> softDelete(String table, String id, DateTime updatedAt) async {
    if (table == 'group_members') {
      await _client.from(table).delete().eq('id', id);
      return;
    }
    final timestamp = updatedAt.toUtc().toIso8601String();
    await _client
        .from(table)
        .update({'deleted_at': timestamp, 'updated_at': timestamp})
        .eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> pull(
    String table, {
    DateTime? since,
    int limit = 300,
  }) async {
    var query = _client.from(table).select();
    if (since != null) {
      query = query.gt('updated_at', since.toUtc().toIso8601String());
    }
    final rows = await query.order('updated_at').limit(limit);
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  @override
  Stream<void> watchChanges(List<String> tables) {
    return Stream.multi((controller) {
      final channel = _client.channel(
        'bagi-fair-sync-${DateTime.now().microsecondsSinceEpoch}',
      );
      for (final table in tables) {
        channel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        );
      }
      channel.subscribe();
      controller.onCancel = () async {
        await _client.removeChannel(channel);
      };
    });
  }

  @override
  Future<String> createInvite(String groupId, {int days = 7}) async {
    final code = await _client.rpc(
      'create_group_invite',
      params: {'p_group_id': groupId, 'p_days': days},
    );
    return code.toString();
  }

  @override
  Future<void> joinGroup(String code) async {
    await _client.rpc('join_group_by_code', params: {'p_code': code.trim()});
  }

  @override
  Future<ReceiptScan> scanReceipt({
    required Uint8List bytes,
    required String mimeType,
    required String groupId,
    required String localeCode,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'scan-receipt',
        body: {
          'image_base64': base64Encode(bytes),
          'mime_type': mimeType,
          'group_id': groupId,
          'locale': localeCode,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const CloudUnavailableException(
          'Respons scan tidak dikenali. Coba foto ulang atau input manual.',
        );
      }
      return ReceiptScan.fromJson(Map<String, dynamic>.from(data));
    } on FunctionException catch (error) {
      final details = error.details;
      if (error.status == 429) {
        final map = details is Map ? details : const {};
        final retry = (map['retry_after_seconds'] as num?)?.toInt() ?? 3600;
        throw AiRateLimitException(retryAfterSeconds: retry);
      }
      final map = details is Map ? details : const {};
      final message = map['error'] ?? map['message'];
      throw CloudUnavailableException(
        message?.toString() ?? 'Scan struk gagal. Coba lagi atau input manual.',
      );
    }
  }

  @override
  Future<String?> uploadReceipt({
    required String groupId,
    required String receiptId,
    required Uint8List bytes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final path = '$groupId/${user.id}/$receiptId.jpg';
    final storage = _client.storage.from('receipts');
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return storage.createSignedUrl(path, 60 * 60 * 24 * 7);
  }

  @override
  Future<void> setNotificationRead(String id, DateTime readAt) async {
    await _client
        .from('notifications')
        .update({'read_at': readAt.toUtc().toIso8601String()})
        .eq('id', id);
  }
}
