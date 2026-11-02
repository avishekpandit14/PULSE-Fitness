import '../datasources/database_helper.dart';
import '../../domain/models/user_profile.dart';

class UserRepository {
  final DatabaseHelper _dbHelper;

  UserRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<UserProfile> getUserProfile() async {
    return await _dbHelper.getUserProfile();
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _dbHelper.saveUserProfile(profile);
  }

  Future<void> updateDemoMode(bool isDemoMode) async {
    final current = await getUserProfile();
    final updated = current.copyWith(isDemoMode: isDemoMode);
    await saveUserProfile(updated);
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    final completed = profile.copyWith(onboardingCompleted: true);
    await saveUserProfile(completed);
  }

  Future<void> clearAllUserData() async {
    await _dbHelper.clearAllData();
  }
}
