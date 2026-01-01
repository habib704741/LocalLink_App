import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_client/core/constants/app_constants.dart';
import 'package:web_client/core/theme/app_theme.dart';
import 'package:web_client/features/connection/providers/connection_provider.dart';

// Device info provider
final deviceInfoProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  return await apiClient.getDeviceInfo();
});

class DeviceInfoWidget extends ConsumerWidget {
  const DeviceInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceInfoAsync = ref.watch(deviceInfoProvider);

    return deviceInfoAsync.when(
      data: (deviceInfo) {
        if (deviceInfo == null) {
          return const Center(child: Text('Failed to load device information'));
        }
        return _buildDeviceInfo(context, deviceInfo);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error loading device info',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(deviceInfoProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo(BuildContext context, Map<String, dynamic> info) {
    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1000;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.phone_android,
                      color: AppTheme.primaryGreen,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info['deviceName'] ?? 'Unknown Device',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Text(
                          '${info['manufacturer']} ${info['model']}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Info Grid
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildDeviceSection(context, info),
                            const SizedBox(height: 16),
                            _buildBatterySection(context, info['battery']),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildStorageSection(context, info['storage']),
                            const SizedBox(height: 16),
                            _buildMemorySection(context, info['memory']),
                            const SizedBox(height: 16),
                            _buildNetworkSection(context, info['network']),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildDeviceSection(context, info),
                      const SizedBox(height: 16),
                      _buildBatterySection(context, info['battery']),
                      const SizedBox(height: 16),
                      _buildStorageSection(context, info['storage']),
                      const SizedBox(height: 16),
                      _buildMemorySection(context, info['memory']),
                      const SizedBox(height: 16),
                      _buildNetworkSection(context, info['network']),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeviceSection(BuildContext context, Map<String, dynamic> info) {
    return _buildSection(
      context: context,
      title: 'Device Information',
      icon: Icons.info_outline,
      children: [
        _buildInfoRow(context, 'Model', info['model'] ?? 'Unknown'),
        _buildInfoRow(
          context,
          'Manufacturer',
          info['manufacturer'] ?? 'Unknown',
        ),
        _buildInfoRow(context, 'Android', info['androidVersion'] ?? 'Unknown'),
        _buildInfoRow(
          context,
          'SDK',
          info['sdkVersion']?.toString() ?? 'Unknown',
        ),
      ],
    );
  }

  Widget _buildBatterySection(
    BuildContext context,
    Map<String, dynamic>? battery,
  ) {
    if (battery == null) return const SizedBox.shrink();

    final level = battery['level'] ?? 0;
    final isCharging = battery['isCharging'] ?? false;
    final status = battery['status'] ?? 'Unknown';

    return _buildSection(
      context: context,
      title: 'Battery',
      icon: isCharging ? Icons.battery_charging_full : Icons.battery_std,
      children: [
        _buildProgressBar(context, 'Level', level / 100, '$level%'),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'Status', status),
      ],
    );
  }

  Widget _buildStorageSection(
    BuildContext context,
    Map<String, dynamic>? storage,
  ) {
    if (storage == null) return const SizedBox.shrink();

    final usedPercentage = storage['usedPercentage'] ?? 0.0;
    final totalFormatted = storage['totalSpaceFormatted'] ?? '0 GB';
    final usedFormatted = storage['usedSpaceFormatted'] ?? '0 GB';
    final freeFormatted = storage['freeSpaceFormatted'] ?? '0 GB';

    return _buildSection(
      context: context,
      title: 'Storage',
      icon: Icons.storage,
      children: [
        _buildProgressBar(
          context,
          'Used',
          usedPercentage / 100,
          '${usedPercentage.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'Total', totalFormatted),
        _buildInfoRow(context, 'Used', usedFormatted),
        _buildInfoRow(context, 'Free', freeFormatted),
      ],
    );
  }

  Widget _buildMemorySection(
    BuildContext context,
    Map<String, dynamic>? memory,
  ) {
    if (memory == null) return const SizedBox.shrink();

    final usedPercentage = memory['usedPercentage'] ?? 0.0;
    final totalFormatted = memory['totalRamFormatted'] ?? '0 GB';
    final usedFormatted = memory['usedRamFormatted'] ?? '0 GB';
    final freeFormatted = memory['freeRamFormatted'] ?? '0 GB';

    return _buildSection(
      context: context,
      title: 'Memory',
      icon: Icons.memory,
      children: [
        _buildProgressBar(
          context,
          'Used',
          usedPercentage / 100,
          '${usedPercentage.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'Total', totalFormatted),
        _buildInfoRow(context, 'Used', usedFormatted),
        _buildInfoRow(context, 'Free', freeFormatted),
      ],
    );
  }

  Widget _buildNetworkSection(
    BuildContext context,
    Map<String, dynamic>? network,
  ) {
    if (network == null) return const SizedBox.shrink();

    final connectionType = network['connectionType'] ?? 'none';
    final wifiName = network['wifiName'];
    final ipAddress = network['ipAddress'];
    final isConnected = network['isConnected'] ?? false;

    return _buildSection(
      context: context,
      title: 'Network',
      icon: Icons.wifi,
      children: [
        _buildInfoRow(context, 'Type', connectionType.toUpperCase()),
        if (wifiName != null) _buildInfoRow(context, 'WiFi', wifiName),
        if (ipAddress != null) _buildInfoRow(context, 'IP Address', ipAddress),
        _buildInfoRow(context, 'Connected', isConnected ? 'Yes' : 'No'),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
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

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    double progress,
    String text,
  ) {
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
