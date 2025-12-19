import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:disk_space_2/disk_space_2.dart';

class SystemService {
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<Map<String, dynamic>> getSystemData() async {
    final int level = await _battery.batteryLevel;

    final BatteryState state = await _battery.onBatteryStateChanged.first;
    final bool isCharging =
        state == BatteryState.charging || state == BatteryState.full;

    String deviceName = "Unknown Android";
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      deviceName = "${androidInfo.manufacturer} ${androidInfo.model}";
    }

    double? totalSpace = await DiskSpace.getTotalDiskSpace;
    double? freeSpace = await DiskSpace.getFreeDiskSpace;

    String storageInfo = "Unknown";
    double usedPercent = 0.0;

    if (totalSpace != null && freeSpace != null) {
      double usedSpace = totalSpace - freeSpace;
      usedPercent = usedSpace / totalSpace;

      storageInfo =
          "${(usedSpace / 1024).toStringAsFixed(1)} GB used of ${(totalSpace / 1024).toStringAsFixed(1)} GB";
    }

    return {
      'deviceName': deviceName,
      'batteryLevel': level,
      'isCharging': isCharging,
      'storageLabel': storageInfo,
      'storagePercent': usedPercent,
    };
  }
}
