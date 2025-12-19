class SystemInfo {
  final String deviceName;
  final int batteryLevel;
  final bool isCharging;
  final String storageLabel;
  final double storagePercent;

  SystemInfo({
    required this.deviceName,
    required this.batteryLevel,
    required this.isCharging,
    required this.storageLabel,
    required this.storagePercent,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    return SystemInfo(
      deviceName: json['deviceName'] ?? 'Unknown',
      batteryLevel: json['batteryLevel'] ?? 0,
      isCharging: json['isCharging'] ?? false,
      storageLabel: json['storageLabel'] ?? 'Unknown Storage',
      storagePercent: (json['storagePercent'] ?? 0.0).toDouble(),
    );
  }
}
