import 'package:flutter/foundation.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  UserProfile _profile = const UserProfile();
  bool _isLoading = true;

  UserProvider({UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository();

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isDemoMode => _profile.isDemoMode;
  bool get onboardingCompleted => _profile.onboardingCompleted;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _userRepository.getUserProfile();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile updated) async {
    _profile = updated;
    notifyListeners();
    await _userRepository.saveUserProfile(updated);
  }

  Future<void> toggleDemoMode(bool enable) async {
    _profile = _profile.copyWith(isDemoMode: enable);
    notifyListeners();
    await _userRepository.updateDemoMode(enable);
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    _profile = profile.copyWith(onboardingCompleted: true);
    notifyListeners();
    await _userRepository.completeOnboarding(_profile);
  }

  Future<void> resetAllData() async {
    await _userRepository.clearAllUserData();
    _profile = const UserProfile();
    notifyListeners();
  }
}
