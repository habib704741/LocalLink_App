import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_client/core/constants/app_constants.dart';
import 'package:web_client/core/theme/app_theme.dart';
import 'package:web_client/features/connection/providers/connection_provider.dart';
import 'package:web_client/features/connection/providers/connection_provider.dart'
    as connection_provider;
import 'package:web_client/features/dashboard/presentation/dashboard_screen.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _ipController = TextEditingController(text: '192.168.1.');
  final _portController = TextEditingController(text: '8080');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionStateProvider);

    ref.listen<connection_provider.ConnectionState>(
      connection_provider.connectionStateProvider,
      (previous, next) {
        if (next.isConnected && previous?.isConnected != true) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      },
    );

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(AppConstants.paddingXLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Icon(Icons.phonelink, size: 80, color: AppTheme.primaryGreen),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Connect to your Android device',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Connection Card
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusLarge,
                      ),
                      border: connectionState.hasError
                          ? Border.all(
                              color: AppTheme.errorRed.withValues(alpha: 0.5),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Device Connection',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),

                        const SizedBox(height: 24),

                        // IP Address Input
                        TextFormField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'IP Address',
                            hintText: 'e.g., 192.168.1.100',
                            prefixIcon: Icon(Icons.router),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter IP address';
                            }
                            // Basic IP validation
                            final parts = value.split('.');
                            if (parts.length != 4) {
                              return 'Invalid IP address format';
                            }
                            return null;
                          },
                          enabled: !connectionState.isConnecting,
                        ),

                        const SizedBox(height: 16),

                        // Port Input
                        TextFormField(
                          controller: _portController,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            hintText: '8080',
                            prefixIcon: Icon(Icons.settings_ethernet),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter port';
                            }
                            final port = int.tryParse(value);
                            if (port == null || port < 1 || port > 65535) {
                              return 'Port must be between 1 and 65535';
                            }
                            return null;
                          },
                          enabled: !connectionState.isConnecting,
                        ),

                        // Error Message
                        if (connectionState.hasError) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusSmall,
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
                                    connectionState.errorMessage ??
                                        'Connection failed',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.errorRed),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Connect Button
                        ElevatedButton(
                          onPressed: connectionState.isConnecting
                              ? null
                              : _handleConnect,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: connectionState.isConnecting
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
                                : const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium,
                      ),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Make sure both devices are on the same Wi-Fi network and the LocalLink app is running on your phone.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleConnect() {
    if (_formKey.currentState?.validate() ?? false) {
      final ipAddress = _ipController.text.trim();
      final port = int.parse(_portController.text.trim());

      ref.read(connectionStateProvider.notifier).connect(ipAddress, port);
    }
  }
}
