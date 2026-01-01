import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Check if all required permissions are granted
  static Future<bool> hasAllPermissions() async {
    final permissions = await _getRequiredPermissions();

    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }

    return true;
  }

  /// Request all required permissions
  static Future<Map<Permission, PermissionStatus>>
  requestAllPermissions() async {
    final permissions = await _getRequiredPermissions();
    return await permissions.request();
  }

  /// Check specific permission
  static Future<bool> hasPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Request specific permission
  static Future<PermissionStatus> requestPermission(
    Permission permission,
  ) async {
    return await permission.request();
  }

  /// Open app settings
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Get list of required permissions based on Android
  static Future<List<Permission>> _getRequiredPermissions() async {
    final permissions = <Permission>[];

    // Storage permissions (Android 13+)
    if (await _isAndroid13OrHigher()) {
      permissions.addAll([Permission.manageExternalStorage]);
    } else {
      // Legacy storage permission (Android 12 and below)
      permissions.add(Permission.storage);
    }

    // Additional permissions
    permissions.addAll([Permission.camera]);
    permissions.addAll([Permission.camera, Permission.contacts]);

    return permissions;
  }

  /// Check if device is running Android 13 or higher
  static Future<bool> _isAndroid13OrHigher() async {
    try {
      await Permission.photos.status;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get permission status details
  static Future<Map<String, bool>> getPermissionStatuses() async {
    final permissions = await _getRequiredPermissions();
    final statuses = <String, bool>{};

    for (final permission in permissions) {
      final status = await permission.status;
      statuses[permission.toString()] = status.isGranted;
    }

    return statuses;
  }

  /// Check if we should show rationale
  static Future<bool> shouldShowRationale(Permission permission) async {
    return await permission.shouldShowRequestRationale;
  }
}
