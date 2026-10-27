import 'package:bagi_fair/domain/repositories/group_repository.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JoinGroupState extends Equatable {
  const JoinGroupState({
    this.joining = false,
    this.joined = false,
    this.errorCode,
  });

  final bool joining;
  final bool joined;
  final String? errorCode;

  JoinGroupState copyWith({
    bool? joining,
    bool? joined,
    String? errorCode,
    bool clearError = false,
  }) {
    return JoinGroupState(
      joining: joining ?? this.joining,
      joined: joined ?? this.joined,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [joining, joined, errorCode];
}

sealed class JoinGroupEvent extends Equatable {
  const JoinGroupEvent();

  @override
  List<Object?> get props => const [];
}

class JoinGroupSubmitted extends JoinGroupEvent {
  const JoinGroupSubmitted(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class JoinGroupBloc extends Bloc<JoinGroupEvent, JoinGroupState> {
  JoinGroupBloc(this._join) : super(const JoinGroupState()) {
    on<JoinGroupSubmitted>(_onSubmitted);
  }

  final JoinGroupByCode _join;

  Future<void> _onSubmitted(
    JoinGroupSubmitted event,
    Emitter<JoinGroupState> emit,
  ) async {
    final code = event.code.trim().toUpperCase();
    if (code.length < 4) {
      emit(state.copyWith(errorCode: 'invalid_code'));
      return;
    }
    emit(state.copyWith(joining: true, clearError: true));
    try {
      await _join(code);
      emit(state.copyWith(joining: false, joined: true));
    } on GroupJoinException catch (error) {
      emit(state.copyWith(joining: false, errorCode: error.code));
    } catch (error) {
      final text = error.toString().toLowerCase();
      final code = text.contains('expired')
          ? 'invite_expired'
          : text.contains('not found') || text.contains('invalid')
          ? 'invite_not_found'
          : text.contains('already')
          ? 'already_member'
          : 'join_failed';
      emit(state.copyWith(joining: false, errorCode: code));
    }
  }
}
