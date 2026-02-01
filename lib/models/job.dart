/// Job model representing a Monarch Core job.
/// All fields that the API may return as null are nullable.
/// createdAt and updatedAt are numeric timestamps (ms), not strings.
class Job {
  const Job({
    this.id,
    this.prompt,
    required this.status,
    this.machineId,
    this.message,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? prompt;
  final JobStatus status;
  final String? machineId;
  final String? message;
  /// Unix timestamp in milliseconds. API returns a number.
  final int? createdAt;
  /// Unix timestamp in milliseconds. API returns a number.
  final int? updatedAt;

  factory Job.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['jobId'] ?? json['job_id'];
    final id = idRaw is String ? idRaw : idRaw?.toString();
    return Job(
      id: id,
      prompt: json['prompt'] as String?,
      status: _parseStatus(json['status']),
      machineId: json['machineId'] as String?,
      message: json['message'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
    );
  }

  static int? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static JobStatus _parseStatus(dynamic value) {
    if (value == null) return JobStatus.pending;
    final s = value is String ? value : value.toString();
    return jobStatusFromString(s);
  }

  Job copyWith({
    String? id,
    String? prompt,
    JobStatus? status,
    String? machineId,
    String? message,
    int? createdAt,
    int? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      status: status ?? this.status,
      machineId: machineId ?? this.machineId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum JobStatus {
  pending,
  running,
  done,
  error,
}

JobStatus jobStatusFromString(String value) {
  final normalized = value.toUpperCase();
  switch (normalized) {
    case 'PENDING':
      return JobStatus.pending;
    case 'RUNNING':
      return JobStatus.running;
    case 'DONE':
      return JobStatus.done;
    case 'ERROR':
      return JobStatus.error;
    default:
      return JobStatus.pending;
  }
}

extension JobStatusX on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.pending:
        return 'PENDING';
      case JobStatus.running:
        return 'RUNNING';
      case JobStatus.done:
        return 'DONE';
      case JobStatus.error:
        return 'ERROR';
    }
  }
}
