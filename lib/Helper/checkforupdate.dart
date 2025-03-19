import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_upgrade_version/flutter_upgrade_version.dart';

Future<void> checkForUpdate() async {
  if (Platform.isAndroid) {
    InAppUpdateManager manager = InAppUpdateManager();
    AppUpdateInfo? appUpdateInfo = await manager.checkForUpdate();
    if (appUpdateInfo == null) return;

    if (appUpdateInfo.updateAvailability ==
        UpdateAvailability.developerTriggeredUpdateInProgress) {
      // If an update is already in progress, resume it.
      String? message = await manager.startAnUpdate(type: AppUpdateType.immediate);
      debugPrint(message ?? '');
    } else if (appUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      // Update available: choose immediate or flexible based on what is allowed.
      if (appUpdateInfo.immediateAllowed) {
        String? message = await manager.startAnUpdate(type: AppUpdateType.immediate);
        debugPrint(message ?? '');
      } else if (appUpdateInfo.flexibleAllowed) {
        String? message = await manager.startAnUpdate(type: AppUpdateType.flexible);
        debugPrint(message ?? '');
      } else {
        debugPrint('Update available but neither immediate nor flexible update flow is allowed.');
      }
    }
  } else if (Platform.isIOS) {
    // For iOS, get the package info and then the App Store version.
    PackageInfo packageInfo = await PackageManager.getPackageInfo();
    VersionInfo? versionInfo = await UpgradeVersion.getiOSStoreVersion(
      packageInfo: packageInfo,
      regionCode: "US",
    );
    debugPrint(versionInfo.toJson().toString());
  }
}
