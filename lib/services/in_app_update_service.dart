import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:get/get.dart';

class InAppUpdateService extends GetxController {
  bool isUpdateAvailable = false;

  @override
  void onInit() {
    super.onInit();
    checkForUpdate();
  }

  Future<void> checkForUpdate() async {
    try {
      await InAppUpdate.checkForUpdate().then((updateInfo) {
        if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
          isUpdateAvailable = true;
          _showUpdateDialog(updateInfo);
        }
      });
    } catch (e) {
      print('Error checking for update: $e');
    }
  }

  void _showUpdateDialog(AppUpdateInfo updateInfo) {
    Get.dialog(
      AlertDialog(
        title: const Text('Update Available'),
        content: const Text(
          'A new version of KorLinks is available. Please update to the latest version for the best experience.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Later', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              _performUpdate(updateInfo);
              Get.back();
            },
            child: const Text('Update Now', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _performUpdate(AppUpdateInfo updateInfo) async {
    try {
      if (updateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate().then((_) {
          InAppUpdate.completeFlexibleUpdate();
        });
      } else if (updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      print('Error performing update: $e');
    }
  }
}
