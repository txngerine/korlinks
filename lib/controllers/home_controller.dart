import 'package:get/get.dart';

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  var isLoading = false.obs;
  bool hasLoadedInitially = false; // track if shimmer shown once

  void loadPage(int index) {
    selectedIndex.value = index;

    if (index == 0 && !hasLoadedInitially) {
      // Show shimmer only once for tab 0 on first load
      isLoading.value = true;
      Future.delayed(Duration(seconds: 10), () {
        isLoading.value = false;
        hasLoadedInitially = true;
      });
    } else {
      // Immediately show content
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadPage(0); // load first tab on start
  }
}
