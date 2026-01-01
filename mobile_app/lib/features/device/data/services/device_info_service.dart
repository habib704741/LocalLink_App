// ignore_for_file: avoid_print

import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mobile_app/core/utils/network_utils.dart';
import 'package:mobile_app/features/device/domain/models/device_info.dart';
import 'package:path_provider/path_provider.dart';

class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static final Battery _battery = Battery();

  /// Get complete device information
  static Future<DeviceInfo> getDeviceInfo() async {
    final androidInfo = await _deviceInfoPlugin.androidInfo;
    final batteryInfo = await _getBatteryInfo();
    final storageInfo = await _getStorageInfo();
    final networkInfo = await _getNetworkInfo();
    final memoryInfo = await _getMemoryInfo();

    return DeviceInfo(
      deviceName: androidInfo.model,
      model: androidInfo.model,
      manufacturer: androidInfo.manufacturer,
      androidVersion: androidInfo.version.release,
      sdkVersion: androidInfo.version.sdkInt,
      battery: batteryInfo,
      storage: storageInfo,
      network: networkInfo,
      memory: memoryInfo,
    );
  }

  /// Get battery information
  static Future<BatteryInfo> _getBatteryInfo() async {
    try {
      final level = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      final isCharging =
          batteryState == BatteryState.charging ||
          batteryState == BatteryState.full;

      String status;
      switch (batteryState) {
        case BatteryState.full:
          status = 'Full';
          break;
        case BatteryState.charging:
          status = 'Charging';
          break;
        case BatteryState.discharging:
          status = 'Discharging';
          break;
        default:
          status = 'Unknown';
      }

      return BatteryInfo(level: level, isCharging: isCharging, status: status);
    } catch (e) {
      return BatteryInfo(level: 0, isCharging: false, status: 'Unknown');
    }
  }

  /// Get storage information
  static Future<StorageInfo> _getStorageInfo() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        return StorageInfo(
          totalSpace: 0,
          freeSpace: 0,
          usedSpace: 0,
          usedPercentage: 0,
        );
      }

      // ignore: unused_local_variable
      final stat = directory.statSync();
      final path = directory.path;

      // Get filesystem stats
      final totalSpace = await _getTotalSpace(path);
      final freeSpace = await _getFreeSpace(path);
      final usedSpace = totalSpace - freeSpace;
      final usedPercentage = totalSpace > 0
          ? (usedSpace / totalSpace) * 100
          : 0.0;

      return StorageInfo(
        totalSpace: totalSpace,
        freeSpace: freeSpace,
        usedSpace: usedSpace,
        usedPercentage: usedPercentage,
      );
    } catch (e) {
      print('Error getting storage info: $e');
      return StorageInfo(
        totalSpace: 0,
        freeSpace: 0,
        usedSpace: 0,
        usedPercentage: 0,
      );
    }
  }

  /// Get total storage space
  static Future<int> _getTotalSpace(String path) async {
    try {
      final result = await Process.run('df', [path]);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length > 1) {
          return int.tryParse(parts[1]) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get free storage space
  static Future<int> _getFreeSpace(String path) async {
    try {
      final result = await Process.run('df', [path]);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length > 3) {
          return int.tryParse(parts[3]) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get network information
  static Future<NetworkInfo> _getNetworkInfo() async {
    try {
      final isConnected = await NetworkUtils.isConnectedToWiFi();
      final ipAddress = await NetworkUtils.getLocalIpAddress();
      final wifiName = await NetworkUtils.getWiFiName();

      return NetworkInfo(
        wifiName: wifiName,
        ipAddress: ipAddress,
        isConnected: isConnected,
        connectionType: isConnected ? 'wifi' : 'none',
      );
    } catch (e) {
      return NetworkInfo(isConnected: false, connectionType: 'none');
    }
  }

  /// Get memory information
  static Future<MemoryInfo> _getMemoryInfo() async {
    try {
      // Get memory info from /proc/meminfo
      final memInfo = File('/proc/meminfo');
      final contents = await memInfo.readAsString();

      int totalRam = 0;
      int freeRam = 0;

      for (final line in contents.split('\n')) {
        if (line.startsWith('MemTotal:')) {
          final match = RegExp(r'\d+').firstMatch(line);
          if (match != null) {
            totalRam = int.parse(match.group(0)!) * 1024; // Convert KB to bytes
          }
        } else if (line.startsWith('MemAvailable:')) {
          final match = RegExp(r'\d+').firstMatch(line);
          if (match != null) {
            freeRam = int.parse(match.group(0)!) * 1024; // Convert KB to bytes
          }
        }
      }

      final usedRam = totalRam - freeRam;
      final usedPercentage = totalRam > 0 ? (usedRam / totalRam) * 100 : 0.0;

      return MemoryInfo(
        totalRam: totalRam,
        freeRam: freeRam,
        usedRam: usedRam,
        usedPercentage: usedPercentage,
      );
    } catch (e) {
      print('Error getting memory info: $e');
      return MemoryInfo(totalRam: 0, freeRam: 0, usedRam: 0, usedPercentage: 0);
    }
  }
}
