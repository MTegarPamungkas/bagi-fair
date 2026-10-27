import 'package:equatable/equatable.dart';

class Settlement extends Equatable {
  const Settlement({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
    required this.currency,
    required this.settledAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.note = '',
    this.isPending = false,
  });

  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final int amountMinor;
  final String currency;
  final String note;
  final DateTime settledAt;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPending;

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'from_user_id': fromUserId,
    'to_user_id': toUserId,
    'amount_minor': amountMinor,
    'currency': currency,
    'note': note,
    'settled_at': settledAt.toUtc().toIso8601String(),
    'created_by': createdBy,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
    if (isPending) 'is_pending': true,
  };

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as String,
      groupId: (json['group_id'] as String?) ?? '',
      fromUserId: (json['from_user_id'] as String?) ?? '',
      toUserId: (json['to_user_id'] as String?) ?? '',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'IDR',
      note: (json['note'] as String?) ?? '',
      settledAt: _date(json['settled_at']),
      createdBy: (json['created_by'] as String?) ?? '',
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
    groupId,
    fromUserId,
    toUserId,
    amountMinor,
    currency,
    note,
    settledAt,
    createdBy,
    createdAt,
    updatedAt,
    isPending,
  ];
}
