import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:bagi_fair/domain/repositories/mutation_queue.dart';

Future<void> logActivity(
  LocalStore store,
  MutationQueue queue, {
  required String id,
  required String groupId,
  required String actorId,
  required String actorName,
  required ActivityKind kind,
  required String summary,
  Map<String, dynamic> payload = const {},
  DateTime? createdAt,
}) async {
  final entry = ActivityEntry(
    id: id,
    groupId: groupId,
    actorId: actorId,
    actorName: actorName,
    kind: kind,
    summary: summary,
    payload: payload,
    createdAt: createdAt ?? DateTime.now(),
    isPending: !queue.isDemo,
  );
  final row = entry.toJson();
  await store.put('activities', row, pending: !queue.isDemo);
  await queue.enqueue(
    table: 'activities',
    rowId: id,
    operation: OutboxOperation.upsert,
    payload: row,
  );
}
