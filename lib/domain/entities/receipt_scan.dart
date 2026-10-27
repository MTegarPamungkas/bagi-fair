import 'package:bagi_fair/domain/entities/receipt.dart';
import 'package:equatable/equatable.dart';

class ReceiptScan extends Equatable {
  const ReceiptScan({
    required this.merchant,
    required this.occurredAt,
    required this.currency,
    required this.items,
    required this.subtotalMinor,
    required this.taxMinor,
    required this.serviceMinor,
    required this.totalMinor,
    this.rawText = '',
    this.confidence,
  });

  final String merchant;
  final DateTime occurredAt;
  final String currency;
  final List<ReceiptItem> items;
  final int subtotalMinor;
  final int taxMinor;
  final int serviceMinor;
  final int totalMinor;
  final String rawText;
  final double? confidence;

  Map<String, dynamic> toJson() => {
    'merchant': merchant,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'currency': currency,
    'items': items.map((item) => item.toJson()).toList(growable: false),
    'subtotal_minor': subtotalMinor,
    'tax_minor': taxMinor,
    'service_minor': serviceMinor,
    'total_minor': totalMinor,
    'raw_text': rawText,
    'confidence': confidence,
  };

  factory ReceiptScan.fromJson(Map<String, dynamic> json) {
    final currency = (json['currency'] as String?) ?? 'IDR';
    final rawItems = ((json['items'] as List?) ?? const [])
        .whereType<Map>()
        .toList(growable: false);
    final items = <ReceiptItem>[
      for (var index = 0; index < rawItems.length; index++)
        _itemFromJson(Map<String, dynamic>.from(rawItems[index]), index),
    ];

    return ReceiptScan(
      merchant: (json['merchant'] as String?) ?? '',
      occurredAt:
          DateTime.tryParse(json['occurred_at']?.toString() ?? '') ??
          DateTime.now(),
      currency: currency,
      items: items,
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      taxMinor: (json['tax_minor'] as num?)?.toInt() ?? 0,
      serviceMinor: (json['service_minor'] as num?)?.toInt() ?? 0,
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      rawText: (json['raw_text'] as String?) ?? '',
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  static ReceiptItem _itemFromJson(Map<String, dynamic> row, int index) {
    final quantity = (row['quantity'] as num?)?.toInt() ?? 1;
    final total = (row['total_minor'] as num?)?.toInt() ?? 0;
    final unit =
        (row['unit_price_minor'] as num?)?.toInt() ??
        (quantity == 0 ? total : total ~/ quantity);
    return ReceiptItem(
      id: (row['id'] as String?) ?? 'item_$index',
      name: (row['name'] as String?) ?? 'Item',
      quantity: quantity,
      unitPriceMinor: unit,
      totalMinor: total,
    );
  }

  @override
  List<Object?> get props => [
    merchant,
    occurredAt,
    currency,
    items,
    subtotalMinor,
    taxMinor,
    serviceMinor,
    totalMinor,
    rawText,
    confidence,
  ];
}
