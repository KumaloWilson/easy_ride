import 'package:get/get.dart';
import 'package:easy_ride/core/services/preferences_service.dart';
import 'package:easy_ride/routes/app_pages.dart';

class OnboardingController extends GetxController {
  final PreferencesService _prefsService = Get.find<PreferencesService>();

  final RxInt currentPage = 0.obs;
  final RxBool isLastPage = false.obs;

  @override
  void onInit() {
    super.onInit();
    print('OnboardingController initialized');
  }

  void setCurrentPage(int page) {
    currentPage.value = page;
    // For intro screens, check if it's the last page (3 for 0-indexed)
    isLastPage.value = (page == 3);
  }

  Future<void> selectRole(String role) async {
    print('Role selected: $role');
    await _prefsService.setUserRole(role);
    await _prefsService.setFirstLaunch(false);

    // Navigate to appropriate intro screen
    if (role == 'rider') {
      Get.offAllNamed(Routes.riderIntro);
    } else {
      Get.offAllNamed(Routes.driverIntro);
    }
  }

  Future<void> completeIntro() async {
    print('Intro completed');
    await _prefsService.setIntroCompleted(true);
    Get.offAllNamed(Routes.register);
  }

  Future<void> skipIntro() async {
    print('Intro skipped');
    await _prefsService.setIntroCompleted(true);
    Get.offAllNamed(Routes.register);
  }
}
