import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends GetxService {
  late SharedPreferences _prefs;

  // Keys
  static const String firstLaunchKey = 'first_launch';
  static const String userRoleKey = 'user_role';
  static const String introCompletedKey = 'intro_completed';

  // Observable values
  final RxBool isFirstLaunch = true.obs;
  final RxString userRole = ''.obs;
  final RxBool introCompleted = false.obs;

  Future<PreferencesService> init() async {
    print('Initializing PreferencesService');
    _prefs = await SharedPreferences.getInstance();

    // Load values from SharedPreferences
    isFirstLaunch.value = _prefs.getBool(firstLaunchKey) ?? true;
    userRole.value = _prefs.getString(userRoleKey) ?? '';
    introCompleted.value = _prefs.getBool(introCompletedKey) ?? false;

    print('PreferencesService initialized with: isFirstLaunch=${isFirstLaunch.value}, '
        'userRole=${userRole.value}, introCompleted=${introCompleted.value}');

    return this;
  }

  // Set first launch status
  Future<void> setFirstLaunch(bool value) async {
    print('Setting isFirstLaunch to $value');
    isFirstLaunch.value = value;
    await _prefs.setBool(firstLaunchKey, value);
  }

  // Set user role
  Future<void> setUserRole(String role) async {
    print('Setting userRole to $role');
    userRole.value = role;
    await _prefs.setString(userRoleKey, role);
  }

  // Set intro completed status
  Future<void> setIntroCompleted(bool value) async {
    print('Setting introCompleted to $value');
    introCompleted.value = value;
    await _prefs.setBool(introCompletedKey, value);
  }

  // Reset all preferences (for logout)
  Future<void> resetPreferences() async {
    print('Resetting all preferences');
    await _prefs.clear();
    isFirstLaunch.value = true;
    userRole.value = '';
    introCompleted.value = false;
  }

  // For testing: force first launch
  Future<void> forceFirstLaunch() async {
    print('Forcing first launch');
    await setFirstLaunch(true);
    await _prefs.remove(userRoleKey);
    await _prefs.remove(introCompletedKey);
    userRole.value = '';
    introCompleted.value = false;
  }
}
