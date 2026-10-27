import 'package:bagi_fair/core/utils/enum_parsing.dart';
import 'package:equatable/equatable.dart';

enum AppNotificationKind {
  nudge,
  expenseAdded,
  settlementAdded,
  memberJoined,
  reminder,
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.actorId,
    this.actorName = '',
    this.payload = const {},
    this.readAt,
    this.isPending = false,
  });

  final String id;
  final String userId;
  final String groupId;
  final String? actorId;
  final String actorName;
  final AppNotificationKind kind;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool isPending;

  bool get isUnread => readAt == null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'group_id': groupId,
    'actor_id': actorId,
    'actor_name': actorName,
    'kind': enumToSnake(kind),
    'title': title,
    'body': body,
    'payload': payload,
    'created_at': createdAt.toUtc().toIso8601String(),
    'read_at': readAt?.toUtc().toIso8601String(),
    if (isPending) 'is_pending': true,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: (json['user_id'] as String?) ?? '',
      groupId: (json['group_id'] as String?) ?? '',
      actorId: json['actor_id'] as String?,
      actorName: (json['actor_name'] as String?) ?? '',
      kind: parseEnum(
        AppNotificationKind.values,
        json['kind'],
        AppNotificationKind.reminder,
      ),
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      payload: Map<String, dynamic>.from((json['payload'] as Map?) ?? const {}),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      readAt: json['read_at'] == null
          ? null
          : DateTime.tryParse(json['read_at'].toString()),
      isPending: json['is_pending'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    groupId,
    actorId,
    actorName,
    kind,
    title,
    body,
    payload,
    createdAt,
    readAt,
    isPending,
  ];
}
