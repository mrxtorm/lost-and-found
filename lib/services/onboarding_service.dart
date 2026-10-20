import 'package:shared_preferences/shared_preferences.dart';

/// Remembers, per user and per device, whether the app tour has been
/// offered. The tour is optional: once the user takes it or declines it they
/// are not asked again, but it can be replayed from Profile or Help & Support.
class OnboardingService {
  /// Bump to offer the tour again after it changes significantly.
  static const int tourVersion = 1;

  String _key(String uid) => 'onboarding_offered_${uid}_v$tourVersion';

  Future<bool> hasBeenOffered(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(uid)) ?? false;
  }

  Future<void> markOffered(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(uid), true);
  }
}
