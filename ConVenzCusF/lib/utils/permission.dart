import 'package:permission_handler/permission_handler.dart';

class PermissionService {

  // We make the function 'static' so you can call it
  // without creating an instance of the class.
  static Future<void> requestInitialPermissions() async {
    // Check and request Location
    var locationStatus = await Permission.location.status;

    // .isDenied includes "not asked yet" or "denied once".
    if (locationStatus.isDenied) {
      await Permission.location.request();
    }

    // Check and request Notification
    var notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied) {
      await Permission.notification.request();
    }

    // As you requested, we don't do anything if it's permanentlyDenied
  }
}
