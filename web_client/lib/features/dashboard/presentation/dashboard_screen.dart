import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_client/core/constants/app_constants.dart';
import 'package:web_client/core/theme/app_theme.dart';
import 'package:web_client/features/connection/presentation/connection_screen.dart';
import 'package:web_client/features/connection/providers/connection_provider.dart';
import 'package:web_client/features/connection/providers/connection_provider.dart'
    as connection_provider;
import 'package:web_client/features/contacts/presentation/contacts_screen.dart';
import 'package:web_client/features/dashboard/presentation/widgets/device_info_widget.dart';
import 'package:web_client/features/files/presentation/file_browser_screen.dart';
import 'package:web_client/features/media/presentation/audio_gallery_screen.dart';
import 'package:web_client/features/media/presentation/image_gallery_screen.dart';
import 'package:web_client/features/media/presentation/video_gallery_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.home, label: 'Home', route: 'home'),
    NavigationItem(
      icon: Icons.phone_android,
      label: 'Device Info',
      route: 'device',
    ),
    NavigationItem(icon: Icons.folder, label: 'Files', route: 'files'),
    NavigationItem(icon: Icons.image, label: 'Images', route: 'images'),
    NavigationItem(icon: Icons.videocam, label: 'Videos', route: 'videos'),
    NavigationItem(icon: Icons.audiotrack, label: 'Audio', route: 'audio'),
    NavigationItem(icon: Icons.contacts, label: 'Contacts', route: 'contacts'),
  ];

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(
      connection_provider.connectionStateProvider,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= AppConstants.desktopBreakpoint;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          if (isDesktop)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(connectionState),
                  Expanded(child: _buildNavigationList()),
                  _buildFooter(),
                ],
              ),
            ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(connectionState),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),

      // Mobile Bottom Navigation
      bottomNavigationBar: !isDesktop
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              backgroundColor: AppTheme.surfaceDark,
              destinations: _navigationItems.take(4).map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                );
              }).toList(),
            )
          : null,
    );
  }

  Widget _buildHeader(connection_provider.ConnectionState connectionState) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phonelink, color: AppTheme.primaryGreen, size: 32),
              const SizedBox(width: 12),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusSmall,
              ),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Connected',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _navigationItems.length,
      itemBuilder: (context, index) {
        final item = _navigationItems[index];
        final isSelected = _selectedIndex == index;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: isSelected ? AppTheme.primaryGreen : Colors.white70,
            ),
            title: Text(
              item.label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSelected ? AppTheme.primaryGreen : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            onTap: () {
              setState(() => _selectedIndex = index);
            },
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorRed),
            title: Text(
              'Disconnect',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.errorRed),
            ),
            onTap: () => _handleDisconnect(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(connection_provider.ConnectionState connectionState) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _navigationItems[_selectedIndex].label,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusSmall,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.router,
                  color: AppTheme.primaryGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  connectionState.ipAddress ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            connectionState.fullAddress,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final route = _navigationItems[_selectedIndex].route;
    switch (route) {
      case 'home':
        return _buildHomeContent();
      case 'device':
        return const DeviceInfoWidget();
      case 'files':
        return const FileBrowserScreen();
      case 'images':
        return const ImageGalleryScreen();
      case 'videos':
        return const VideoGalleryScreen();
      case 'audio':
        return const AudioGalleryScreen();
      case 'contacts':
        return const ContactsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to LocalLink',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your Android device from your browser',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 40),

          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text("Failed to load stats"),
            data: (stats) => LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 2;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      icon: Icons.contacts,
                      title: 'Contacts',
                      value: stats['contacts'] ?? '0',
                      color: Colors.teal,
                    ),
                    _buildStatCard(
                      icon: Icons.image,
                      title: 'Images',
                      value: stats['images'] ?? '0',
                      color: Colors.purple,
                    ),
                    _buildStatCard(
                      icon: Icons.videocam,
                      title: 'Videos',
                      value: stats['videos'] ?? '0',
                      color: Colors.red,
                    ),
                    _buildStatCard(
                      icon: Icons.audiotrack,
                      title: 'Audio',
                      value: stats['audio'] ?? '0',
                      color: Colors.orange,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(color: color),
              ),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleDisconnect() {
    ref.read(connectionStateProvider.notifier).disconnect();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ConnectionScreen()),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  final connectionState = ref.watch(connectionStateProvider);
  if (!connectionState.isConnected || connectionState.fullAddress.isEmpty) {
    return {};
  }

  final baseUrl = connectionState.fullAddress;

  Future<String> getCount(String endpoint, String jsonKey) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey(jsonKey)) {
          final list = data[jsonKey] as List;
          return list.length.toString();
        }
      }
    } catch (e) {
      // Silent error
    }
    return '0';
  }

  final results = await Future.wait([
    getCount('/api/media/images', 'images'),
    getCount('/api/media/videos', 'videos'),
    getCount('/api/media/audio', 'audio'),
    getCount('/api/contacts', 'contacts'),
  ]);

  return {
    'images': results[0],
    'videos': results[1],
    'audio': results[2],
    'contacts': results[3],
  };
});
