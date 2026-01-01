import 'package:flutter_riverpod/legacy.dart';
import 'package:mobile_app/core/constants/app_constants.dart';
import 'package:mobile_app/core/utils/network_utils.dart';
import 'package:mobile_app/features/server/data/services/http_server_service.dart';
import 'package:mobile_app/features/server/domain/models/server_status.dart';

// Server status provider
final serverStatusProvider =
    StateNotifierProvider<ServerNotifier, ServerStatus>((ref) {
      return ServerNotifier();
    });

class ServerNotifier extends StateNotifier<ServerStatus> {
  ServerNotifier() : super(ServerStatus.stopped());

  final _serverService = HttpServerService();

  /// Start the server
  Future<void> startServer() async {
    if (state.isTransitioning || state.isRunning) {
      return;
    }

    state = ServerStatus.starting();

    try {
      // Check WiFi connection
      final isWiFiConnected = await NetworkUtils.isConnectedToWiFi();
      if (!isWiFiConnected) {
        state = ServerStatus.error('Not connected to WiFi');
        return;
      }

      // Get IP address
      final ipAddress = await NetworkUtils.getLocalIpAddress();
      if (ipAddress == null) {
        state = ServerStatus.error('Could not get IP address');
        return;
      }

      // Check if port is available
      const port = AppConstants.defaultPort;
      final isPortAvailable = await NetworkUtils.isPortAvailable(port);
      if (!isPortAvailable) {
        state = ServerStatus.error('Port $port is already in use');
        return;
      }

      // Start server
      await _serverService.start(ipAddress: ipAddress, port: port);

      state = ServerStatus.running(ipAddress: ipAddress, port: port);
    } catch (e) {
      state = ServerStatus.error('Failed to start server: $e');
    }
  }

  /// Stop the server
  Future<void> stopServer() async {
    if (state.isStopped || state.isTransitioning) {
      return;
    }

    state = ServerStatus.stopping();

    try {
      await _serverService.stop();
      state = ServerStatus.stopped();
    } catch (e) {
      state = ServerStatus.error('Failed to stop server: $e');
    }
  }

  /// Toggle server state
  Future<void> toggleServer() async {
    if (state.isRunning) {
      await stopServer();
    } else {
      await startServer();
    }
  }
}
