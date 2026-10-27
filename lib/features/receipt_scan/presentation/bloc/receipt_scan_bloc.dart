import 'dart:typed_data';

import 'package:bagi_fair/data/datasources/cloud_gateway.dart';
import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/receipt.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/usecases/expense_usecases.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class ReceiptScanState extends Equatable {
  const ReceiptScanState({
    this.loading = true,
    this.group,
    this.imageBytes,
    this.imageMimeType,
    this.scanning = false,
    this.manual = false,
    this.scanErrorCode,
    this.merchant = '',
    this.currency = 'IDR',
    this.items = const [],
    this.subtotalMinor = 0,
    this.taxMinor = 0,
    this.serviceMinor = 0,
    this.totalMinor = 0,
    this.occurredAt,
    this.rawText = '',
    this.confidence,
    this.saving = false,
    this.saved = false,
    this.receiptId,
    this.errorCode,
  });

  final bool loading;
  final Group? group;
  final Uint8List? imageBytes;
  final String? imageMimeType;
  final bool scanning;
  final bool manual;
  final String? scanErrorCode;
  final String merchant;
  final String currency;
  final List<ReceiptItem> items;
  final int subtotalMinor;
  final int taxMinor;
  final int serviceMinor;
  final int totalMinor;
  final DateTime? occurredAt;
  final String rawText;
  final double? confidence;
  final bool saving;
  final bool saved;
  final String? receiptId;
  final String? errorCode;

  bool get hasDraft =>
      merchant.trim().isNotEmpty || items.isNotEmpty || totalMinor > 0;

  DateTime get effectiveDate => occurredAt ?? DateTime.now();

  int get computedSubtotal =>
      items.fold(0, (total, item) => total + item.totalMinor);

  int get computedTotal => computedSubtotal + taxMinor + serviceMinor;

  ReceiptScanState copyWith({
    bool? loading,
    Group? group,
    Uint8List? imageBytes,
    String? imageMimeType,
    bool? scanning,
    bool? manual,
    String? scanErrorCode,
    String? merchant,
    String? currency,
    List<ReceiptItem>? items,
    int? subtotalMinor,
    int? taxMinor,
    int? serviceMinor,
    int? totalMinor,
    DateTime? occurredAt,
    String? rawText,
    double? confidence,
    bool? saving,
    bool? saved,
    String? receiptId,
    String? errorCode,
    bool clearScanError = false,
    bool clearError = false,
  }) {
    return ReceiptScanState(
      loading: loading ?? this.loading,
      group: group ?? this.group,
      imageBytes: imageBytes ?? this.imageBytes,
      imageMimeType: imageMimeType ?? this.imageMimeType,
      scanning: scanning ?? this.scanning,
      manual: manual ?? this.manual,
      scanErrorCode: clearScanError
          ? null
          : (scanErrorCode ?? this.scanErrorCode),
      merchant: merchant ?? this.merchant,
      currency: currency ?? this.currency,
      items: items ?? this.items,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      taxMinor: taxMinor ?? this.taxMinor,
      serviceMinor: serviceMinor ?? this.serviceMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      occurredAt: occurredAt ?? this.occurredAt,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      receiptId: receiptId ?? this.receiptId,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    group,
    imageBytes,
    imageMimeType,
    scanning,
    manual,
    scanErrorCode,
    merchant,
    currency,
    items,
    subtotalMinor,
    taxMinor,
    serviceMinor,
    totalMinor,
    occurredAt,
    rawText,
    confidence,
    saving,
    saved,
    receiptId,
    errorCode,
  ];
}

sealed class ReceiptScanEvent extends Equatable {
  const ReceiptScanEvent();

  @override
  List<Object?> get props => const [];
}

class ReceiptScanStarted extends ReceiptScanEvent {
  const ReceiptScanStarted(this.groupId);

  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

class ReceiptScanImageSelected extends ReceiptScanEvent {
  const ReceiptScanImageSelected({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;

  @override
  List<Object?> get props => [bytes, mimeType];
}

class ReceiptScanSampleRequested extends ReceiptScanEvent {
  const ReceiptScanSampleRequested();
}

class ReceiptScanManualRequested extends ReceiptScanEvent {
  const ReceiptScanManualRequested();
}

class ReceiptScanMerchantChanged extends ReceiptScanEvent {
  const ReceiptScanMerchantChanged(this.merchant);

  final String merchant;

  @override
  List<Object?> get props => [merchant];
}

class ReceiptScanCurrencyChanged extends ReceiptScanEvent {
  const ReceiptScanCurrencyChanged(this.currency);

  final String currency;

  @override
  List<Object?> get props => [currency];
}

class ReceiptScanItemAdded extends ReceiptScanEvent {
  const ReceiptScanItemAdded();
}

class ReceiptScanItemUpdated extends ReceiptScanEvent {
  const ReceiptScanItemUpdated(this.item);

  final ReceiptItem item;

  @override
  List<Object?> get props => [item];
}

class ReceiptScanItemRemoved extends ReceiptScanEvent {
  const ReceiptScanItemRemoved(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

class ReceiptScanTaxChanged extends ReceiptScanEvent {
  const ReceiptScanTaxChanged(this.minor);

  final int minor;

  @override
  List<Object?> get props => [minor];
}

class ReceiptScanServiceChanged extends ReceiptScanEvent {
  const ReceiptScanServiceChanged(this.minor);

  final int minor;

  @override
  List<Object?> get props => [minor];
}

class ReceiptScanTotalChanged extends ReceiptScanEvent {
  const ReceiptScanTotalChanged(this.minor);

  final int minor;

  @override
  List<Object?> get props => [minor];
}

class ReceiptScanDateChanged extends ReceiptScanEvent {
  const ReceiptScanDateChanged(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class ReceiptScanSubmitted extends ReceiptScanEvent {
  const ReceiptScanSubmitted();
}

class ReceiptScanCleared extends ReceiptScanEvent {
  const ReceiptScanCleared();
}

class ReceiptScanBloc extends Bloc<ReceiptScanEvent, ReceiptScanState> {
  ReceiptScanBloc({
    required this._getGroup,
    required this._scanReceipt,
    required this._saveReceipt,
    required this._uploadImage,
    required this._logActivity,
    required this._auth,
    this._uuid = const Uuid(),
  }) : super(const ReceiptScanState()) {
    on<ReceiptScanStarted>(_onStarted);
    on<ReceiptScanImageSelected>(_onImageSelected);
    on<ReceiptScanSampleRequested>(_onSample);
    on<ReceiptScanManualRequested>(_onManual);
    on<ReceiptScanMerchantChanged>(_onMerchant);
    on<ReceiptScanCurrencyChanged>(_onCurrency);
    on<ReceiptScanItemAdded>(_onItemAdded);
    on<ReceiptScanItemUpdated>(_onItemUpdated);
    on<ReceiptScanItemRemoved>(_onItemRemoved);
    on<ReceiptScanTaxChanged>(_onTax);
    on<ReceiptScanServiceChanged>(_onService);
    on<ReceiptScanTotalChanged>(_onTotal);
    on<ReceiptScanDateChanged>(_onDate);
    on<ReceiptScanSubmitted>(_onSubmitted);
    on<ReceiptScanCleared>(_onCleared);
  }

  final GetGroup _getGroup;
  final ScanReceipt _scanReceipt;
  final SaveReceipt _saveReceipt;
  final UploadReceiptImage _uploadImage;
  final LogActivity _logActivity;
  final AuthRepository _auth;
  final Uuid _uuid;

  Future<void> _onStarted(
    ReceiptScanStarted event,
    Emitter<ReceiptScanState> emit,
  ) async {
    final group = await _getGroup(event.groupId);
    emit(
      state.copyWith(
        loading: false,
        group: group,
        currency: group?.currency ?? 'IDR',
        occurredAt: DateTime.now(),
        clearError: true,
        clearScanError: true,
      ),
    );
  }

  Future<void> _onImageSelected(
    ReceiptScanImageSelected event,
    Emitter<ReceiptScanState> emit,
  ) async {
    final group = state.group;
    if (group == null) return;
    emit(
      state.copyWith(
        imageBytes: event.bytes,
        imageMimeType: event.mimeType,
        scanning: true,
        manual: false,
        clearScanError: true,
        clearError: true,
      ),
    );
    try {
      final scan = await _scanReceipt(
        bytes: event.bytes,
        mimeType: event.mimeType,
        groupId: group.id,
        localeCode: 'id',
      );
      emit(
        state.copyWith(
          scanning: false,
          merchant: scan.merchant,
          currency: scan.currency,
          items: scan.items,
          subtotalMinor: scan.subtotalMinor,
          taxMinor: scan.taxMinor,
          serviceMinor: scan.serviceMinor,
          totalMinor: scan.totalMinor,
          occurredAt: scan.occurredAt,
          rawText: scan.rawText,
          confidence: scan.confidence,
          manual: true,
          clearScanError: true,
        ),
      );
    } on AiRateLimitException {
      emit(
        state.copyWith(
          scanning: false,
          manual: true,
          scanErrorCode: 'rate_limited',
        ),
      );
    } on CloudUnavailableException catch (error) {
      // The Edge Function returns a machine code when its AI provider is not
      // configured. Say so plainly instead of blaming the user's connection.
      final notConfigured = error.message.contains('ai_not_configured');
      emit(
        state.copyWith(
          scanning: false,
          manual: true,
          scanErrorCode: notConfigured
              ? 'ai_not_configured'
              : 'cloud_unavailable',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          scanning: false,
          manual: true,
          scanErrorCode: 'scan_failed',
        ),
      );
    }
  }

  void _onSample(
    ReceiptScanSampleRequested event,
    Emitter<ReceiptScanState> emit,
  ) {
    const items = [
      ReceiptItem(
        id: 'sample_1',
        name: 'Nasi goreng spesial',
        quantity: 2,
        unitPriceMinor: 45000,
        totalMinor: 90000,
      ),
      ReceiptItem(
        id: 'sample_2',
        name: 'Es teh manis',
        quantity: 3,
        unitPriceMinor: 12000,
        totalMinor: 36000,
      ),
      ReceiptItem(
        id: 'sample_3',
        name: 'Pisang goreng',
        quantity: 1,
        unitPriceMinor: 24000,
        totalMinor: 24000,
      ),
    ];
    const subtotal = 150000;
    const tax = 15000;
    const service = 7500;
    emit(
      state.copyWith(
        merchant: 'Warung Senja',
        currency: state.group?.currency ?? 'IDR',
        items: items,
        subtotalMinor: subtotal,
        taxMinor: tax,
        serviceMinor: service,
        totalMinor: subtotal + tax + service,
        occurredAt: state.occurredAt ?? DateTime.now(),
        confidence: 0.98,
        manual: true,
        clearScanError: true,
        clearError: true,
      ),
    );
  }

  void _onManual(
    ReceiptScanManualRequested event,
    Emitter<ReceiptScanState> emit,
  ) {
    final items = state.items.isEmpty
        ? [
            ReceiptItem(
              id: _uuid.v4(),
              name: '',
              unitPriceMinor: 0,
              totalMinor: 0,
            ),
          ]
        : state.items;
    emit(
      state.copyWith(
        manual: true,
        items: items,
        occurredAt: state.occurredAt ?? DateTime.now(),
        clearScanError: true,
        clearError: true,
      ),
    );
  }

  void _onMerchant(
    ReceiptScanMerchantChanged event,
    Emitter<ReceiptScanState> emit,
  ) {
    emit(state.copyWith(merchant: event.merchant, clearError: true));
  }

  void _onCurrency(
    ReceiptScanCurrencyChanged event,
    Emitter<ReceiptScanState> emit,
  ) {
    emit(state.copyWith(currency: event.currency, clearError: true));
  }

  void _onItemAdded(
    ReceiptScanItemAdded event,
    Emitter<ReceiptScanState> emit,
  ) {
    final items = [
      ...state.items,
      ReceiptItem(id: _uuid.v4(), name: '', unitPriceMinor: 0, totalMinor: 0),
    ];
    emit(_withItems(state, emit, items));
  }

  void _onItemUpdated(
    ReceiptScanItemUpdated event,
    Emitter<ReceiptScanState> emit,
  ) {
    final items = state.items
        .map((item) => item.id == event.item.id ? event.item : item)
        .toList(growable: false);
    emit(_withItems(state, emit, items));
  }

  void _onItemRemoved(
    ReceiptScanItemRemoved event,
    Emitter<ReceiptScanState> emit,
  ) {
    final items = state.items
        .where((item) => item.id != event.itemId)
        .toList(growable: false);
    emit(_withItems(state, emit, items));
  }

  ReceiptScanState _withItems(
    ReceiptScanState state,
    Emitter<ReceiptScanState> emit,
    List<ReceiptItem> items,
  ) {
    final subtotal = items.fold(0, (total, item) => total + item.totalMinor);
    final total = subtotal + state.taxMinor + state.serviceMinor;
    return state.copyWith(
      items: items,
      subtotalMinor: subtotal,
      totalMinor: total,
      clearError: true,
    );
  }

  void _onTax(ReceiptScanTaxChanged event, Emitter<ReceiptScanState> emit) {
    final tax = event.minor < 0 ? 0 : event.minor;
    final subtotal = state.items.fold(
      0,
      (total, item) => total + item.totalMinor,
    );
    emit(
      state.copyWith(
        taxMinor: tax,
        subtotalMinor: subtotal,
        totalMinor: subtotal + tax + state.serviceMinor,
        clearError: true,
      ),
    );
  }

  void _onService(
    ReceiptScanServiceChanged event,
    Emitter<ReceiptScanState> emit,
  ) {
    final service = event.minor < 0 ? 0 : event.minor;
    final subtotal = state.items.fold(
      0,
      (total, item) => total + item.totalMinor,
    );
    emit(
      state.copyWith(
        serviceMinor: service,
        subtotalMinor: subtotal,
        totalMinor: subtotal + state.taxMinor + service,
        clearError: true,
      ),
    );
  }

  void _onTotal(ReceiptScanTotalChanged event, Emitter<ReceiptScanState> emit) {
    emit(state.copyWith(totalMinor: event.minor < 0 ? 0 : event.minor));
  }

  void _onDate(ReceiptScanDateChanged event, Emitter<ReceiptScanState> emit) {
    emit(state.copyWith(occurredAt: event.date));
  }

  Future<void> _onSubmitted(
    ReceiptScanSubmitted event,
    Emitter<ReceiptScanState> emit,
  ) async {
    final group = state.group;
    final user = _auth.currentUser;
    if (group == null || user == null) return;
    if (state.merchant.trim().isEmpty || state.totalMinor <= 0) {
      emit(state.copyWith(errorCode: 'receipt_incomplete'));
      return;
    }
    if (state.items.any((item) => item.name.trim().isEmpty)) {
      emit(state.copyWith(errorCode: 'items_required'));
      return;
    }
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final now = DateTime.now();
      final receiptId = _uuid.v4();
      String? imageUrl;
      if (state.imageBytes != null && state.imageBytes!.isNotEmpty) {
        imageUrl = await _uploadImage(
          groupId: group.id,
          receiptId: receiptId,
          bytes: state.imageBytes!,
        );
      }
      final receipt = Receipt(
        id: receiptId,
        groupId: group.id,
        createdBy: user.id,
        merchant: state.merchant.trim(),
        currency: state.currency,
        items: state.items,
        subtotalMinor: state.subtotalMinor,
        taxMinor: state.taxMinor,
        serviceMinor: state.serviceMinor,
        totalMinor: state.totalMinor,
        rawText: state.rawText,
        imageUrl: imageUrl,
        occurredAt: state.effectiveDate,
        status: ReceiptStatus.saved,
        createdAt: now,
        updatedAt: now,
      );
      await _saveReceipt(receipt);
      await _logActivity(
        ActivityEntry(
          id: _uuid.v4(),
          groupId: group.id,
          actorId: user.id,
          actorName: user.displayName,
          kind: ActivityKind.receiptScanned,
          summary: 'memindai struk ${receipt.merchant}',
          payload: {
            'receipt_id': receipt.id,
            'total_minor': receipt.totalMinor,
          },
          createdAt: now,
        ),
      );
      emit(
        state.copyWith(
          saving: false,
          saved: true,
          receiptId: receipt.id,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(saving: false, errorCode: 'save_failed'));
    }
  }

  void _onCleared(ReceiptScanCleared event, Emitter<ReceiptScanState> emit) {
    emit(
      ReceiptScanState(
        loading: false,
        group: state.group,
        currency: state.group?.currency ?? 'IDR',
        occurredAt: DateTime.now(),
      ),
    );
  }
}
