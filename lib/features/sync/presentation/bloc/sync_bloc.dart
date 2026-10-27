import 'dart:async';

import 'package:bagi_fair/domain/entities/sync_status.dart';
import 'package:bagi_fair/domain/usecases/sync_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class SyncEvent {
  const SyncEvent();
}

class SyncStarted extends SyncEvent {
  const SyncStarted();
}

class SyncRequested extends SyncEvent {
  const SyncRequested();
}

class SyncBloc extends Bloc<SyncEvent, SyncStatus> {
  SyncBloc(this._watch, this._syncNow) : super(const SyncStatus()) {
    on<SyncStarted>(_onStarted);
    on<SyncRequested>(_onRequested);
    on<_SyncChanged>(_onChanged);
    add(const SyncStarted());
  }

  final WatchSyncStatus _watch;
  final SyncNow _syncNow;
  StreamSubscription<SyncStatus>? _subscription;

  Future<void> _onStarted(SyncStarted event, Emitter<SyncStatus> emit) async {
    await _subscription?.cancel();
    _subscription = _watch().listen((status) {
      if (!isClosed) add(_SyncChanged(status));
    });
  }

  Future<void> _onRequested(
    SyncRequested event,
    Emitter<SyncStatus> emit,
  ) async {
    await _syncNow();
  }

  void _onChanged(_SyncChanged event, Emitter<SyncStatus> emit) {
    emit(event.status);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _SyncChanged extends SyncEvent {
  const _SyncChanged(this.status);

  final SyncStatus status;
}
