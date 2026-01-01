enum ServerState { stopped, starting, running, stopping, error }

class ServerStatus {
  final ServerState state;
  final String? ipAddress;
  final int? port;
  final String? errorMessage;
  final DateTime? startTime;

  const ServerStatus({
    required this.state,
    this.ipAddress,
    this.port,
    this.errorMessage,
    this.startTime,
  });

  factory ServerStatus.stopped() {
    return const ServerStatus(state: ServerState.stopped);
  }

  factory ServerStatus.starting() {
    return const ServerStatus(state: ServerState.starting);
  }

  factory ServerStatus.running({required String ipAddress, required int port}) {
    return ServerStatus(
      state: ServerState.running,
      ipAddress: ipAddress,
      port: port,
      startTime: DateTime.now(),
    );
  }

  factory ServerStatus.stopping() {
    return const ServerStatus(state: ServerState.stopping);
  }

  factory ServerStatus.error(String message) {
    return ServerStatus(state: ServerState.error, errorMessage: message);
  }

  bool get isRunning => state == ServerState.running;
  bool get isStopped => state == ServerState.stopped;
  bool get isTransitioning =>
      state == ServerState.starting || state == ServerState.stopping;

  String get fullAddress => isRunning && ipAddress != null && port != null
      ? 'http://$ipAddress:$port'
      : '';

  ServerStatus copyWith({
    ServerState? state,
    String? ipAddress,
    int? port,
    String? errorMessage,
    DateTime? startTime,
  }) {
    return ServerStatus(
      state: state ?? this.state,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      errorMessage: errorMessage ?? this.errorMessage,
      startTime: startTime ?? this.startTime,
    );
  }
}
