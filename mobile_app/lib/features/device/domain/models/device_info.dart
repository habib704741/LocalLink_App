class DeviceInfo {
  final String deviceName;
  final String model;
  final String manufacturer;
  final String androidVersion;
  final int sdkVersion;
  final BatteryInfo battery;
  final StorageInfo storage;
  final NetworkInfo network;
  final MemoryInfo memory;

  DeviceInfo({
    required this.deviceName,
    required this.model,
    required this.manufacturer,
    required this.androidVersion,
    required this.sdkVersion,
    required this.battery,
    required this.storage,
    required this.network,
    required this.memory,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'model': model,
      'manufacturer': manufacturer,
      'androidVersion': androidVersion,
      'sdkVersion': sdkVersion,
      'battery': battery.toJson(),
      'storage': storage.toJson(),
      'network': network.toJson(),
      'memory': memory.toJson(),
    };
  }
}

class BatteryInfo {
  final int level; // 0-100
  final bool isCharging;
  final String status;

  BatteryInfo({
    required this.level,
    required this.isCharging,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {'level': level, 'isCharging': isCharging, 'status': status};
  }
}

class StorageInfo {
  final int totalSpace; // in bytes
  final int freeSpace; // in bytes
  final int usedSpace; // in bytes
  final double usedPercentage; // 0-100

  StorageInfo({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
    required this.usedPercentage,
  });

  String get totalSpaceFormatted => _formatBytes(totalSpace);
  String get freeSpaceFormatted => _formatBytes(freeSpace);
  String get usedSpaceFormatted => _formatBytes(usedSpace);

  Map<String, dynamic> toJson() {
    return {
      'totalSpace': totalSpace,
      'freeSpace': freeSpace,
      'usedSpace': usedSpace,
      'usedPercentage': usedPercentage,
      'totalSpaceFormatted': totalSpaceFormatted,
      'freeSpaceFormatted': freeSpaceFormatted,
      'usedSpaceFormatted': usedSpaceFormatted,
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class NetworkInfo {
  final String? wifiName;
  final String? ipAddress;
  final bool isConnected;
  final String connectionType;

  NetworkInfo({
    this.wifiName,
    this.ipAddress,
    required this.isConnected,
    required this.connectionType,
  });

  Map<String, dynamic> toJson() {
    return {
      'wifiName': wifiName,
      'ipAddress': ipAddress,
      'isConnected': isConnected,
      'connectionType': connectionType,
    };
  }
}

class MemoryInfo {
  final int totalRam; // in bytes
  final int freeRam; // in bytes
  final int usedRam; // in bytes
  final double usedPercentage; // 0-100

  MemoryInfo({
    required this.totalRam,
    required this.freeRam,
    required this.usedRam,
    required this.usedPercentage,
  });

  String get totalRamFormatted => _formatBytes(totalRam);
  String get freeRamFormatted => _formatBytes(freeRam);
  String get usedRamFormatted => _formatBytes(usedRam);

  Map<String, dynamic> toJson() {
    return {
      'totalRam': totalRam,
      'freeRam': freeRam,
      'usedRam': usedRam,
      'usedPercentage': usedPercentage,
      'totalRamFormatted': totalRamFormatted,
      'freeRamFormatted': freeRamFormatted,
      'usedRamFormatted': usedRamFormatted,
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
