import 'package:bagi_fair/domain/entities/app_settings.dart';
import 'package:bagi_fair/domain/entities/user_profile.dart';
import 'package:bagi_fair/domain/repositories/settings_repository.dart';

class WatchSettings {
  const WatchSettings(this._repository);

  final SettingsRepository _repository;

  Stream<AppSettings> call() => _repository.watch();
}

class GetSettings {
  const GetSettings(this._repository);

  final SettingsRepository _repository;

  AppSettings call() => _repository.current;
}

class UpdateSettings {
  const UpdateSettings(this._repository);

  final SettingsRepository _repository;

  Future<void> call(AppSettings settings) => _repository.save(settings);
}

class WatchProfile {
  const WatchProfile(this._repository);

  final ProfileRepository _repository;

  Stream<UserProfile?> call(String userId) => _repository.watchProfile(userId);
}

class GetProfile {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  Future<UserProfile?> call(String userId) => _repository.getProfile(userId);
}

class SaveProfile {
  const SaveProfile(this._repository);

  final ProfileRepository _repository;

  Future<void> call(UserProfile profile) => _repository.saveProfile(profile);
}
