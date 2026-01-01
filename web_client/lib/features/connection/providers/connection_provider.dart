import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:web_client/core/api/api_client.dart';

// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Connection state provider
final connectionStateProvider =
    StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return ConnectionNotifier(apiClient);
    });

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final ApiClient _apiClient;

  ConnectionNotifier(this._apiClient) : super(ConnectionState.disconnected());

  /// Connect to server
  Future<void> connect(String ipAddress, int port) async {
    state = ConnectionState.connecting(ipAddress: ipAddress, port: port);

    try {
      final success = await _apiClient.connect(ipAddress, port);

      if (success) {
        // Get server status
        final status = await _apiClient.getStatus();
        final version = status?['version'] ?? 'Unknown';

        state = ConnectionState.connected(
          ipAddress: ipAddress,
          port: port,
          serverVersion: version,
        );
      } else {
        state = ConnectionState.error(
          ipAddress: ipAddress,
          port: port,
          message: 'Failed to connect to server',
        );
      }
    } catch (e) {
      state = ConnectionState.error(
        ipAddress: ipAddress,
        port: port,
        message: 'Connection error: $e',
      );
    }
  }

  /// Disconnect from server
  void disconnect() {
    _apiClient.disconnect();
    state = ConnectionState.disconnected();
  }

  /// Retry connection
  Future<void> retry() async {
    if (state.ipAddress != null && state.port != null) {
      await connect(state.ipAddress!, state.port!);
    }
  }
}

// Connection State Model
class ConnectionState {
  final ConnectionStatus status;
  final String? ipAddress;
  final int? port;
  final String? serverVersion;
  final String? errorMessage;

  ConnectionState({
    required this.status,
    this.ipAddress,
    this.port,
    this.serverVersion,
    this.errorMessage,
  });

  factory ConnectionState.disconnected() {
    return ConnectionState(status: ConnectionStatus.disconnected);
  }

  factory ConnectionState.connecting({
    required String ipAddress,
    required int port,
  }) {
    return ConnectionState(
      status: ConnectionStatus.connecting,
      ipAddress: ipAddress,
      port: port,
    );
  }

  factory ConnectionState.connected({
    required String ipAddress,
    required int port,
    required String serverVersion,
  }) {
    return ConnectionState(
      status: ConnectionStatus.connected,
      ipAddress: ipAddress,
      port: port,
      serverVersion: serverVersion,
    );
  }

  factory ConnectionState.error({
    required String ipAddress,
    required int port,
    required String message,
  }) {
    return ConnectionState(
      status: ConnectionStatus.error,
      ipAddress: ipAddress,
      port: port,
      errorMessage: message,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting;
  bool get isDisconnected => status == ConnectionStatus.disconnected;
  bool get hasError => status == ConnectionStatus.error;

  String get fullAddress =>
      ipAddress != null && port != null ? 'http://$ipAddress:$port' : '';
}

enum ConnectionStatus { disconnected, connecting, connected, error }
