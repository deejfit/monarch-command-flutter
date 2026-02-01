/// Machine model representing a Monarch Core machine.
/// Matches API: machineId, status, currentJobId (nullable), lastSeen (numeric timestamp).
class Machine {
  const Machine({
    this.machineId,
    this.status,
    this.currentJobId,
    this.lastSeen,
  });

  final String? machineId;
  final String? status;
  final String? currentJobId;
  /// Unix timestamp in milliseconds. API returns a number, not a string.
  final int? lastSeen;

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

    return Machine(
      machineId: json['machineId'] as String? ?? json['id'] as String?,
      status: json['status'] as String?,
      currentJobId: json['currentJobId'] as String?,
      lastSeen: lastSeen,
    );
  }
}
