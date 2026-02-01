/// Job model representing a Monarch Core job.
/// All fields that the API may return as null are nullable.
class Job {
  const Job({
    this.id,
    this.prompt,
    required this.status,
    this.machineId,
    this.message,
    this.updatedAt,
  });

  final String? id;
  final String? prompt;
  final JobStatus status;
  final String? machineId;
  final String? message;
  final String? updatedAt;

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String?,
      prompt: json['prompt'] as String?,
      status: jobStatusFromString(json['status'] as String? ?? 'PENDING'),
      machineId: json['machineId'] as String?,
      message: json['message'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Job copyWith({
    String? id,
    String? prompt,
    JobStatus? status,
    String? machineId,
    String? message,
    String? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      status: status ?? this.status,
      machineId: machineId ?? this.machineId,
      message: message ?? this.message,
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
