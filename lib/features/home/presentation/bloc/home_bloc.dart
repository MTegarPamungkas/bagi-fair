import 'dart:async';

import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:bagi_fair/domain/entities/home_overview.dart';
import 'package:bagi_fair/domain/usecases/home_usecases.dart';
import 'package:bagi_fair/domain/usecases/notification_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState extends Equatable {
  const HomeState({
    this.loading = true,
    this.overview = const HomeOverview(),
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
  });

  final bool loading;
  final HomeOverview overview;
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? error;

  HomeState copyWith({
    bool? loading,
    HomeOverview? overview,
    List<AppNotification>? notifications,
    int? unreadCount,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      loading: loading ?? this.loading,
      overview: overview ?? this.overview,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    overview,
    notifications,
    unreadCount,
    error,
  ];
}

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => const [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

class HomeNotificationsRead extends HomeEvent {
  const HomeNotificationsRead(this.notification);

  final AppNotification notification;

  @override
  List<Object?> get props => [notification];
}

class HomeAllNotificationsRead extends HomeEvent {
  const HomeAllNotificationsRead(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(
    this._watchOverview,
    this._watchNotifications,
    this._markRead,
    this._markAllRead,
  ) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshRequested>(_onRefresh);
    on<HomeNotificationsRead>(_onRead);
    on<HomeAllNotificationsRead>(_onAllRead);
    on<_OverviewChanged>(_onOverview);
    on<_NotificationsChanged>(_onNotifications);
    on<_HomeFailed>(_onFailed);
  }

  final WatchHomeOverview _watchOverview;
  final WatchNotifications _watchNotifications;
  final MarkNotificationRead _markRead;
  final MarkAllNotificationsRead _markAllRead;

  StreamSubscription<HomeOverview>? _overviewSubscription;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    await _overviewSubscription?.cancel();
    await _notificationSubscription?.cancel();

    _overviewSubscription = _watchOverview(currentUserId: event.userId).listen(
      (overview) => add(_OverviewChanged(overview)),
      onError: (Object error) => add(_HomeFailed(error.toString())),
    );
    _notificationSubscription = _watchNotifications(event.userId).listen(
      (items) => add(_NotificationsChanged(items)),
      onError: (Object error) => add(_HomeFailed(error.toString())),
    );
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    // Local streams are already live; a refresh just clears transient errors.
    emit(state.copyWith(clearError: true));
  }

  Future<void> _onRead(
    HomeNotificationsRead event,
    Emitter<HomeState> emit,
  ) async {
    await _markRead(event.notification);
  }

  Future<void> _onAllRead(
    HomeAllNotificationsRead event,
    Emitter<HomeState> emit,
  ) async {
    await _markAllRead(event.userId);
  }

  void _onOverview(_OverviewChanged event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        loading: false,
        overview: event.overview,
        clearError: true,
      ),
    );
  }

  void _onNotifications(_NotificationsChanged event, Emitter<HomeState> emit) {
    emit(
      state.copyWith(
        notifications: event.notifications,
        unreadCount: event.notifications.where((item) => item.isUnread).length,
      ),
    );
  }

  void _onFailed(_HomeFailed event, Emitter<HomeState> emit) {
    emit(state.copyWith(loading: false, error: event.message));
  }

  @override
  Future<void> close() async {
    await _overviewSubscription?.cancel();
    await _notificationSubscription?.cancel();
    return super.close();
  }
}

class _OverviewChanged extends HomeEvent {
  const _OverviewChanged(this.overview);

  final HomeOverview overview;
}

class _NotificationsChanged extends HomeEvent {
  const _NotificationsChanged(this.notifications);

  final List<AppNotification> notifications;
}

class _HomeFailed extends HomeEvent {
  const _HomeFailed(this.message);

  final String message;
}
