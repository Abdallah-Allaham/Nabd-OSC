import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  static Future<bool> requestPermission(Permission permission) async {
    final status = await permission.status;
    if (status.isGranted) {
      return true;
    }
    final result = await permission.request();
    return result.isGranted;
  }
}
