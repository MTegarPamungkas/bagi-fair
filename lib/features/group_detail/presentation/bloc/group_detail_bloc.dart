import 'dart:async';

import 'package:bagi_fair/core/utils/stream_combine.dart';
import 'package:bagi_fair/data/services/notification_service.dart';
import 'package:bagi_fair/domain/entities/activity_entry.dart';
import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:bagi_fair/domain/entities/balance.dart';
import 'package:bagi_fair/domain/entities/expense.dart';
import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/receipt.dart';
import 'package:bagi_fair/domain/entities/settlement.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/repositories/export_repository.dart';
import 'package:bagi_fair/domain/usecases/expense_usecases.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:bagi_fair/domain/usecases/notification_usecases.dart';
import 'package:bagi_fair/domain/usecases/polite_nudge.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

typedef _GroupSnapshot = (
  Group? group,
  List<GroupMember> members,
  List<Expense> expenses,
  List<Settlement> settlements,
  List<ActivityEntry> activities,
  List<Receipt> receipts,
);

class GroupDetailState extends Equatable {
  const GroupDetailState({
    this.loading = true,
    this.group,
    this.members = const [],
    this.expenses = const [],
    this.settlements = const [],
    this.activities = const [],
    this.receipts = const [],
    this.summary = const GroupBalanceSummary(),
    this.currentUserId,
    this.busy = false,
    this.error,
    this.actionError,
    this.actionNotice,
    this.nudgeText,
    this.nudgeTargetName,
    this.archived = false,
  });

  final bool loading;
  final Group? group;
  final List<GroupMember> members;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final List<ActivityEntry> activities;
  final List<Receipt> receipts;
  final GroupBalanceSummary summary;
  final String? currentUserId;
  final bool busy;
  final String? error;
  final String? actionError;
  final String? actionNotice;
  final String? nudgeText;
  final String? nudgeTargetName;
  final bool archived;

  String get currency => group?.currency ?? 'IDR';

