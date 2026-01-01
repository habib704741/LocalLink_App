import 'package:flutter/material.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/services/permission_service.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/home/presentation/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isRequesting = false;
  bool _showError = false;
  String _errorMessage = '';

  final List<PermissionInfo> _permissions = [
    PermissionInfo(
      icon: Icons.folder,
      title: 'Storage Access',
      description: 'Access files, photos, videos, and audio on your device',
    ),
    PermissionInfo(
      icon: Icons.camera_alt,
      title: 'Camera',
      description: 'Take photos and videos',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon
              Icon(Icons.security, size: 80, color: AppTheme.primaryGreen),

              const SizedBox(height: 24),

              // Title
              Text(
                'Permissions Required',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'LocalLink needs these permissions to manage your phone',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Permission List
              ..._permissions.map((perm) => _buildPermissionCard(perm)),

              const SizedBox(height: 32),

              // Error Message
              if (_showError)
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  margin: const EdgeInsets.only(bottom: 16),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),

              // Grant Permission Button
              ElevatedButton(
                onPressed: _isRequesting ? null : _handleGrantPermissions,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _isRequesting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Text('Grant Permissions'),
                ),
              ),

              const SizedBox(height: 12),

              // Skip Button
              TextButton(
                onPressed: _isRequesting ? null : _handleSkip,
                child: const Text('Skip for now'),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your data never leaves your device. All operations are local.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(PermissionInfo permission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusSmall,
              ),
            ),
            child: Icon(
              permission.icon,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  permission.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Future<void> _requestPermission() async {
  //   var status = await Permission.manageExternalStorage.status;
  //   if (!status.isGranted) {
  //     await Permission.manageExternalStorage.request();
  //   } else {
  //     // Navigate to home
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(builder: (context) => const HomeScreen()),
  //     );
  //   }
  // }

  Future<void> _handleGrantPermissions() async {
    setState(() {
      _isRequesting = true;
      _showError = false;
    });

    try {
      final results = await PermissionService.requestAllPermissions();

      // Check if all permissions are granted
      final allGranted = results.values.every((status) => status.isGranted);

      if (allGranted) {
        _navigateToHome();
      } else {
        // Check for permanently denied permissions
        final permanentlyDenied = results.entries
            .where((entry) => entry.value.isPermanentlyDenied)
            .toList();

        if (permanentlyDenied.isNotEmpty) {
          setState(() {
            _showError = true;
            _errorMessage =
                'Some permissions are permanently denied. Please enable them in settings.';
          });

          // Show dialog to open settings
          _showSettingsDialog();
        } else {
          setState(() {
            _showError = true;
            _errorMessage =
                'Some permissions were denied. LocalLink may not work properly.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _showError = true;
        _errorMessage = 'Error requesting permissions: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  void _handleSkip() {
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Open Settings?'),
        content: const Text(
          'Some permissions are permanently denied. Would you like to open app settings to enable them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await PermissionService.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

class PermissionInfo {
  final IconData icon;
  final String title;
  final String description;

  PermissionInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}
