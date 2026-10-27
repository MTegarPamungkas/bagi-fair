import 'package:equatable/equatable.dart';

class GroupInvite extends Equatable {
  const GroupInvite({
    required this.code,
    required this.groupId,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
  });

  final String code;
  final String groupId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'code': code,
    'group_id': groupId,
    'created_by': createdBy,
    'created_at': createdAt.toUtc().toIso8601String(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
  };

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      code: (json['code'] as String?) ?? '',
      groupId: (json['group_id'] as String?) ?? '',
      createdBy: (json['created_by'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 7)),
    );
  }

  @override
  List<Object?> get props => [code, groupId, createdBy, createdAt, expiresAt];
}
