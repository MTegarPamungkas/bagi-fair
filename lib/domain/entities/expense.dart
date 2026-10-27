import 'package:equatable/equatable.dart';

enum SplitMode { equal, percentage, exact, itemized }

enum ExpenseCategory {
  food,
  transport,
  stay,
  groceries,
  utilities,
  fun,
  shopping,
  other,
}

class ExpenseItem extends Equatable {
  const ExpenseItem({
    required this.id,
    required this.name,
    required this.unitPriceMinor,
    required this.totalMinor,
    this.quantity = 1,
    this.memberIds = const [],
  });

  final String id;
  final String name;
  final int quantity;
  final int unitPriceMinor;
  final int totalMinor;
  final List<String> memberIds;

  ExpenseItem copyWith({
    String? name,
    int? quantity,
    int? unitPriceMinor,
    int? totalMinor,
    List<String>? memberIds,
  }) {
    return ExpenseItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit_price_minor': unitPriceMinor,
    'total_minor': totalMinor,
    'member_ids': memberIds,
  };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      id: (json['id'] as String?) ?? 'item',
      name: (json['name'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPriceMinor: (json['unit_price_minor'] as num?)?.toInt() ?? 0,
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      memberIds: ((json['member_ids'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    quantity,
    unitPriceMinor,
    totalMinor,
    memberIds,
  ];
}

class ExpenseShare extends Equatable {
  const ExpenseShare({
    required this.userId,
    required this.amountMinor,
    this.subtotalMinor = 0,
    this.taxShareMinor = 0,
    this.serviceShareMinor = 0,
    this.discountShareMinor = 0,
    this.adjustmentMinor = 0,
    this.weightBps = 0,
    this.itemIds = const [],
  });

  final String userId;

  /// Final share in the group's base currency.
  final int amountMinor;

  /// Item subtotal assigned to this person, in the group base currency.
  final int subtotalMinor;
  final int taxShareMinor;
  final int serviceShareMinor;
  final int discountShareMinor;
  final int adjustmentMinor;

  /// Basis points used for percentage splits (10000 = 100%).
  final int weightBps;
  final List<String> itemIds;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'amount_minor': amountMinor,
    'subtotal_minor': subtotalMinor,
    'tax_share_minor': taxShareMinor,
    'service_share_minor': serviceShareMinor,
    'discount_share_minor': discountShareMinor,
    'adjustment_minor': adjustmentMinor,
    'weight_bps': weightBps,
    'item_ids': itemIds,
  };

  factory ExpenseShare.fromJson(Map<String, dynamic> json) {
    return ExpenseShare(
      userId: (json['user_id'] as String?) ?? '',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      taxShareMinor: (json['tax_share_minor'] as num?)?.toInt() ?? 0,
      serviceShareMinor: (json['service_share_minor'] as num?)?.toInt() ?? 0,
      discountShareMinor: (json['discount_share_minor'] as num?)?.toInt() ?? 0,
      adjustmentMinor: (json['adjustment_minor'] as num?)?.toInt() ?? 0,
      weightBps: (json['weight_bps'] as num?)?.toInt() ?? 0,
      itemIds: ((json['item_ids'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [
    userId,
    amountMinor,
    subtotalMinor,
    taxShareMinor,
    serviceShareMinor,
    discountShareMinor,
    adjustmentMinor,
    weightBps,
    itemIds,
  ];
}

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amountMinor,
    required this.amountBaseMinor,
    required this.currency,
    required this.paidBy,
    required this.splitMode,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.category = ExpenseCategory.other,
    this.fxRate = 1,
    this.note = '',
    this.items = const [],
    this.shares = const [],
    this.taxMinor = 0,
    this.serviceMinor = 0,
    this.discountMinor = 0,
    this.receiptId,
    this.isPending = false,
  });

  final String id;
  final String groupId;
  final String title;
  final ExpenseCategory category;

  /// Total in [currency].
  final int amountMinor;

  /// Total converted to the group's base currency.
  final int amountBaseMinor;
  final String currency;

  /// 1 unit of [currency] equals this many units of the group currency.
  final double fxRate;
  final String paidBy;
  final SplitMode splitMode;
  final String note;
  final DateTime occurredAt;
  final List<ExpenseItem> items;
  final List<ExpenseShare> shares;
  final int taxMinor;
  final int serviceMinor;
  final int discountMinor;
  final String? receiptId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPending;

  bool get isItemized => splitMode == SplitMode.itemized;

  int get participantsCount => shares.length;

  ExpenseShare? shareFor(String userId) {
    for (final share in shares) {
      if (share.userId == userId) return share;
    }
    return null;
  }

  int get itemsSubtotalMinor =>
      items.fold(0, (total, item) => total + item.totalMinor);

  Expense copyWith({
    String? title,
    ExpenseCategory? category,
    int? amountMinor,
    int? amountBaseMinor,
    String? currency,
    double? fxRate,
    String? paidBy,
    SplitMode? splitMode,
    String? note,
    DateTime? occurredAt,
    List<ExpenseItem>? items,
    List<ExpenseShare>? shares,
    int? taxMinor,
    int? serviceMinor,
    int? discountMinor,
    String? receiptId,
    DateTime? updatedAt,
    bool? isPending,
  }) {
    return Expense(
      id: id,
      groupId: groupId,
      title: title ?? this.title,
      category: category ?? this.category,
      amountMinor: amountMinor ?? this.amountMinor,
      amountBaseMinor: amountBaseMinor ?? this.amountBaseMinor,
      currency: currency ?? this.currency,
      fxRate: fxRate ?? this.fxRate,
      paidBy: paidBy ?? this.paidBy,
      splitMode: splitMode ?? this.splitMode,
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      items: items ?? this.items,
      shares: shares ?? this.shares,
      taxMinor: taxMinor ?? this.taxMinor,
      serviceMinor: serviceMinor ?? this.serviceMinor,
      discountMinor: discountMinor ?? this.discountMinor,
      receiptId: receiptId ?? this.receiptId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPending: isPending ?? this.isPending,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'title': title,
    'category': category.name,
    'amount_minor': amountMinor,
    'amount_base_minor': amountBaseMinor,
    'currency': currency,
    'fx_rate': fxRate,
    'paid_by': paidBy,
    'split_mode': splitMode.name,
    'note': note,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'shares': shares.map((share) => share.toJson()).toList(growable: false),
    'tax_minor': taxMinor,
    'service_minor': serviceMinor,
    'discount_minor': discountMinor,
    'receipt_id': receiptId,
    'created_by': createdBy,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
    if (isPending) 'is_pending': true,
  };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      groupId: (json['group_id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Pengeluaran',
      category: ExpenseCategory.values.firstWhere(
        (category) => category.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      amountBaseMinor: (json['amount_base_minor'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] as String?) ?? 'IDR',
      fxRate: (json['fx_rate'] as num?)?.toDouble() ?? 1,
      paidBy: (json['paid_by'] as String?) ?? '',
      splitMode: SplitMode.values.firstWhere(
        (mode) => mode.name == json['split_mode'],
        orElse: () => SplitMode.equal,
      ),
      note: (json['note'] as String?) ?? '',
      occurredAt: _date(json['occurred_at']),
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => ExpenseItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      shares: ((json['shares'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (share) => ExpenseShare.fromJson(Map<String, dynamic>.from(share)),
          )
          .toList(growable: false),
      taxMinor: (json['tax_minor'] as num?)?.toInt() ?? 0,
      serviceMinor: (json['service_minor'] as num?)?.toInt() ?? 0,
      discountMinor: (json['discount_minor'] as num?)?.toInt() ?? 0,
      receiptId: json['receipt_id'] as String?,
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
    title,
    category,
    amountMinor,
    amountBaseMinor,
    currency,
    fxRate,
    paidBy,
    splitMode,
    note,
    occurredAt,
    items,
    shares,
    taxMinor,
    serviceMinor,
    discountMinor,
    receiptId,
    createdBy,
    createdAt,
    updatedAt,
    isPending,
  ];
}
