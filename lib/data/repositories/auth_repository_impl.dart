import 'dart:async';

import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

/// Supabase Auth backed by the on-device Hive scope.
///
/// The session itself is persisted by `supabase_flutter`; this class only maps
/// it to the domain [AppUser] and keeps the local cache scoped to the signed-in
/// user so two accounts on the same device never see each other's ledger.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._store, this._client) {
    _current = _restore();
  }

  final LocalStore _store;
  final SupabaseClient _client;

  AppUser? _current;

  @override
  bool get isConfigured => true;

  @override
  AppUser? get currentUser => _current;

  AppUser? _restore() {
    final user = _client.auth.currentUser;
    return user == null ? null : _mapSupabaseUser(user);
  }

  @override
  Stream<AppUser?> watchUser() {
    return Stream<AppUser?>.multi((controller) async {
      controller.add(_current);
      final subscription = _client.auth.onAuthStateChange.listen((state) {
        final user = state.session?.user;
        if (user != null) {
          unawaited(_store.ensureUserScope(user.id));
        }
        _current = user == null ? null : _mapSupabaseUser(user);
        if (!controller.isClosed) controller.add(_current);
      }, onError: controller.addError);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('no_session');
    }
    await _store.ensureUserScope(user.id);
    _current = _mapSupabaseUser(user);
    return _current!;
  }

  @override
  Future<AppUser?> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
    final user = response.user;
    if (response.session == null || user == null) {
      return null;
    }
    await _store.ensureUserScope(user.id);
    _current = _mapSupabaseUser(user);
    return _current;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _current = null;
    await _store.clearUserData();
  }

  AppUser _mapSupabaseUser(User user) {
    final metadata = user.userMetadata ?? const {};
    final name = (metadata['display_name'] as String?)?.trim();
    final fullName = (metadata['full_name'] as String?)?.trim();
    final email = user.email ?? '';
    final fallback = email.contains('@') ? email.split('@').first : 'Teman';
    return AppUser(
      id: user.id,
      displayName: (name?.isNotEmpty ?? false)
          ? name!
          : ((fullName?.isNotEmpty ?? false) ? fullName! : fallback),
      email: email,
      avatarUrl: metadata['avatar_url'] as String?,
    );
  }
}
