import 'package:equatable/equatable.dart';

enum OutboxOperation { insert, upsert, delete, patch }

class OutboxItem extends Equatable {
  const OutboxItem({
    required this.id,
    required this.table,
    required this.rowId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  final String id;
  final String table;
  final String rowId;
  final OutboxOperation operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;

  OutboxItem copyWith({int? attempts}) => OutboxItem(
    id: id,
    table: table,
    rowId: rowId,
    operation: operation,
    payload: payload,
    createdAt: createdAt,
    attempts: attempts ?? this.attempts,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'row_id': rowId,
    'operation': operation.name,
    'payload': payload,
    'created_at': createdAt.toUtc().toIso8601String(),
    'attempts': attempts,
  };

  factory OutboxItem.fromJson(Map<String, dynamic> json) {
    return OutboxItem(
      id: (json['id'] as String?) ?? '',
      table: (json['table'] as String?) ?? '',
      rowId: (json['row_id'] as String?) ?? '',
      operation: OutboxOperation.values.firstWhere(
        (op) => op.name == json['operation'],
        orElse: () => OutboxOperation.upsert,
      ),
      payload: Map<String, dynamic>.from((json['payload'] as Map?) ?? const {}),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    table,
    rowId,
    operation,
    payload,
    createdAt,
    attempts,
  ];
}
