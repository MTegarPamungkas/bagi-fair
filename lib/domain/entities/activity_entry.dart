import 'package:bagi_fair/core/utils/enum_parsing.dart';
import 'package:equatable/equatable.dart';

enum ActivityKind {
  groupCreated,
  groupUpdated,
  memberJoined,
  memberRemoved,
  expenseAdded,
  expenseUpdated,
  expenseDeleted,
  settlementAdded,
  receiptScanned,
  nudgeSent,
}

class ActivityEntry extends Equatable {
  const ActivityEntry({
    required this.id,
    required this.groupId,
    required this.actorId,
    required this.actorName,
    required this.kind,
    required this.createdAt,
    this.summary = '',
    this.payload = const {},
    this.isPending = false,
  });

  final String id;
  final String groupId;
  final String actorId;
  final String actorName;
  final ActivityKind kind;
  final String summary;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final bool isPending;

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'actor_id': actorId,
    'actor_name': actorName,
    'kind': enumToSnake(kind),
    'summary': summary,
    'payload': payload,
    'created_at': createdAt.toUtc().toIso8601String(),
    if (isPending) 'is_pending': true,
  };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      id: json['id'] as String,
      groupId: (json['group_id'] as String?) ?? '',
      actorId: (json['actor_id'] as String?) ?? '',
      actorName: (json['actor_name'] as String?) ?? 'Teman',
      kind: parseEnum(
        ActivityKind.values,
        json['kind'],
        ActivityKind.groupUpdated,
      ),
      summary: (json['summary'] as String?) ?? '',
      payload: Map<String, dynamic>.from((json['payload'] as Map?) ?? const {}),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isPending: json['is_pending'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    actorId,
    actorName,
    kind,
    summary,
    payload,
    createdAt,
    isPending,
  ];
}
