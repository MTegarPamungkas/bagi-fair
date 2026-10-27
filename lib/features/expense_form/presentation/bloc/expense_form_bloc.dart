import 'dart:async';

import 'package:bagi_fair/data/services/notification_service.dart';
import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/receipt.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/usecases/currency_converter.dart';
import 'package:bagi_fair/domain/usecases/expense_usecases.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:bagi_fair/domain/usecases/notification_usecases.dart';
import 'package:bagi_fair/domain/usecases/split_engine.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

/// Everything the router needs to open the editor.
class ExpenseFormRequest {
  const ExpenseFormRequest({
    required this.groupId,
    this.expenseId,
    this.receiptId,
  });

  final String groupId;
  final String? expenseId;
  final String? receiptId;
}

class ExpenseFormState extends Equatable {
  const ExpenseFormState({
    this.loading = true,
    this.group,
    this.members = const [],
    this.expenseId,
    this.receiptId,
    this.receiptMerchant,
    this.title = '',
    this.amountMinor = 0,
    this.currency = 'IDR',
    this.fxRate = 1,
    this.payerId,
    this.splitMode = SplitMode.equal,
    this.participantIds = const [],
    this.weightsBps = const {},
    this.exactMinor = const {},
    this.items = const [],
    this.taxMinor = 0,
    this.serviceMinor = 0,
    this.discountMinor = 0,
    this.note = '',
    this.category = ExpenseCategory.other,
    this.occurredAt,
    this.baseAmountMinor = 0,
    this.shares = const [],
    this.saving = false,
    this.saved = false,
    this.errorCode,
    this.savedExpenseId,
  });

  final bool loading;
  final Group? group;
  final List<GroupMember> members;
  final String? expenseId;
  final String? receiptId;
  final String? receiptMerchant;
  final String title;
  final int amountMinor;
  final String currency;
  final double fxRate;
  final String? payerId;
  final SplitMode splitMode;
  final List<String> participantIds;
  final Map<String, int> weightsBps;
  final Map<String, int> exactMinor;
  final List<ExpenseItem> items;
  final int taxMinor;
  final int serviceMinor;
  final int discountMinor;
  final String note;
  final ExpenseCategory category;
  final DateTime? occurredAt;

  /// Preview total in the group's base currency.
  final int baseAmountMinor;
  final List<ExpenseShare> shares;

  final bool saving;
  final bool saved;
  final String? errorCode;
  final String? savedExpenseId;

  bool get isEditing => expenseId != null;

  bool get isItemized => splitMode == SplitMode.itemized;

  String get groupCurrency => group?.currency ?? 'IDR';

  bool get isForeignCurrency => currency != groupCurrency;

  DateTime get effectiveDate => occurredAt ?? DateTime.now();

