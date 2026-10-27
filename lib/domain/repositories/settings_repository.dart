import 'package:bagi_fair/domain/entities/app_settings.dart';
import 'package:bagi_fair/domain/entities/user_profile.dart';

abstract interface class SettingsRepository {
  AppSettings get current;

  Stream<AppSettings> watch();

  Future<void> save(AppSettings settings);
}

abstract interface class ProfileRepository {
  Stream<UserProfile?> watchProfile(String userId);

  Future<UserProfile?> getProfile(String userId);

  Future<void> saveProfile(UserProfile profile);
}
