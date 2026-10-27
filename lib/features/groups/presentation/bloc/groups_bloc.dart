import 'dart:async';

import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/entities/home_overview.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:bagi_fair/domain/usecases/home_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GroupsState extends Equatable {
  const GroupsState({
    this.loading = true,
    this.groups = const [],
    this.query = '',
    this.error,
    this.netByGroup = const {},
  });

  final bool loading;
  final List<Group> groups;
  final String query;
  final String? error;

  /// Net position per group id: positive means the group owes you.
  final Map<String, int> netByGroup;

  List<Group> get filtered {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return groups;
    return groups
        .where(
          (group) =>
              group.name.toLowerCase().contains(needle) ||
              group.description.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  GroupsState copyWith({
    bool? loading,
    List<Group>? groups,
    String? query,
    String? error,
    Map<String, int>? netByGroup,
    bool clearError = false,
  }) {
    return GroupsState(
      loading: loading ?? this.loading,
      groups: groups ?? this.groups,
      query: query ?? this.query,
      error: clearError ? null : (error ?? this.error),
      netByGroup: netByGroup ?? this.netByGroup,
    );
  }

  @override
  List<Object?> get props => [loading, groups, query, error, netByGroup];
}

sealed class GroupsEvent extends Equatable {
  const GroupsEvent();

  @override
  List<Object?> get props => const [];
}

class GroupsStarted extends GroupsEvent {
  const GroupsStarted({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class GroupsQueryChanged extends GroupsEvent {
  const GroupsQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class GroupsRefreshRequested extends GroupsEvent {
  const GroupsRefreshRequested();
}

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  GroupsBloc(this._watchGroups, this._watchOverview)
    : super(const GroupsState()) {
    on<GroupsStarted>(_onStarted);
    on<GroupsQueryChanged>(_onQuery);
    on<GroupsRefreshRequested>(_onRefresh);
    on<_GroupsChanged>(_onChanged);
    on<_OverviewChanged>(_onOverview);
    on<_GroupsFailed>(_onFailed);
  }

  final WatchGroups _watchGroups;
  final WatchHomeOverview _watchOverview;
  StreamSubscription<List<Group>>? _subscription;
  StreamSubscription<HomeOverview>? _overviewSubscription;

  Future<void> _onStarted(
    GroupsStarted event,
    Emitter<GroupsState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    await _subscription?.cancel();
    _subscription = _watchGroups().listen(
      (groups) => add(_GroupsChanged(groups)),
      onError: (Object error) => add(_GroupsFailed(error.toString())),
    );

    await _overviewSubscription?.cancel();
    _overviewSubscription = _watchOverview(
      currentUserId: event.userId,
    ).listen(
      (overview) => add(
        _OverviewChanged({
          for (final item in overview.groups)
            item.group.id:
                item.summary.youAreOwedMinor - item.summary.youOweMinor,
        }),
      ),
      onError: (Object error) {},
    );
  }

  Future<void> _onRefresh(
    GroupsRefreshRequested event,
    Emitter<GroupsState> emit,
  ) async {
    emit(state.copyWith(clearError: true));
  }

  void _onQuery(GroupsQueryChanged event, Emitter<GroupsState> emit) {
    emit(state.copyWith(query: event.query));
  }

  void _onChanged(_GroupsChanged event, Emitter<GroupsState> emit) {
    emit(
      state.copyWith(loading: false, groups: event.groups, clearError: true),
    );
  }

  void _onOverview(_OverviewChanged event, Emitter<GroupsState> emit) {
    emit(state.copyWith(netByGroup: event.netByGroup));
  }

  void _onFailed(_GroupsFailed event, Emitter<GroupsState> emit) {
    emit(state.copyWith(loading: false, error: event.message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _overviewSubscription?.cancel();
    return super.close();
  }
}

class _GroupsChanged extends GroupsEvent {
  const _GroupsChanged(this.groups);

  final List<Group> groups;
}

class _OverviewChanged extends GroupsEvent {
  const _OverviewChanged(this.netByGroup);

  final Map<String, int> netByGroup;
}

class _GroupsFailed extends GroupsEvent {
  const _GroupsFailed(this.message);

  final String message;
}