  GroupMember? memberFor(String userId) {
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  String nameFor(String userId) {
    if (userId == currentUserId && currentUserId != null) return 'Kamu';
    return memberFor(userId)?.displayName ?? 'Teman';
  }

  MemberBalance? balanceFor(String userId) => summary.balanceFor(userId);

  bool get isOwner => group?.isOwner(currentUserId) ?? false;

  GroupDetailState copyWith({
    bool? loading,
    Group? group,
    List<GroupMember>? members,
    List<Expense>? expenses,
    List<Settlement>? settlements,
    List<ActivityEntry>? activities,
    List<Receipt>? receipts,
    GroupBalanceSummary? summary,
    String? currentUserId,
    bool? busy,
    String? error,
    String? actionError,
    String? actionNotice,
    String? nudgeText,
    String? nudgeTargetName,
    bool? archived,
    bool clearError = false,
    bool clearActionError = false,
    bool clearActionNotice = false,
    bool clearNudge = false,
  }) {
    return GroupDetailState(
      loading: loading ?? this.loading,
      group: group ?? this.group,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      settlements: settlements ?? this.settlements,
      activities: activities ?? this.activities,
      receipts: receipts ?? this.receipts,
      summary: summary ?? this.summary,
      currentUserId: currentUserId ?? this.currentUserId,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      actionNotice: clearActionNotice
          ? null
          : (actionNotice ?? this.actionNotice),
      nudgeText: clearNudge ? null : (nudgeText ?? this.nudgeText),
      nudgeTargetName: clearNudge
          ? null
          : (nudgeTargetName ?? this.nudgeTargetName),
      archived: archived ?? this.archived,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    group,
    members,
    expenses,
    settlements,
    activities,
    receipts,
    summary,
    currentUserId,
    busy,
    error,
    actionError,
    actionNotice,
    nudgeText,
    nudgeTargetName,
    archived,
  ];
}

sealed class GroupDetailEvent extends Equatable {
  const GroupDetailEvent();

  @override
  List<Object?> get props => const [];
}

class GroupDetailStarted extends GroupDetailEvent {
  const GroupDetailStarted(this.groupId);

  final String groupId;

  @override
  List<Object?> get props => [groupId];
}

class GroupDetailRefreshRequested extends GroupDetailEvent {
  const GroupDetailRefreshRequested();
}

class GroupDetailSettlementSubmitted extends GroupDetailEvent {
  const GroupDetailSettlementSubmitted({
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
    this.note = '',
  });

  final String fromUserId;
  final String toUserId;
  final int amountMinor;
  final String note;

  @override
  List<Object?> get props => [fromUserId, toUserId, amountMinor, note];
}

class GroupDetailNudgeRequested extends GroupDetailEvent {
  const GroupDetailNudgeRequested(this.targetUserId);

  final String targetUserId;

  @override
  List<Object?> get props => [targetUserId];
}

class GroupDetailDeleteExpenseRequested extends GroupDetailEvent {
  const GroupDetailDeleteExpenseRequested(this.expense);

  final Expense expense;

  @override
  List<Object?> get props => [expense];
}

class GroupDetailArchiveRequested extends GroupDetailEvent {
  const GroupDetailArchiveRequested();
}

class GroupDetailExportRequested extends GroupDetailEvent {
  const GroupDetailExportRequested({required this.pdf});

  final bool pdf;

  @override
  List<Object?> get props => [pdf];
}

class GroupDetailMessageDismissed extends GroupDetailEvent {
  const GroupDetailMessageDismissed();
}

class GroupDetailBloc extends Bloc<GroupDetailEvent, GroupDetailState> {
  GroupDetailBloc({
    required this._watchGroup,
    required this._watchMembers,
    required this._watchExpenses,
    required this._watchSettlements,
    required this._watchActivities,
    required this._watchReceipts,
    required this._computeBalance,
    required this._saveSettlement,
    required this._logActivity,
    required this._deleteExpense,
    required this._archiveGroup,
    required this._sendNotification,
    required this._auth,
    required this._exportRepository,
    required this._notifications,
    this._uuid = const Uuid(),
  }) : super(const GroupDetailState()) {
    on<GroupDetailStarted>(_onStarted);
    on<GroupDetailRefreshRequested>(_onRefresh);
    on<GroupDetailSettlementSubmitted>(_onSettlement);
    on<GroupDetailNudgeRequested>(_onNudge);
    on<GroupDetailDeleteExpenseRequested>(_onDeleteExpense);
    on<GroupDetailArchiveRequested>(_onArchive);
    on<GroupDetailExportRequested>(_onExport);
    on<GroupDetailMessageDismissed>(_onDismiss);
    on<_GroupDetailChanged>(_onChanged);
    on<_GroupDetailFailed>(_onFailed);
  }

  final WatchGroup _watchGroup;
  final WatchGroupMembers _watchMembers;
  final WatchExpenses _watchExpenses;
  final WatchSettlements _watchSettlements;
  final WatchActivities _watchActivities;
  final WatchReceipts _watchReceipts;
  final ComputeGroupBalance _computeBalance;
  final SaveSettlement _saveSettlement;
  final LogActivity _logActivity;
  final DeleteExpense _deleteExpense;
  final ArchiveGroup _archiveGroup;
  final SendNotification _sendNotification;
  final AuthRepository _auth;
  final ExportRepository _exportRepository;
  final NotificationService _notifications;
  final Uuid _uuid;

  StreamSubscription<_GroupSnapshot>? _subscription;

  Future<void> _onStarted(
    GroupDetailStarted event,
    Emitter<GroupDetailState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    await _subscription?.cancel();
    final userId = _auth.currentUser?.id;
    final stream = combineLatest6(
      _watchGroup(event.groupId),
      _watchMembers(event.groupId),
      _watchExpenses(event.groupId),
      _watchSettlements(event.groupId),
      _watchActivities(event.groupId),
      _watchReceipts(event.groupId),
      (
        Group? group,
        List<GroupMember> members,
        List<Expense> expenses,
        List<Settlement> settlements,
        List<ActivityEntry> activities,
        List<Receipt> receipts,
      ) => (group, members, expenses, settlements, activities, receipts),
    );
    _subscription = stream.listen(
      (snapshot) => add(_GroupDetailChanged(snapshot, userId)),
      onError: (Object error) => add(_GroupDetailFailed(error.toString())),
    );
  }

  void _onChanged(_GroupDetailChanged event, Emitter<GroupDetailState> emit) {
    final (group, members, expenses, settlements, activities, receipts) =
        event.snapshot;
    final summary = _computeBalance(
      members: members,
      expenses: expenses,
      settlements: settlements,
      currentUserId: event.currentUserId,
    );
    emit(
      state.copyWith(
        loading: false,
        group: group,
        members: members,
        expenses: expenses,
        settlements: settlements,
        activities: activities,
        receipts: receipts,
        summary: summary,
        currentUserId: event.currentUserId,
        clearError: true,
      ),
    );
  }

  void _onFailed(_GroupDetailFailed event, Emitter<GroupDetailState> emit) {
    emit(state.copyWith(loading: false, error: event.message));
  }

  Future<void> _onRefresh(
    GroupDetailRefreshRequested event,
    Emitter<GroupDetailState> emit,
  ) async {
    emit(state.copyWith(clearActionError: true, clearActionNotice: true));
  }

  Future<void> _onSettlement(
    GroupDetailSettlementSubmitted event,
    Emitter<GroupDetailState> emit,
  ) async {
    final group = state.group;
    final user = _auth.currentUser;
    if (group == null || user == null) return;
    if (event.amountMinor <= 0 || event.fromUserId == event.toUserId) {
      emit(state.copyWith(actionError: 'settle_failed'));
      return;
    }
    emit(state.copyWith(busy: true, clearActionError: true));
    try {
      final now = DateTime.now();
      final settlement = Settlement(
        id: _uuid.v4(),
        groupId: group.id,
        fromUserId: event.fromUserId,
        toUserId: event.toUserId,
        amountMinor: event.amountMinor,
        currency: group.currency,
        note: event.note.trim(),
        settledAt: now,
        createdBy: user.id,
        createdAt: now,
        updatedAt: now,
      );
      await _saveSettlement(settlement);
      await _logActivity(
        ActivityEntry(
          id: _uuid.v4(),
          groupId: group.id,
          actorId: user.id,
          actorName: user.displayName,
          kind: ActivityKind.settlementAdded,
          summary: 'mencatat pelunasan ke ${_name(event.toUserId)}',
          createdAt: now,
        ),
      );
      if (event.toUserId != user.id) {
        await _sendNotification(
          AppNotification(
            id: _uuid.v4(),
            userId: event.toUserId,
            groupId: group.id,
            actorId: user.id,
            actorName: user.displayName,
            kind: AppNotificationKind.settlementAdded,
            title: 'Pelunasan diterima',
            body:
                '${user.displayName} mencatat pelunasan di ${group.name}. Cek detailnya biar tetap impas.',
            payload: {'amount_minor': event.amountMinor},
            createdAt: now,
          ),
        );
      }
      await _notifications.show(
        title: 'Pelunasan tercatat',
        body: '${group.name} · pembayaran sudah masuk riwayat.',
      );
      emit(
        state.copyWith(
          busy: false,
          actionNotice: 'settlement_saved',
          clearActionError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(busy: false, actionError: 'settle_failed'));
    }
  }

  Future<void> _onNudge(
    GroupDetailNudgeRequested event,
    Emitter<GroupDetailState> emit,
  ) async {
    final group = state.group;
    final user = _auth.currentUser;
    if (group == null || user == null) return;
    if (!group.memberCount.isNaN && event.targetUserId == user.id) return;
    final balance = state.summary.balanceFor(event.targetUserId);
    if (balance == null || balance.netMinor >= 0) {
      emit(state.copyWith(actionError: 'nudge_already_even'));
      return;
    }
    final target = state.memberFor(event.targetUserId);
    if (target == null) return;
    final amount = -balance.netMinor;
    final message = PoliteNudge.build(
      fromName: user.displayName,
      toName: target.displayName,
      groupName: group.name,
      amountMinor: amount,
      currency: group.currency,
      localeCode: 'id',
    );
    emit(state.copyWith(busy: true, clearActionError: true));
    try {
      await _sendNotification(
        AppNotification(
          id: _uuid.v4(),
          userId: target.userId,
          groupId: group.id,
          actorId: user.id,
          actorName: user.displayName,
          kind: AppNotificationKind.nudge,
          title: 'Colek halus dari ${user.displayName}',
          body: message,
          payload: {'amount_minor': amount},
          createdAt: DateTime.now(),
        ),
      );
      await _logActivity(
        ActivityEntry(
          id: _uuid.v4(),
          groupId: group.id,
          actorId: user.id,
          actorName: user.displayName,
          kind: ActivityKind.nudgeSent,
          summary: 'mengirim colek halus ke ${target.displayName}',
          createdAt: DateTime.now(),
        ),
      );
      emit(
        state.copyWith(
          busy: false,
          nudgeText: message,
          nudgeTargetName: target.displayName,
        ),
      );
    } catch (error) {
      emit(state.copyWith(busy: false, actionError: 'share_failed'));
    }
  }

  Future<void> _onDeleteExpense(
    GroupDetailDeleteExpenseRequested event,
    Emitter<GroupDetailState> emit,
  ) async {
    final group = state.group;
    final user = _auth.currentUser;
    if (group == null || user == null) return;
    emit(state.copyWith(busy: true, clearActionError: true));
    try {
      await _deleteExpense(event.expense);
      await _logActivity(
        ActivityEntry(
          id: _uuid.v4(),
          groupId: group.id,
          actorId: user.id,
          actorName: user.displayName,
          kind: ActivityKind.expenseDeleted,
          summary: 'menghapus ${event.expense.title}',
          createdAt: DateTime.now(),
        ),
      );
      emit(
        state.copyWith(
          busy: false,
          actionNotice: 'expense_deleted',
          clearActionError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(busy: false, actionError: 'save_failed'));
    }
  }

  Future<void> _onArchive(
    GroupDetailArchiveRequested event,
    Emitter<GroupDetailState> emit,
  ) async {
    final group = state.group;
    if (group == null) return;
    emit(state.copyWith(busy: true, clearActionError: true));
    try {
      await _archiveGroup(group.id);
      emit(
        state.copyWith(
          busy: false,
          archived: true,
          actionNotice: 'group_archived',
        ),
      );
    } catch (error) {
      emit(state.copyWith(busy: false, actionError: 'save_failed'));
    }
  }

  Future<void> _onExport(
    GroupDetailExportRequested event,
    Emitter<GroupDetailState> emit,
  ) async {
    final group = state.group;
    if (group == null) return;
    emit(state.copyWith(busy: true, clearActionError: true));
    try {
      final request = GroupExportRequest(
        currentUserId: state.currentUserId,
        group: group,
        members: state.members,
        expenses: state.expenses,
        settlements: state.settlements,
        summary: state.summary,
        activities: state.activities,
        localeCode: 'id',
      );
      if (event.pdf) {
        await _exportRepository.exportPdf(request);
      } else {
        await _exportRepository.exportCsv(request);
      }
      emit(
        state.copyWith(
          busy: false,
          actionNotice: event.pdf ? 'exported_pdf' : 'exported_csv',
        ),
      );
    } catch (error) {
      emit(state.copyWith(busy: false, actionError: 'save_failed'));
    }
  }

  void _onDismiss(
    GroupDetailMessageDismissed event,
    Emitter<GroupDetailState> emit,
  ) {
    emit(
      state.copyWith(
        clearActionError: true,
        clearActionNotice: true,
        clearNudge: true,
      ),
    );
  }

  String _name(String userId) =>
      state.memberFor(userId)?.displayName ?? 'Teman';

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _GroupDetailChanged extends GroupDetailEvent {
  const _GroupDetailChanged(this.snapshot, this.currentUserId);

  final _GroupSnapshot snapshot;
  final String? currentUserId;
}

class _GroupDetailFailed extends GroupDetailEvent {
  const _GroupDetailFailed(this.message);

  final String message;
}
