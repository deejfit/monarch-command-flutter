import 'package:flutter/material.dart';

import '../models/job.dart';

/// Status badge for job state (PENDING / RUNNING / DONE / ERROR).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final JobStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (Color, Color) get _colors {
    switch (status) {
      case JobStatus.pending:
        return (Colors.orange.shade800, Colors.orange.shade100);
      case JobStatus.running:
        return (Colors.blue.shade800, Colors.blue.shade100);
      case JobStatus.done:
        return (Colors.green.shade800, Colors.green.shade100);
      case JobStatus.error:
        return (Colors.red.shade800, Colors.red.shade100);
    }
  }
}
