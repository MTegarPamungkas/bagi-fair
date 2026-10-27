import 'package:equatable/equatable.dart';

enum ReceiptStatus { draft, reviewed, saved }

class ReceiptItem extends Equatable {
  const ReceiptItem({
    required this.id,
    required this.name,
    required this.unitPriceMinor,
    required this.totalMinor,
    this.quantity = 1,
  });

  final String id;
  final String name;
  final int quantity;
  final int unitPriceMinor;
  final int totalMinor;

  ReceiptItem copyWith({
    String? name,
    int? quantity,
    int? unitPriceMinor,
    int? totalMinor,
  }) {
    return ReceiptItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
      totalMinor: totalMinor ?? this.totalMinor,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit_price_minor': unitPriceMinor,
    'total_minor': totalMinor,
  };

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: (json['id'] as String?) ?? 'item',
      name: (json['name'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPriceMinor: (json['unit_price_minor'] as num?)?.toInt() ?? 0,
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, quantity, unitPriceMinor, totalMinor];
}

class Receipt extends Equatable {
  const Receipt({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.currency,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.merchant = '',
    this.items = const [],
    this.subtotalMinor = 0,
    this.taxMinor = 0,
    this.serviceMinor = 0,
    this.totalMinor = 0,
    this.rawText = '',
    this.imageUrl,
    this.status = ReceiptStatus.draft,
    this.isPending = false,
  });

  final String id;
  final String groupId;
  final String createdBy;
  final String merchant;
  final String currency;
  final List<ReceiptItem> items;
  final int subtotalMinor;
  final int taxMinor;
  final int serviceMinor;
  final int totalMinor;
  final String rawText;
  final String? imageUrl;
  final DateTime occurredAt;
  final ReceiptStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPending;

  Receipt copyWith({
    String? merchant,
    String? currency,
    List<ReceiptItem>? items,
    int? subtotalMinor,
    int? taxMinor,
    int? serviceMinor,
    int? totalMinor,
    String? rawText,
    String? imageUrl,
    DateTime? occurredAt,
    ReceiptStatus? status,
    DateTime? updatedAt,
    bool? isPending,
  }) {
    return Receipt(
      id: id,
      groupId: groupId,
      createdBy: createdBy,
      merchant: merchant ?? this.merchant,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      taxMinor: taxMinor ?? this.taxMinor,
      serviceMinor: serviceMinor ?? this.serviceMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      rawText: rawText ?? this.rawText,
      imageUrl: imageUrl ?? this.imageUrl,
      occurredAt: occurredAt ?? this.occurredAt,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPending: isPending ?? this.isPending,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'created_by': createdBy,
    'merchant': merchant,
    'currency': currency,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'subtotal_minor': subtotalMinor,
    'tax_minor': taxMinor,
    'service_minor': serviceMinor,
    'total_minor': totalMinor,
    'raw_text': rawText,
    'image_url': imageUrl,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'status': status.name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
    if (isPending) 'is_pending': true,
  };

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      groupId: (json['group_id'] as String?) ?? '',
      createdBy: (json['created_by'] as String?) ?? '',
      merchant: (json['merchant'] as String?) ?? '',
      currency: (json['currency'] as String?) ?? 'IDR',
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => ReceiptItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      taxMinor: (json['tax_minor'] as num?)?.toInt() ?? 0,
      serviceMinor: (json['service_minor'] as num?)?.toInt() ?? 0,
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      rawText: (json['raw_text'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      occurredAt: _date(json['occurred_at']),
      status: ReceiptStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ReceiptStatus.draft,
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
    groupId,
    createdBy,
    merchant,
    currency,
    items,
    subtotalMinor,
    taxMinor,
    serviceMinor,
    totalMinor,
    rawText,
    imageUrl,
    occurredAt,
    status,
    createdAt,
    updatedAt,
    isPending,
  ];
}
