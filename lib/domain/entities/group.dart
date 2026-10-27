import 'package:equatable/equatable.dart';

enum GroupType { trip, kos, hangout, other }

enum GroupRole { owner, admin, member }

class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.emoji = '🍕',
    this.archived = false,
    this.memberCount = 1,
    this.myRole = GroupRole.member,
    this.isPending = false,
  });

  final String id;
  final String name;
  final String description;
  final String emoji;
  final GroupType type;
  final String currency;
  final String ownerId;
  final bool archived;
  final int memberCount;
  final GroupRole myRole;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPending;

  bool isOwner(String? userId) => userId != null && ownerId == userId;

  Group copyWith({
    String? name,
    String? description,
    String? emoji,
    GroupType? type,
    String? currency,
    bool? archived,
    int? memberCount,
    GroupRole? myRole,
    DateTime? updatedAt,
    bool? isPending,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      ownerId: ownerId,
      archived: archived ?? this.archived,
      memberCount: memberCount ?? this.memberCount,
      myRole: myRole ?? this.myRole,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPending: isPending ?? this.isPending,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'emoji': emoji,
    'type': type.name,
    'currency': currency,
    'owner_id': ownerId,
    'archived': archived,
    'member_count': memberCount,
    'my_role': myRole.name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
    if (isPending) 'is_pending': true,
  };

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Grup',
      description: (json['description'] as String?) ?? '',
      emoji: (json['emoji'] as String?) ?? '🍕',
      type: GroupType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => GroupType.other,
      ),
      currency: (json['currency'] as String?) ?? 'IDR',
      ownerId: (json['owner_id'] as String?) ?? '',
      archived: json['archived'] as bool? ?? false,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 1,
      myRole: GroupRole.values.firstWhere(
        (role) => role.name == json['my_role'],
        orElse: () => GroupRole.member,
      ),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
      isPending: json['is_pending'] as bool? ?? false,
    );
  }

  static DateTime _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    emoji,
    type,
    currency,
    ownerId,
    archived,
    memberCount,
    myRole,
    createdAt,
    updatedAt,
    isPending,
  ];
}

class GroupMember extends Equatable {
  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.email = '',
    this.avatarUrl,
    this.isPending = false,
  });

  final String id;
  final String groupId;
  final String userId;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final GroupRole role;
  final DateTime joinedAt;
  final bool isPending;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.length > 1
        ? parts.last.substring(0, 1).toUpperCase()
        : '';
    return '$first$last';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'user_id': userId,
    'display_name': displayName,
    'email': email,
    'avatar_url': avatarUrl,
    'role': role.name,
    'joined_at': joinedAt.toUtc().toIso8601String(),
    'updated_at': DateTime.now().toUtc().toIso8601String(),
    'deleted_at': null,
    if (isPending) 'is_pending': true,
  };

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: (json['id'] as String?) ?? '${json['group_id']}:${json['user_id']}',
      groupId: (json['group_id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      displayName: (json['display_name'] as String?)?.trim().isNotEmpty == true
          ? json['display_name'] as String
          : 'Teman',
      email: (json['email'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: GroupRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => GroupRole.member,
      ),
      joinedAt: _date(json['joined_at']),
      isPending: json['is_pending'] as bool? ?? false,
    );
  }

  static DateTime _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

  @override
  List<Object?> get props => [
    id,
    groupId,
    userId,
    displayName,
    email,
    avatarUrl,
    role,
    joinedAt,
    isPending,
  ];
}
