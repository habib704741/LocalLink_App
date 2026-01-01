import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/contacts/presentation/contacts_screen.dart';
import 'package:mobile_app/features/device/presentation/device_info_screen.dart';
import 'package:mobile_app/features/files/presentation/file_browser_screen.dart';
import 'package:mobile_app/features/media/presentation/audio_gallery_screen.dart';
import 'package:mobile_app/features/media/presentation/image_gallery_screen.dart';
import 'package:mobile_app/features/media/presentation/video_gallery_screen.dart';
import 'package:mobile_app/features/server/domain/models/server_status.dart';
import 'package:mobile_app/features/server/presentation/providers/server_provider.dart';
import 'package:mobile_app/features/media/data/services/media_service.dart';
import 'package:mobile_app/features/contacts/data/services/contacts_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverStatus = ref.watch(serverStatusProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Privacy-focused phone control',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              _ServerStatusCard(serverStatus: serverStatus),
              const SizedBox(height: 24),
              const Expanded(child: _FeaturesGrid()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerStatusCard extends ConsumerWidget {
  final ServerStatus serverStatus;
  const _ServerStatusCard({required this.serverStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRunning = serverStatus.isRunning;
    final isTransitioning = serverStatus.isTransitioning;
    final hasError = serverStatus.state == ServerState.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(
          color: hasError
              ? AppTheme.errorRed.withValues(alpha: 0.3)
              : isRunning
              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
              : Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor,
                color: hasError
                    ? AppTheme.errorRed
                    : isRunning
                    ? AppTheme.primaryGreen
                    : Colors.white54,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Web on PC',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusDescription(serverStatus),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasError ? AppTheme.errorRed : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStatusLabel(serverStatus),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (isTransitioning)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGreen,
                    ),
                  ),
                )
              else
                Switch(
                  value: isRunning,
                  onChanged: hasError
                      ? null
                      : (value) {
                          ref
                              .read(serverStatusProvider.notifier)
                              .toggleServer();
                        },
                ),
            ],
          ),
          if (isRunning && serverStatus.fullAddress.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.link,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serverStatus.fullAddress,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    color: AppTheme.primaryGreen,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: serverStatus.fullAddress),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Address copied to clipboard'),
                          backgroundColor: AppTheme.primaryGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          if (hasError && serverStatus.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusMedium,
                ),
                border: Border.all(
                  color: AppTheme.errorRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serverStatus.errorMessage!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusDescription(ServerStatus status) {
    switch (status.state) {
      case ServerState.stopped:
        return 'Access your phone from a computer browser';
      case ServerState.starting:
        return 'Starting server...';
      case ServerState.running:
        return 'Server is running - Open the URL below in your browser';
      case ServerState.stopping:
        return 'Stopping server...';
      case ServerState.error:
        return 'Error occurred';
    }
  }

  String _getStatusLabel(ServerStatus status) {
    switch (status.state) {
      case ServerState.stopped:
        return 'Start Service';
      case ServerState.starting:
        return 'Starting...';
      case ServerState.running:
        return 'Server Running';
      case ServerState.stopping:
        return 'Stopping...';
      case ServerState.error:
        return 'Error';
    }
  }
}

class _FeaturesGrid extends ConsumerWidget {
  const _FeaturesGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stats provider
    final statsAsync = ref.watch(homeStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading stats: $err')),
      data: (stats) {
        final features = [
          {
            'icon': Icons.phone_android,
            'label': 'Device Info',
            'count': '',
            'route': 'device_info',
          },
          {
            'icon': Icons.folder,
            'label': 'Files',
            'count': '',
            'route': 'files',
          },
          {
            'icon': Icons.contacts,
            'label': 'Contacts',
            'count': stats['contacts'] ?? '0',
            'route': 'contacts',
          },
          {
            'icon': Icons.image,
            'label': 'Images',
            'count': stats['images'] ?? '0',
            'route': 'images',
          },
          {
            'icon': Icons.videocam,
            'label': 'Videos',
            'count': stats['videos'] ?? '0',
            'route': 'videos',
          },
          {
            'icon': Icons.audiotrack,
            'label': 'Audio',
            'count': stats['audio'] ?? '0',
            'route': 'audio',
          },
        ];

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return _FeatureCard(
              icon: feature['icon'] as IconData,
              label: feature['label'] as String,
              count: feature['count'] as String,
              route: feature['route'] as String?,
            );
          },
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final String? route;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.count,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          onTap: () => _handleTap(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.primaryGreen, size: 32),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                if (count.isNotEmpty && count != '0') ...[
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (route == 'device_info') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DeviceInfoScreen()),
      );
    } else if (route == 'files') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FileBrowserScreen()),
      );
    } else if (route == 'images') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ImageGalleryScreen()),
      );
    } else if (route == 'videos') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VideoGalleryScreen()),
      );
    } else if (route == 'audio') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AudioGalleryScreen()),
      );
    } else if (route == 'contacts') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ContactsScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label feature coming soon'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}

final homeStatsProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final contacts = await ContactsService.getAllContacts();
  final images = await MediaService.getAllImages();
  final videos = await MediaService.getAllVideos();
  final audio = await MediaService.getAllAudio();

  return {
    'contacts': contacts.length.toString(),
    'images': images.length.toString(),
    'videos': videos.length.toString(),
    'audio': audio.length.toString(),
  };
});
