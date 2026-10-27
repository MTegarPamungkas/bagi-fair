import 'package:bagi_fair/domain/entities/app_user.dart';
import 'package:bagi_fair/domain/repositories/auth_repository.dart';

class WatchAuthUser {
  const WatchAuthUser(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.watchUser();
}

class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) =>
      _repository.signInWithEmail(email, password);
}

class SignUpWithEmail {
  const SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser?> call({
    required String displayName,
    required String email,
    required String password,
  }) => _repository.signUpWithEmail(
    displayName: displayName,
    email: email,
    password: password,
  );
}

class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
