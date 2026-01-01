// ignore_for_file: avoid_print

import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkUtils {
  static final NetworkInfo _networkInfo = NetworkInfo();

  /// Get the device's local IP address on WiFi
  static Future<String?> getLocalIpAddress() async {
    try {
      // Try to get WiFi IP first
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty) {
        return wifiIP;
      }

      // Fallback: Get IP from network interfaces
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Skip loopback addresses
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }

      return null;
    } catch (e) {
      print('Error getting IP address: $e');
      return null;
    }
  }

  /// Check if device is connected to WiFi
  static Future<bool> isConnectedToWiFi() async {
    try {
      final wifiIP = await _networkInfo.getWifiIP();
      return wifiIP != null && wifiIP.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get WiFi name (SSID)
  static Future<String?> getWiFiName() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      return null;
    }
  }

  /// Check if port is available
  static Future<bool> isPortAvailable(int port) async {
    try {
      final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      await server.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
