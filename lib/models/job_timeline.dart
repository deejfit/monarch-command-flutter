import 'job.dart';

/// A single immutable message in a job's timeline (chat-style).
/// Status updates are additive; never remove or overwrite.
enum JobTimelineRole {
  user,
  system,
}

class JobTimelineEntry {
  JobTimelineEntry({
    required this.role,
    required this.content,
    required this.status,
    required this.jobId,
    required this.timestamp,
  });

  final JobTimelineRole role;
  final String content;
  final JobStatus status;
  final String jobId;
  final DateTime timestamp;
}

/// A job plus its immutable timeline of messages.
/// Entries are appended when API status changes; prompt is never replaced.
class JobWithTimeline {
  const JobWithTimeline({
    required this.job,
    required this.entries,
  });

  final Job job;
  final List<JobTimelineEntry> entries;

  /// Creates the initial timeline: one user message with the prompt and PENDING.
  static JobWithTimeline fromJob(Job job) {
    final prompt = job.prompt ?? '—';
    final jobId = job.id ?? '';
    return JobWithTimeline(
      job: job,
      entries: [
        JobTimelineEntry(
          role: JobTimelineRole.user,
          content: prompt,
          status: JobStatus.pending,
          jobId: jobId,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Appends status messages based on current API job; never mutates existing entries.
  /// Within a job, ordering is by timestamp.
  JobWithTimeline applyStatusFromApi(Job updatedJob) {
    final next = List<JobTimelineEntry>.from(entries);
    final hasRunning = next.any((e) => e.status == JobStatus.running);
    final hasDone = next.any((e) => e.status == JobStatus.done);
    final hasError = next.any((e) => e.status == JobStatus.error);
    final jobId = updatedJob.id ?? '';

    if (updatedJob.status == JobStatus.running && !hasRunning) {
      next.add(JobTimelineEntry(
        role: JobTimelineRole.system,
        content: 'Running…',
        status: JobStatus.running,
        jobId: jobId,
        timestamp: DateTime.now(),
      ));
    }
    if (updatedJob.status == JobStatus.done && !hasDone) {
      next.add(JobTimelineEntry(
        role: JobTimelineRole.system,
        content: updatedJob.message?.isNotEmpty == true
            ? updatedJob.message!
            : 'Done',
        status: JobStatus.done,
        jobId: jobId,
        timestamp: DateTime.now(),
      ));
    }
    if (updatedJob.status == JobStatus.error && !hasError) {
      next.add(JobTimelineEntry(
        role: JobTimelineRole.system,
        content: updatedJob.message?.isNotEmpty == true
            ? updatedJob.message!
            : 'Error',
        status: JobStatus.error,
        jobId: jobId,
        timestamp: DateTime.now(),
      ));
    }

    next.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return JobWithTimeline(job: updatedJob, entries: next);
  }
}
