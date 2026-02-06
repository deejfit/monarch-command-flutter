/// Machine model representing a Monarch Core machine.
/// Matches API: machineId, status, currentJobId (nullable), lastSeen, clients (supported app clients).
class Machine {
  const Machine({
    this.machineId,
    this.status,
    this.currentJobId,
    this.lastSeen,
    this.clients = const [],
  });

  final String? machineId;
  final String? status;
  final String? currentJobId;
  /// Unix timestamp in milliseconds. API returns a number, not a string.
  final int? lastSeen;
  /// Supported application client ids (e.g. cursor, codex). From API; empty if not provided.
  final List<String> clients;

  /// Stable id for selection/comparison.
  String get id => machineId ?? '';

  factory Machine.fromJson(Map<String, dynamic> json) {
    final lastSeenRaw = json['lastSeen'];
    int? lastSeen;
    if (lastSeenRaw != null) {
      lastSeen = lastSeenRaw is int
          ? lastSeenRaw
          : (lastSeenRaw is num ? lastSeenRaw.toInt() : null);
    }
    final clientsRaw = json['clients'];
    List<String> clients = const [];
    if (clientsRaw is List<dynamic>) {
      clients = clientsRaw
          .map((e) => (e?.toString().trim() ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return Machine(
      machineId: json['machineId'] as String? ?? json['id'] as String?,
      status: json['status'] as String?,
      currentJobId: json['currentJobId'] as String?,
      lastSeen: lastSeen,
      clients: clients,
    );
  }
}
