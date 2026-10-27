import 'package:bagi_fair/domain/entities/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => message ?? code;
}

/// Email/password authentication against Supabase Auth.
///
/// Google sign-in is deliberately out of scope for now (the provider is not
/// configured on the project), so the interface has no OAuth method.
abstract interface class AuthRepository {
  bool get isConfigured;

  AppUser? get currentUser;

  Stream<AppUser?> watchUser();

  Future<AppUser> signInWithEmail(String email, String password);

  Future<AppUser?> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
