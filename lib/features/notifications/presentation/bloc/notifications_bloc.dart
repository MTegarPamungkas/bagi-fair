import 'dart:async';

import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:bagi_fair/domain/usecases/notification_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.loading = true,
    this.notifications = const [],
    this.error,
  });

  final bool loading;
  final List<AppNotification> notifications;
  final String? error;

  int get unreadCount =>
      notifications.where((notification) => notification.isUnread).length;

  NotificationsState copyWith({
    bool? loading,
    List<AppNotification>? notifications,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      loading: loading ?? this.loading,
      notifications: notifications ?? this.notifications,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [loading, notifications, error];
}

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => const [];
}

class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class NotificationReadRequested extends NotificationsEvent {
  const NotificationReadRequested(this.notification);

  final AppNotification notification;

  @override
  List<Object?> get props => [notification];
}

class NotificationsAllReadRequested extends NotificationsEvent {
  const NotificationsAllReadRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class NotificationsRefreshRequested extends NotificationsEvent {
  const NotificationsRefreshRequested();
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc(this._watch, this._markRead, this._markAllRead)
    : super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationReadRequested>(_onRead);
    on<NotificationsAllReadRequested>(_onAllRead);
    on<NotificationsRefreshRequested>(_onRefresh);
    on<_NotificationsChanged>(_onChanged);
    on<_NotificationsFailed>(_onFailed);
  }

  final WatchNotifications _watch;
  final MarkNotificationRead _markRead;
  final MarkAllNotificationsRead _markAllRead;

  StreamSubscription<List<AppNotification>>? _subscription;

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    await _subscription?.cancel();
    _subscription = _watch(event.userId).listen(
      (items) => add(_NotificationsChanged(items)),
      onError: (Object error) => add(_NotificationsFailed(error.toString())),
    );
  }

  Future<void> _onRead(
    NotificationReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _markRead(event.notification);
  }

  Future<void> _onAllRead(
    NotificationsAllReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _markAllRead(event.userId);
  }

  Future<void> _onRefresh(
    NotificationsRefreshRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(state.copyWith(clearError: true));
  }

  void _onChanged(
    _NotificationsChanged event,
    Emitter<NotificationsState> emit,
  ) {
    emit(
      state.copyWith(
        loading: false,
        notifications: event.notifications,
        clearError: true,
      ),
    );
  }

  void _onFailed(_NotificationsFailed event, Emitter<NotificationsState> emit) {
    emit(state.copyWith(loading: false, error: event.message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _NotificationsChanged extends NotificationsEvent {
  const _NotificationsChanged(this.notifications);

  final List<AppNotification> notifications;
}

class _NotificationsFailed extends NotificationsEvent {
  const _NotificationsFailed(this.message);

  final String message;
}
