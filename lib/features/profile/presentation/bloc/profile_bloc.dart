import 'dart:async';

import 'package:bagi_fair/domain/entities/user_profile.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/repositories/settings_repository.dart';
import 'package:bagi_fair/domain/usecases/settings_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.loading = true,
    this.profile,
    this.displayName = '',
    this.defaultCurrency = 'IDR',
    this.saving = false,
    this.saved = false,
    this.errorCode,
  });

  final bool loading;
  final UserProfile? profile;
  final String displayName;
  final String defaultCurrency;
  final bool saving;
  final bool saved;
  final String? errorCode;

  ProfileState copyWith({
    bool? loading,
    UserProfile? profile,
    String? displayName,
    String? defaultCurrency,
    bool? saving,
    bool? saved,
    String? errorCode,
    bool clearError = false,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      profile: profile ?? this.profile,
      displayName: displayName ?? this.displayName,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    profile,
    displayName,
    defaultCurrency,
    saving,
    saved,
    errorCode,
  ];
}

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => const [];
}

class ProfileStarted extends ProfileEvent {
  const ProfileStarted(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ProfileNameChanged extends ProfileEvent {
  const ProfileNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class ProfileCurrencyChanged extends ProfileEvent {
  const ProfileCurrencyChanged(this.currency);

  final String currency;

  @override
  List<Object?> get props => [currency];
}

class ProfileSubmitted extends ProfileEvent {
  const ProfileSubmitted();
}

class ProfileMessageDismissed extends ProfileEvent {
  const ProfileMessageDismissed();
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(
    this._watchProfile,
    this._getProfile,
    this._saveProfile,
    this._auth,
    this._settingsRepository,
  ) : super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileNameChanged>(_onName);
    on<ProfileCurrencyChanged>(_onCurrency);
    on<ProfileSubmitted>(_onSubmitted);
    on<ProfileMessageDismissed>(_onDismiss);
    on<_ProfileChanged>(_onChanged);
    on<_ProfileFailed>(_onFailed);
  }

  final WatchProfile _watchProfile;
  final GetProfile _getProfile;
  final SaveProfile _saveProfile;
  final AuthRepository _auth;
  final SettingsRepository _settingsRepository;

  StreamSubscription<UserProfile?>? _subscription;
  String? _userId;

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    _userId = event.userId;
    emit(state.copyWith(loading: true, clearError: true));
    final user = _auth.currentUser;
    final existing = await _getProfile(event.userId);
    final profile =
        existing ??
        UserProfile(
          id: event.userId,
          displayName: user?.displayName ?? 'Pengguna',
          email: user?.email ?? '',
          avatarUrl: user?.avatarUrl,
          defaultCurrency: _settingsRepository.current.defaultCurrency,
          localeCode: _settingsRepository.current.localeCode,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    emit(
      state.copyWith(
        loading: false,
        profile: profile,
        displayName: profile.displayName,
        defaultCurrency: profile.defaultCurrency,
        clearError: true,
      ),
    );

    await _subscription?.cancel();
    _subscription = _watchProfile(event.userId).listen(
      (value) => add(_ProfileChanged(value)),
      onError: (Object error) => add(_ProfileFailed(error.toString())),
    );
  }

  void _onChanged(_ProfileChanged event, Emitter<ProfileState> emit) {
    final profile = event.profile;
    if (profile == null) return;
    emit(
      state.copyWith(
        loading: false,
        profile: profile,
        displayName: profile.displayName,
        defaultCurrency: profile.defaultCurrency,
        clearError: true,
      ),
    );
  }

  void _onFailed(_ProfileFailed event, Emitter<ProfileState> emit) {
    emit(state.copyWith(loading: false, errorCode: 'load_failed'));
  }

  void _onName(ProfileNameChanged event, Emitter<ProfileState> emit) {
    emit(
      state.copyWith(displayName: event.name, saved: false, clearError: true),
    );
  }

  void _onCurrency(ProfileCurrencyChanged event, Emitter<ProfileState> emit) {
    emit(
      state.copyWith(
        defaultCurrency: event.currency,
        saved: false,
        clearError: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    ProfileSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    final profile = state.profile;
    if (profile == null || _userId == null) return;
    final name = state.displayName.trim();
    if (name.isEmpty) {
      emit(state.copyWith(errorCode: 'name_required'));
      return;
    }
    emit(state.copyWith(saving: true, saved: false, clearError: true));
    try {
      final settings = _settingsRepository.current;
      await _saveProfile(
        profile.copyWith(
          displayName: name,
          defaultCurrency: state.defaultCurrency,
          localeCode: settings.localeCode,
          updatedAt: DateTime.now(),
        ),
      );
      emit(state.copyWith(saving: false, saved: true, clearError: true));
    } catch (error) {
      emit(state.copyWith(saving: false, errorCode: 'save_failed'));
    }
  }

  void _onDismiss(ProfileMessageDismissed event, Emitter<ProfileState> emit) {
    emit(state.copyWith(clearError: true, saved: false));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _ProfileChanged extends ProfileEvent {
  const _ProfileChanged(this.profile);

  final UserProfile? profile;
}

class _ProfileFailed extends ProfileEvent {
  const _ProfileFailed(this.message);

  final String message;
}
