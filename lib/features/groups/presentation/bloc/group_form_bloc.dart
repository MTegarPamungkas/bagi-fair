import 'package:bagi_fair/domain/entities/group.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/usecases/group_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class GroupFormState extends Equatable {
  const GroupFormState({
    this.submitting = false,
    this.createdGroupId,
    this.errorCode,
  });

  final bool submitting;
  final String? createdGroupId;
  final String? errorCode;

  bool get created => createdGroupId != null;

  GroupFormState copyWith({
    bool? submitting,
    String? createdGroupId,
    String? errorCode,
    bool clearError = false,
  }) {
    return GroupFormState(
      submitting: submitting ?? this.submitting,
      createdGroupId: createdGroupId ?? this.createdGroupId,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [submitting, createdGroupId, errorCode];
}

sealed class GroupFormEvent extends Equatable {
  const GroupFormEvent();

  @override
  List<Object?> get props => const [];
}

class GroupFormSubmitted extends GroupFormEvent {
  const GroupFormSubmitted({
    required this.name,
    required this.description,
    required this.emoji,
    required this.type,
    required this.currency,
  });

  final String name;
  final String description;
  final String emoji;
  final GroupType type;
  final String currency;

  @override
  List<Object?> get props => [name, description, emoji, type, currency];
}

class GroupFormBloc extends Bloc<GroupFormEvent, GroupFormState> {
  GroupFormBloc(this._createGroup, this._auth, this._uuid)
    : super(const GroupFormState()) {
    on<GroupFormSubmitted>(_onSubmitted);
  }

  final CreateGroup _createGroup;
  final AuthRepository _auth;
  final Uuid _uuid;

  Future<void> _onSubmitted(
    GroupFormSubmitted event,
    Emitter<GroupFormState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(errorCode: 'name_required'));
      return;
    }
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(errorCode: 'not_signed_in'));
      return;
    }
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final now = DateTime.now();
      final group = Group(
        id: _uuid.v4(),
        name: name,
        description: event.description.trim(),
        emoji: event.emoji.trim().isEmpty ? '🎉' : event.emoji.trim(),
        type: event.type,
        currency: event.currency,
        ownerId: user.id,
        memberCount: 1,
        myRole: GroupRole.owner,
        createdAt: now,
        updatedAt: now,
      );
      await _createGroup(group);
      emit(
        state.copyWith(
          submitting: false,
          createdGroupId: group.id,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(submitting: false, errorCode: 'save_failed'));
    }
  }
}
