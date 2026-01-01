import 'package:flutter/material.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/device/data/services/device_info_service.dart';
import 'package:mobile_app/features/device/domain/models/device_info.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  DeviceInfo? _deviceInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() => _isLoading = true);

    try {
      final info = await DeviceInfoService.getDeviceInfo();
      if (mounted) {
        setState(() {
          _deviceInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeviceInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            )
          : _deviceInfo == null
          ? const Center(child: Text('Failed to load device info'))
          : RefreshIndicator(
              onRefresh: _loadDeviceInfo,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                children: [
                  _buildSection(
                    title: 'Device',
                    icon: Icons.phone_android,
                    items: [
                      _InfoItem('Name', _deviceInfo!.deviceName),
                      _InfoItem('Model', _deviceInfo!.model),
                      _InfoItem('Manufacturer', _deviceInfo!.manufacturer),
                      _InfoItem('Android', _deviceInfo!.androidVersion),
                      _InfoItem('SDK', _deviceInfo!.sdkVersion.toString()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildBatterySection(),
                  const SizedBox(height: 20),
                  _buildStorageSection(),
                  const SizedBox(height: 20),
                  _buildMemorySection(),
                  const SizedBox(height: 20),
                  _buildNetworkSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_InfoItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _buildInfoRow(item.label, item.value)),
        ],
      ),
    );
  }

  Widget _buildBatterySection() {
    final battery = _deviceInfo!.battery;
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                battery.isCharging
                    ? Icons.battery_charging_full
                    : Icons.battery_std,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('Battery', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar('Level', battery.level / 100, '${battery.level}%'),
          const SizedBox(height: 8),
          _buildInfoRow('Status', battery.status),
        ],
      ),
    );
  }

  Widget _buildStorageSection() {
    final storage = _deviceInfo!.storage;
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Text('Storage', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            'Used',
            storage.usedPercentage / 100,
            '${storage.usedPercentage.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Total', storage.totalSpaceFormatted),
          _buildInfoRow('Used', storage.usedSpaceFormatted),
          _buildInfoRow('Free', storage.freeSpaceFormatted),
        ],
      ),
    );
  }

  Widget _buildMemorySection() {
    final memory = _deviceInfo!.memory;
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Text('Memory', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            'Used',
            memory.usedPercentage / 100,
            '${memory.usedPercentage.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Total', memory.totalRamFormatted),
          _buildInfoRow('Used', memory.usedRamFormatted),
          _buildInfoRow('Free', memory.freeRamFormatted),
        ],
      ),
    );
  }

  Widget _buildNetworkSection() {
    final network = _deviceInfo!.network;
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Text('Network', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Type', network.connectionType.toUpperCase()),
          if (network.wifiName != null)
            _buildInfoRow('WiFi', network.wifiName!),
          if (network.ipAddress != null)
            _buildInfoRow('IP Address', network.ipAddress!),
          _buildInfoRow('Connected', network.isConnected ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double progress, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.primaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.surfaceDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryGreen,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}
