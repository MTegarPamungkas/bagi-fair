import 'dart:async';

import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:bagi_fair/domain/usecases/auth_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthStatus { resolving, signedOut, signedIn }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.resolving,
    this.user,
    this.busy = false,
    this.errorCode,
    this.errorMessage,
    this.notice,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool busy;
  final String? errorCode;
  final String? errorMessage;
  final String? notice;

  bool get resolving => status == AuthStatus.resolving;

  bool get signedIn => status == AuthStatus.signedIn && user != null;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? busy,
    String? errorCode,
    String? errorMessage,
    String? notice,
    bool clearError = false,
    bool clearUser = false,
    bool clearNotice = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      busy: busy ?? this.busy,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    busy,
    errorCode,
    errorMessage,
    notice,
  ];
}

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthEmailRequested extends AuthEvent {
  const AuthEmailRequested({
    required this.email,
    required this.password,
    required this.isSignUp,
    this.displayName = '',
  });

  final String email;
  final String password;
  final bool isSignUp;
  final String displayName;

  @override
  List<Object?> get props => [email, password, isSignUp, displayName];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthMessageDismissed extends AuthEvent {
  const AuthMessageDismissed();
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._watchUser,
    this._signIn,
    this._signUp,
    this._signOut,
    this._repository,
  ) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthEmailRequested>(_onEmail);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthMessageDismissed>(_onDismiss);
    on<_AuthUserChanged>(_onUserChanged);
    add(const AuthStarted());
  }

  final WatchAuthUser _watchUser;
  final SignInWithEmail _signIn;
  final SignUpWithEmail _signUp;
  final SignOut _signOut;
  final AuthRepository _repository;

  StreamSubscription<AppUser?>? _subscription;

  bool get isConfigured => _repository.isConfigured;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final current = _repository.currentUser;
    if (current != null) {
      emit(
        state.copyWith(status: AuthStatus.signedIn, user: current, busy: false),
      );
    } else {
      emit(state.copyWith(status: AuthStatus.signedOut, busy: false));
    }

    await _subscription?.cancel();
    _subscription = _watchUser().listen((user) {
      if (isClosed) return;
      if (user == null) {
        add(const _AuthUserChanged(null));
      } else {
        add(_AuthUserChanged(user));
      }
    });
  }

  Future<void> _onEmail(
    AuthEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!isConfigured) {
      emit(state.copyWith(busy: false, errorCode: 'network'));
      return;
    }
    final email = event.email.trim();
    if (!email.contains('@')) {
      emit(state.copyWith(busy: false, errorCode: 'email_invalid'));
      return;
    }
    if (event.password.length < 6) {
      emit(state.copyWith(busy: false, errorCode: 'password_short'));
      return;
    }
    emit(state.copyWith(busy: true, clearError: true, clearNotice: true));
    try {
      if (event.isSignUp) {
        final user = await _signUp(
          displayName: event.displayName.trim().isEmpty
              ? email.split('@').first
              : event.displayName,
          email: email,
          password: event.password,
        );
        if (user == null) {
          emit(
            state.copyWith(
              busy: false,
              notice: 'confirm_email',
              status: AuthStatus.signedOut,
            ),
          );
        } else {
          emit(
            state.copyWith(
              busy: false,
              status: AuthStatus.signedIn,
              user: user,
            ),
          );
        }
      } else {
        final user = await _signIn(email: email, password: event.password);
        emit(
          state.copyWith(busy: false, status: AuthStatus.signedIn, user: user),
        );
      }
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          busy: false,
          errorCode: error.code,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          busy: false,
          errorCode: _mapNetworkError(error),
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(busy: true));
    try {
      await _signOut();
    } catch (_) {
      // Signing out locally still succeeds even if the network call fails.
    }
    emit(const AuthState(status: AuthStatus.signedOut, busy: false));
  }

  void _onDismiss(AuthMessageDismissed event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearError: true, clearNotice: true));
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user == null) {
      emit(
        state.copyWith(
          status: AuthStatus.signedOut,
          user: null,
          clearUser: true,
        ),
      );
    } else {
      emit(
        state.copyWith(status: AuthStatus.signedIn, user: user, busy: false),
      );
    }
  }

  String _mapNetworkError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('invalid login credentials')) {
      return 'invalid_credentials';
    }
    if (text.contains('email not confirmed')) return 'email_not_confirmed';
    if (text.contains('already registered') ||
        text.contains('already exists')) {
      return 'email_in_use';
    }
    if (text.contains('rate limit') || text.contains('security purposes')) {
      return 'rate_limited';
    }
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('connection')) {
      return 'network';
    }
    return 'something_wrong';
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}