  GroupMember? memberFor(String userId) {
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  String nameFor(String userId) {
    if (userId == payerId) return memberFor(userId)?.displayName ?? 'Teman';
    return memberFor(userId)?.displayName ?? 'Teman';
  }

  int get itemsSubtotalMinor =>
      items.fold(0, (total, item) => total + item.totalMinor);

  ExpenseFormState copyWith({
    bool? loading,
    Group? group,
    List<GroupMember>? members,
    String? expenseId,
    String? receiptId,
    String? receiptMerchant,
    String? title,
    int? amountMinor,
    String? currency,
    double? fxRate,
    String? payerId,
    SplitMode? splitMode,
    List<String>? participantIds,
    Map<String, int>? weightsBps,
    Map<String, int>? exactMinor,
    List<ExpenseItem>? items,
    int? taxMinor,
    int? serviceMinor,
    int? discountMinor,
    String? note,
    ExpenseCategory? category,
    DateTime? occurredAt,
    int? baseAmountMinor,
    List<ExpenseShare>? shares,
    bool? saving,
    bool? saved,
    String? errorCode,
    String? savedExpenseId,
    bool clearError = false,
    bool clearReceipt = false,
  }) {
    return ExpenseFormState(
      loading: loading ?? this.loading,
      group: group ?? this.group,
      members: members ?? this.members,
      expenseId: expenseId ?? this.expenseId,
      receiptId: clearReceipt ? null : (receiptId ?? this.receiptId),
      receiptMerchant: clearReceipt
          ? null
          : (receiptMerchant ?? this.receiptMerchant),
      title: title ?? this.title,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      fxRate: fxRate ?? this.fxRate,
      payerId: payerId ?? this.payerId,
      splitMode: splitMode ?? this.splitMode,
      participantIds: participantIds ?? this.participantIds,
      weightsBps: weightsBps ?? this.weightsBps,
      exactMinor: exactMinor ?? this.exactMinor,
      items: items ?? this.items,
      taxMinor: taxMinor ?? this.taxMinor,
      serviceMinor: serviceMinor ?? this.serviceMinor,
      discountMinor: discountMinor ?? this.discountMinor,
      note: note ?? this.note,
      category: category ?? this.category,
      occurredAt: occurredAt ?? this.occurredAt,
      baseAmountMinor: baseAmountMinor ?? this.baseAmountMinor,
      shares: shares ?? this.shares,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      savedExpenseId: savedExpenseId ?? this.savedExpenseId,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    group,
    members,
    expenseId,
    receiptId,
    receiptMerchant,
    title,
    amountMinor,
    currency,
    fxRate,
    payerId,
    splitMode,
    participantIds,
    weightsBps,
    exactMinor,
    items,
    taxMinor,
    serviceMinor,
    discountMinor,
    note,
    category,
    occurredAt,
    baseAmountMinor,
    shares,
    saving,
    saved,
    errorCode,
    savedExpenseId,
  ];
}

sealed class ExpenseFormEvent extends Equatable {
  const ExpenseFormEvent();

  @override
  List<Object?> get props => const [];
}

class ExpenseFormStarted extends ExpenseFormEvent {
  const ExpenseFormStarted();
}

class ExpenseFormTitleChanged extends ExpenseFormEvent {
  const ExpenseFormTitleChanged(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

class ExpenseFormAmountChanged extends ExpenseFormEvent {
  const ExpenseFormAmountChanged(this.amountMinor);

  final int amountMinor;

  @override
  List<Object?> get props => [amountMinor];
}

class ExpenseFormCurrencyChanged extends ExpenseFormEvent {
  const ExpenseFormCurrencyChanged(this.currency);

  final String currency;

  @override
  List<Object?> get props => [currency];
}

class ExpenseFormFxRateChanged extends ExpenseFormEvent {
  const ExpenseFormFxRateChanged(this.rate);

  final double rate;

  @override
  List<Object?> get props => [rate];
}

class ExpenseFormPayerChanged extends ExpenseFormEvent {
  const ExpenseFormPayerChanged(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ExpenseFormModeChanged extends ExpenseFormEvent {
  const ExpenseFormModeChanged(this.mode);

  final SplitMode mode;

  @override
  List<Object?> get props => [mode];
}

class ExpenseFormParticipantToggled extends ExpenseFormEvent {
  const ExpenseFormParticipantToggled(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ExpenseFormAllParticipantsSelected extends ExpenseFormEvent {
  const ExpenseFormAllParticipantsSelected();
}

class ExpenseFormWeightChanged extends ExpenseFormEvent {
  const ExpenseFormWeightChanged(this.userId, this.bps);

  final String userId;
  final int bps;

  @override
  List<Object?> get props => [userId, bps];
}

class ExpenseFormExactChanged extends ExpenseFormEvent {
  const ExpenseFormExactChanged(this.userId, this.minor);

  final String userId;
  final int minor;

  @override
  List<Object?> get props => [userId, minor];
}

class ExpenseFormItemAdded extends ExpenseFormEvent {
  const ExpenseFormItemAdded();
}

class ExpenseFormItemUpdated extends ExpenseFormEvent {
  const ExpenseFormItemUpdated({
    required this.itemId,
    this.name,
    this.quantity,
    this.unitPriceMinor,
    this.memberIds,
  });

  final String itemId;
  final String? name;
  final int? quantity;
  final int? unitPriceMinor;
  final List<String>? memberIds;

  @override
  List<Object?> get props => [
    itemId,
    name,
    quantity,
    unitPriceMinor,
    memberIds,
  ];
}

class ExpenseFormItemRemoved extends ExpenseFormEvent {
  const ExpenseFormItemRemoved(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

class ExpenseFormItemMemberToggled extends ExpenseFormEvent {
  const ExpenseFormItemMemberToggled(this.itemId, this.userId);

  final String itemId;
  final String userId;

  @override
  List<Object?> get props => [itemId, userId];
}

class ExpenseFormItemEveryoneToggled extends ExpenseFormEvent {
  const ExpenseFormItemEveryoneToggled(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

class ExpenseFormTaxChanged extends ExpenseFormEvent {
  const ExpenseFormTaxChanged(this.minor);

  final int minor;

  @override
  List<Object?> get props => [minor];
}

class ExpenseFormServiceChanged extends ExpenseFormEvent {
  const ExpenseFormServiceChanged(this.minor);

  final int minor;

  @override
  List<Object?> get props => [minor];
}

class ExpenseFormDiscountChanged extends ExpenseFormEvent {
  const ExpenseFormDiscountChanged(this.minor);

  final int minor;

  @override
  List<Object?> get props => [minor];
}

class ExpenseFormNoteChanged extends ExpenseFormEvent {
  const ExpenseFormNoteChanged(this.note);

  final String note;

  @override
  List<Object?> get props => [note];
}

class ExpenseFormCategoryChanged extends ExpenseFormEvent {
  const ExpenseFormCategoryChanged(this.category);

  final ExpenseCategory category;

  @override
  List<Object?> get props => [category];
}

class ExpenseFormDateChanged extends ExpenseFormEvent {
  const ExpenseFormDateChanged(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class ExpenseFormReceiptCleared extends ExpenseFormEvent {
  const ExpenseFormReceiptCleared();
}

class ExpenseFormSubmitted extends ExpenseFormEvent {
  const ExpenseFormSubmitted();
}

class ExpenseFormMessageDismissed extends ExpenseFormEvent {
  const ExpenseFormMessageDismissed();
}

class ExpenseFormBloc extends Bloc<ExpenseFormEvent, ExpenseFormState> {
  ExpenseFormBloc({
    required this._getGroup,
    required this._watchMembers,
    required this._getExpense,
    required this._getReceipt,
    required this._saveExpense,
    required this._saveReceipt,
    required this._logActivity,
    required this._sendNotification,
    required this._auth,
    required this._notifications,
    required this._request,
    this._uuid = const Uuid(),
  }) : super(const ExpenseFormState()) {
    on<ExpenseFormStarted>(_onStarted);
    on<ExpenseFormTitleChanged>(_onTitle);
    on<ExpenseFormAmountChanged>(_onAmount);
    on<ExpenseFormCurrencyChanged>(_onCurrency);
    on<ExpenseFormFxRateChanged>(_onFxRate);
    on<ExpenseFormPayerChanged>(_onPayer);
    on<ExpenseFormModeChanged>(_onMode);
    on<ExpenseFormParticipantToggled>(_onParticipantToggled);
    on<ExpenseFormAllParticipantsSelected>(_onAllParticipants);
    on<ExpenseFormWeightChanged>(_onWeight);
    on<ExpenseFormExactChanged>(_onExact);
    on<ExpenseFormItemAdded>(_onItemAdded);
    on<ExpenseFormItemUpdated>(_onItemUpdated);
    on<ExpenseFormItemRemoved>(_onItemRemoved);
    on<ExpenseFormItemMemberToggled>(_onItemMemberToggled);
    on<ExpenseFormItemEveryoneToggled>(_onItemEveryone);
    on<ExpenseFormTaxChanged>(_onTax);
    on<ExpenseFormServiceChanged>(_onService);
    on<ExpenseFormDiscountChanged>(_onDiscount);
    on<ExpenseFormNoteChanged>(_onNote);
    on<ExpenseFormCategoryChanged>(_onCategory);
    on<ExpenseFormDateChanged>(_onDate);
    on<ExpenseFormReceiptCleared>(_onReceiptCleared);
    on<ExpenseFormSubmitted>(_onSubmitted);
    on<ExpenseFormMessageDismissed>(_onDismiss);
    on<_ExpenseFormMembersChanged>(_onMembersChanged);
    on<_ExpenseFormFailed>(_onFailed);
  }

  final GetGroup _getGroup;
  final WatchGroupMembers _watchMembers;
  final GetExpense _getExpense;
  final GetReceipt _getReceipt;
  final SaveExpense _saveExpense;
  final SaveReceipt _saveReceipt;
  final LogActivity _logActivity;
  final SendNotification _sendNotification;
  final AuthRepository _auth;
  final NotificationService _notifications;
  final ExpenseFormRequest _request;
  final Uuid _uuid;

  StreamSubscription<List<GroupMember>>? _membersSubscription;
  Receipt? _receipt;

  Future<void> _onStarted(
    ExpenseFormStarted event,
    Emitter<ExpenseFormState> emit,
  ) async {
    final group = await _getGroup(_request.groupId);
    if (group == null) {
      emit(state.copyWith(loading: false, errorCode: 'group_not_found'));
      return;
    }
    final userId = _auth.currentUser?.id;
    final expense = _request.expenseId == null
        ? null
        : await _getExpense(_request.expenseId!);
    if (_request.receiptId != null) {
      _receipt = await _getReceipt(_request.receiptId!);
    }

    var next = state.copyWith(
      loading: true,
      group: group,
      expenseId: _request.expenseId,
      receiptId: _receipt?.id ?? _request.receiptId,
      receiptMerchant: _receipt?.merchant,
      currency: expense?.currency ?? _receipt?.currency ?? group.currency,
      fxRate: expense?.fxRate ?? 1,
      title: expense?.title ?? _receipt?.merchant ?? '',
      amountMinor: expense?.amountMinor ?? _receipt?.totalMinor ?? 0,
      payerId: expense?.paidBy ?? userId,
      splitMode: expense?.splitMode ?? SplitMode.equal,
      participantIds:
          expense?.shares.map((share) => share.userId).toList() ?? const [],
      weightsBps: {
        if (expense != null)
          for (final share in expense.shares)
            if (share.weightBps > 0) share.userId: share.weightBps,
      },
      exactMinor: {
        if (expense != null)
          for (final share in expense.shares)
            if (expense.splitMode == SplitMode.exact)
              share.userId: share.amountMinor,
      },
      items:
          expense?.items ??
          (_receipt?.items
                  .map(
                    (item) => ExpenseItem(
                      id: item.id,
                      name: item.name,
                      quantity: item.quantity,
                      unitPriceMinor: item.unitPriceMinor,
                      totalMinor: item.totalMinor,
                      memberIds: const [],
                    ),
                  )
                  .toList() ??
              const []),
      taxMinor: expense?.taxMinor ?? _receipt?.taxMinor ?? 0,
      serviceMinor: expense?.serviceMinor ?? _receipt?.serviceMinor ?? 0,
      discountMinor: expense?.discountMinor ?? 0,
      note: expense?.note ?? '',
      category: expense?.category ?? _categoryForReceipt(_receipt),
      occurredAt: expense?.occurredAt ?? _receipt?.occurredAt ?? DateTime.now(),
      clearError: true,
    );

    emit(_recalculate(next));

    await _membersSubscription?.cancel();
    _membersSubscription = _watchMembers(group.id).listen(
      (members) => add(_ExpenseFormMembersChanged(members)),
      onError: (Object error) => add(_ExpenseFormFailed(error.toString())),
    );
  }

  void _onMembersChanged(
    _ExpenseFormMembersChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    final ids = event.members.map((member) => member.userId).toSet();
    final participants = state.participantIds
        .where(ids.contains)
        .toList(growable: false);
    final selected = participants.isEmpty
        ? ids.toList(growable: false)
        : participants;
    final payer = state.payerId != null && ids.contains(state.payerId)
        ? state.payerId
        : (_auth.currentUser?.id != null && ids.contains(_auth.currentUser!.id)
              ? _auth.currentUser!.id
              : (event.members.isEmpty ? null : event.members.first.userId));
    final items = state.items
        .map(
          (item) => item.copyWith(
            memberIds: item.memberIds.where(ids.contains).toList(),
          ),
        )
        .toList(growable: false);

    emit(
      _recalculate(
        state.copyWith(
          loading: false,
          members: event.members,
          participantIds: selected,
          payerId: payer,
          items: items,
          weightsBps:
              state.weightsBps.isEmpty
                    ? _evenWeights(selected)
                    : {for (final id in selected) id: state.weightsBps[id] ?? 0}
                ..addAll(_fillMissingWeights(selected, state.weightsBps)),
        ),
      ),
    );
  }

  void _onFailed(_ExpenseFormFailed event, Emitter<ExpenseFormState> emit) {
    emit(state.copyWith(loading: false, errorCode: 'load_failed'));
  }

  void _onTitle(ExpenseFormTitleChanged event, Emitter<ExpenseFormState> emit) {
    emit(_recalculate(state.copyWith(title: event.title, clearError: true)));
  }

  void _onAmount(
    ExpenseFormAmountChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(
      _recalculate(
        state.copyWith(amountMinor: event.amountMinor, clearError: true),
      ),
    );
  }

  void _onCurrency(
    ExpenseFormCurrencyChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    final sameCurrency = event.currency == state.groupCurrency;
    emit(
      _recalculate(
        state.copyWith(
          currency: event.currency,
          fxRate: sameCurrency ? 1 : state.fxRate,
          clearError: true,
        ),
      ),
    );
  }

  void _onFxRate(
    ExpenseFormFxRateChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(_recalculate(state.copyWith(fxRate: event.rate, clearError: true)));
  }

  void _onPayer(ExpenseFormPayerChanged event, Emitter<ExpenseFormState> emit) {
    emit(_recalculate(state.copyWith(payerId: event.userId, clearError: true)));
  }

  void _onMode(ExpenseFormModeChanged event, Emitter<ExpenseFormState> emit) {
    final participants = state.participantIds.isEmpty
        ? state.members.map((member) => member.userId).toList(growable: false)
        : state.participantIds;
    var weights = state.weightsBps;
    if (event.mode == SplitMode.percentage) {
      weights = _fillMissingWeights(participants, weights);
    }
    emit(
      _recalculate(
        state.copyWith(
          splitMode: event.mode,
          weightsBps: weights,
          clearError: true,
        ),
      ),
    );
  }

  void _onParticipantToggled(
    ExpenseFormParticipantToggled event,
    Emitter<ExpenseFormState> emit,
  ) {
    final participants = [...state.participantIds];
    if (participants.contains(event.userId)) {
      if (participants.length == 1) {
        emit(state.copyWith(errorCode: 'participant_required'));
        return;
      }
      participants.remove(event.userId);
    } else {
      participants.add(event.userId);
    }

    final exact = Map<String, int>.from(state.exactMinor)
      ..removeWhere((key, _) => !participants.contains(key));
    final weights = state.splitMode == SplitMode.percentage
        ? _evenWeights(participants)
        : state.weightsBps;

    emit(
      _recalculate(
        state.copyWith(
          participantIds: participants,
          weightsBps: weights,
          exactMinor: exact,
          clearError: true,
        ),
      ),
    );
  }

  void _onAllParticipants(
    ExpenseFormAllParticipantsSelected event,
    Emitter<ExpenseFormState> emit,
  ) {
    final participants = state.members
        .map((member) => member.userId)
        .toList(growable: false);
    emit(
      _recalculate(
        state.copyWith(
          participantIds: participants,
          weightsBps: state.splitMode == SplitMode.percentage
              ? _evenWeights(participants)
              : state.weightsBps,
          exactMinor: {
            for (final id in participants) id: state.exactMinor[id] ?? 0,
          },
          clearError: true,
        ),
      ),
    );
  }

  void _onWeight(
    ExpenseFormWeightChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    final weights = Map<String, int>.from(state.weightsBps);
    weights[event.userId] = event.bps.clamp(0, 10000);
    emit(_recalculate(state.copyWith(weightsBps: weights, clearError: true)));
  }

  void _onExact(ExpenseFormExactChanged event, Emitter<ExpenseFormState> emit) {
    final exact = Map<String, int>.from(state.exactMinor);
    exact[event.userId] = event.minor < 0 ? 0 : event.minor;
    emit(_recalculate(state.copyWith(exactMinor: exact, clearError: true)));
  }

  void _onItemAdded(
    ExpenseFormItemAdded event,
    Emitter<ExpenseFormState> emit,
  ) {
    final item = ExpenseItem(
      id: _uuid.v4(),
      name: '',
      unitPriceMinor: 0,
      totalMinor: 0,
      memberIds: [...state.participantIds],
    );
    emit(
      _recalculate(
        state.copyWith(items: [...state.items, item], clearError: true),
      ),
    );
  }

  void _onItemUpdated(
    ExpenseFormItemUpdated event,
    Emitter<ExpenseFormState> emit,
  ) {
    final items = state.items
        .map((item) {
          if (item.id != event.itemId) return item;
          final quantity = event.quantity ?? item.quantity;
          final unit = event.unitPriceMinor ?? item.unitPriceMinor;
          return item.copyWith(
            name: event.name,
            quantity: quantity,
            unitPriceMinor: unit,
            totalMinor: (quantity * unit).clamp(0, 1 << 52).toInt(),
            memberIds: event.memberIds,
          );
        })
        .toList(growable: false);
    emit(_recalculate(state.copyWith(items: items, clearError: true)));
  }

  void _onItemRemoved(
    ExpenseFormItemRemoved event,
    Emitter<ExpenseFormState> emit,
  ) {
    final items = state.items
        .where((item) => item.id != event.itemId)
        .toList(growable: false);
    emit(_recalculate(state.copyWith(items: items, clearError: true)));
  }

  void _onItemMemberToggled(
    ExpenseFormItemMemberToggled event,
    Emitter<ExpenseFormState> emit,
  ) {
    final items = state.items
        .map((item) {
          if (item.id != event.itemId) return item;
          final members = [...item.memberIds];
          if (members.contains(event.userId)) {
            members.remove(event.userId);
          } else {
            members.add(event.userId);
          }
          return item.copyWith(memberIds: members);
        })
        .toList(growable: false);
    emit(_recalculate(state.copyWith(items: items, clearError: true)));
  }

  void _onItemEveryone(
    ExpenseFormItemEveryoneToggled event,
    Emitter<ExpenseFormState> emit,
  ) {
    final items = state.items
        .map((item) {
          if (item.id != event.itemId) return item;
          return item.copyWith(memberIds: [...state.participantIds]);
        })
        .toList(growable: false);
    emit(_recalculate(state.copyWith(items: items, clearError: true)));
  }

  void _onTax(ExpenseFormTaxChanged event, Emitter<ExpenseFormState> emit) {
    emit(
      _recalculate(
        state.copyWith(
          taxMinor: event.minor < 0 ? 0 : event.minor,
          clearError: true,
        ),
      ),
    );
  }

  void _onService(
    ExpenseFormServiceChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(
      _recalculate(
        state.copyWith(
          serviceMinor: event.minor < 0 ? 0 : event.minor,
          clearError: true,
        ),
      ),
    );
  }

  void _onDiscount(
    ExpenseFormDiscountChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(
      _recalculate(
        state.copyWith(
          discountMinor: event.minor < 0 ? 0 : event.minor,
          clearError: true,
        ),
      ),
    );
  }

  void _onNote(ExpenseFormNoteChanged event, Emitter<ExpenseFormState> emit) {
    emit(state.copyWith(note: event.note, clearError: true));
  }

  void _onCategory(
    ExpenseFormCategoryChanged event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(state.copyWith(category: event.category, clearError: true));
  }

  void _onDate(ExpenseFormDateChanged event, Emitter<ExpenseFormState> emit) {
    emit(state.copyWith(occurredAt: event.date, clearError: true));
  }

  void _onReceiptCleared(
    ExpenseFormReceiptCleared event,
    Emitter<ExpenseFormState> emit,
  ) {
    _receipt = null;
    emit(state.copyWith(clearReceipt: true, clearError: true));
  }

  Future<void> _onSubmitted(
    ExpenseFormSubmitted event,
    Emitter<ExpenseFormState> emit,
  ) async {
    final group = state.group;
    final user = _auth.currentUser;
    if (group == null || user == null) return;

    final invalid = _validationError(state);
    if (invalid != null) {
      emit(state.copyWith(errorCode: invalid));
      return;
    }
    final preview = _recalculate(state);
    if (preview.shares.isEmpty) {
      emit(state.copyWith(errorCode: 'save_failed'));
      return;
    }

    emit(state.copyWith(saving: true, clearError: true));
    try {
      final now = DateTime.now();
      final originalAmount = state.isItemized
          ? state.itemsSubtotalMinor +
                state.taxMinor +
                state.serviceMinor -
                state.discountMinor
          : state.amountMinor;
      final expense = Expense(
        id: state.expenseId ?? _uuid.v4(),
        groupId: group.id,
        title: state.title.trim(),
        category: state.category,
        amountMinor: originalAmount,
        amountBaseMinor: preview.baseAmountMinor,
        currency: state.currency,
        fxRate: state.isForeignCurrency ? state.fxRate : 1,
        paidBy: state.payerId!,
        splitMode: state.splitMode,
        note: state.note.trim(),
        occurredAt: state.effectiveDate,
        items: state.isItemized ? state.items : const [],
        shares: preview.shares,
        taxMinor: state.isItemized ? state.taxMinor : 0,
        serviceMinor: state.isItemized ? state.serviceMinor : 0,
        discountMinor: state.isItemized ? state.discountMinor : 0,
        receiptId: state.receiptId,
        createdBy: user.id,
        createdAt: now,
        updatedAt: now,
      );
      await _saveExpense(expense);

      if (_receipt != null) {
        final receipt = _receipt!.copyWith(
          status: ReceiptStatus.saved,
          imageUrl: _receipt!.imageUrl,
          updatedAt: now,
        );
        await _saveReceipt(receipt);
      }

      await _logActivity(
        ActivityEntry(
          id: _uuid.v4(),
          groupId: group.id,
          actorId: user.id,
          actorName: user.displayName,
          kind: state.isEditing
              ? ActivityKind.expenseUpdated
              : ActivityKind.expenseAdded,
          summary:
              '${state.isEditing ? 'mengubah' : 'menambahkan'} ${expense.title}',
          payload: {'amount_minor': expense.amountBaseMinor},
          createdAt: now,
        ),
      );

      final people = preview.shares
          .where((share) => share.userId != user.id)
          .map((share) => share.userId)
          .toSet();
      for (final userId in people) {
        await _sendNotification(
          AppNotification(
            id: _uuid.v4(),
            userId: userId,
            groupId: group.id,
            actorId: user.id,
            actorName: user.displayName,
            kind: AppNotificationKind.expenseAdded,
            title: state.isEditing
                ? 'Pengeluaran diperbarui di ${group.name}'
                : 'Pengeluaran baru di ${group.name}',
            body:
                '${user.displayName} mencatat ${expense.title}. Cek bagianmu di Bagi Fair.',
            payload: {'expense_id': expense.id},
            createdAt: now,
          ),
        );
      }

      await _notifications.show(
        title: state.isEditing
            ? 'Pengeluaran diperbarui'
            : 'Pengeluaran tersimpan',
        body: '${group.name} · ${expense.title}',
      );

      emit(
        state.copyWith(
          saving: false,
          saved: true,
          savedExpenseId: expense.id,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(saving: false, errorCode: 'save_failed'));
    }
  }

  void _onDismiss(
    ExpenseFormMessageDismissed event,
    Emitter<ExpenseFormState> emit,
  ) {
    emit(state.copyWith(clearError: true));
  }

  String? _validationError(ExpenseFormState state) {
    if (state.title.trim().isEmpty) return 'title_required';
    if (state.payerId == null) return 'payer_required';
    if (!state.participantIds.contains(state.payerId)) return 'payer_required';
    if (state.participantIds.isEmpty) return 'participant_required';
    if (state.isForeignCurrency && state.fxRate <= 0) return 'fx_invalid';

    if (state.isItemized) {
      if (state.items.isEmpty) return 'items_required';
      if (state.items.any((item) => item.name.trim().isEmpty)) {
        return 'items_required';
      }
      if (state.items.any((item) => item.memberIds.isEmpty)) {
        return 'item_unassigned';
      }
      if (state.itemsSubtotalMinor +
              state.taxMinor +
              state.serviceMinor -
              state.discountMinor <=
          0) {
        return 'amount_required';
      }
    } else {
      if (state.amountMinor <= 0) return 'amount_required';
      if (state.amountMinor < state.discountMinor) {
        return 'amount_required';
      }
      if (state.splitMode == SplitMode.percentage &&
          state.weightsBps.values.fold(0, (a, b) => a + b) != 10000) {
        return 'percentage_total';
      }
      if (state.splitMode == SplitMode.exact) {
        var sum = 0;
        for (final id in state.participantIds) {
          sum += state.exactMinor[id] ?? 0;
        }
        if (sum != state.amountMinor) return 'exact_total';
      }
    }
    final computed = _calculate(state);
    if (computed.error != null) return computed.error;
    if (computed.shares.isEmpty) return 'participant_required';
    return null;
  }

  ExpenseFormState _recalculate(ExpenseFormState input) {
    final result = _calculate(input);
    return input.copyWith(
      baseAmountMinor: result.baseAmount,
      shares: result.shares,
      members: input.members,
    );
  }

  _Calculation _calculate(ExpenseFormState s) {
    final group = s.group;
    if (group == null) return const _Calculation(0, [], null);
    final rate = s.isForeignCurrency ? s.fxRate : 1.0;
    if (s.isForeignCurrency && rate <= 0) {
      return const _Calculation(0, [], 'fx_invalid');
    }

    if (s.isItemized) {
      if (s.items.isEmpty) return const _Calculation(0, [], 'items_required');
      final baseItems = [
        for (final item in s.items)
          item.copyWith(
            totalMinor: _convert(
              item.totalMinor,
              s.currency,
              group.currency,
              rate,
            ),
          ),
      ];
      final baseTax = _convert(s.taxMinor, s.currency, group.currency, rate);
      final baseService = _convert(
        s.serviceMinor,
        s.currency,
        group.currency,
        rate,
      );
      final baseDiscount = _convert(
        s.discountMinor,
        s.currency,
        group.currency,
        rate,
      );
      final total =
          baseItems.fold(0, (sum, item) => sum + item.totalMinor) +
          baseTax +
          baseService -
          baseDiscount;
      if (total <= 0) return _Calculation(total, const [], 'amount_required');
      if (baseDiscount > total) {
        return _Calculation(total, const [], 'amount_required');
      }
      try {
        final result = SplitEngine.compute(
          totalMinor: total,
          mode: SplitMode.itemized,
          participants: [
            for (final id in s.participantIds) SplitParticipant(userId: id),
          ],
          items: baseItems,
          taxMinor: baseTax,
          serviceMinor: baseService,
          discountMinor: baseDiscount,
        );
        return _Calculation(total, result.shares, null);
      } on SplitException {
        return const _Calculation(0, [], 'item_unassigned');
      }
    }

    var total = _convert(s.amountMinor, s.currency, group.currency, rate);
    if (total <= 0) return _Calculation(total, const [], 'amount_required');

    // Tax/service/discount entered for a non-itemized bill are proportional
    // adjustments applied by the engine before allocating shares.
    final participants = [
      for (final id in s.participantIds) SplitParticipant(userId: id),
    ];
    if (participants.isEmpty) {
      return const _Calculation(0, [], 'participant_required');
    }

    if (s.splitMode == SplitMode.equal) {
      try {
        final result = SplitEngine.compute(
          totalMinor: total,
          mode: SplitMode.equal,
          participants: participants,
        );
        return _Calculation(total, result.shares, null);
      } on SplitException {
        return const _Calculation(0, [], 'participant_required');
      }
    }

    if (s.splitMode == SplitMode.percentage) {
      final weights = [
        for (final id in s.participantIds) s.weightsBps[id] ?? 0,
      ];
      if (weights.fold(0, (a, b) => a + b) != 10000) {
        return _Calculation(total, const [], 'percentage_total');
      }
      try {
        final result = SplitEngine.compute(
          totalMinor: total,
          mode: SplitMode.percentage,
          participants: [
            for (var i = 0; i < s.participantIds.length; i++)
              SplitParticipant(
                userId: s.participantIds[i],
                weightBps: weights[i],
              ),
          ],
        );
        return _Calculation(total, result.shares, null);
      } on SplitException {
        return _Calculation(total, const [], 'percentage_total');
      }
    }

    // Exact mode: keep the user's amounts, converting each proportionally when
    // the bill is in a foreign currency.
    var exactTotal = 0;
    for (final id in s.participantIds) {
      exactTotal += s.exactMinor[id] ?? 0;
    }
    if (exactTotal != s.amountMinor) {
      return _Calculation(total, const [], 'exact_total');
    }
    final weights = [for (final id in s.participantIds) s.exactMinor[id] ?? 0];
    final amounts = s.isForeignCurrency
        ? SplitEngine.allocate(total, weights)
        : [for (final id in s.participantIds) s.exactMinor[id] ?? 0];
    return _Calculation(total, [
      for (var i = 0; i < s.participantIds.length; i++)
        ExpenseShare(
          userId: s.participantIds[i],
          amountMinor: amounts[i],
          subtotalMinor: amounts[i],
        ),
    ], null);
  }

  int _convert(int minor, String from, String to, double rate) {
    return CurrencyConverter.toBase(
      minor,
      fromCurrency: from,
      toCurrency: to,
      rate: rate,
    );
  }

  Map<String, int> _evenWeights(List<String> ids) {
    if (ids.isEmpty) return const {};
    final weights = SplitEngine.allocate(
      10000,
      List<int>.filled(ids.length, 1),
    );
    return {for (var i = 0; i < ids.length; i++) ids[i]: weights[i]};
  }

  Map<String, int> _fillMissingWeights(
    List<String> ids,
    Map<String, int> existing,
  ) {
    final known = {
      for (final id in ids)
        if ((existing[id] ?? 0) > 0) id: existing[id]!,
    };
    if (known.isEmpty) return _evenWeights(ids);
    final group = ids.where((id) => !known.containsKey(id)).toList();
    if (group.isEmpty) return {for (final id in ids) id: known[id] ?? 0};
    final remaining = (10000 - known.values.fold(0, (a, b) => a + b))
        .clamp(0, 10000)
        .toInt();
    final extra = SplitEngine.allocate(
      remaining,
      List<int>.filled(group.length, 1),
    );
    return {for (final id in ids) id: known[id] ?? extra[group.indexOf(id)]};
  }

  ExpenseCategory _categoryForReceipt(Receipt? receipt) {
    if (receipt == null) return ExpenseCategory.other;
    return ExpenseCategory.food;
  }

  @override
  Future<void> close() async {
    await _membersSubscription?.cancel();
    return super.close();
  }
}

class _Calculation {
  const _Calculation(this.baseAmount, this.shares, this.error);

  final int baseAmount;
  final List<ExpenseShare> shares;
  final String? error;
}

class _ExpenseFormMembersChanged extends ExpenseFormEvent {
  const _ExpenseFormMembersChanged(this.members);

  final List<GroupMember> members;
}

class _ExpenseFormFailed extends ExpenseFormEvent {
  const _ExpenseFormFailed(this.message);

  final String message;
}
