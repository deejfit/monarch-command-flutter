import 'package:flutter/material.dart';

import '../models/job_timeline.dart';
import 'status_badge.dart';

/// Chat-style bubble for one timeline entry (prompt or status update).
/// Content is never replaced; status updates are additive.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.entry});

  final JobTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final isUser = entry.role == JobTimelineRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            StatusBadge(status: entry.status),
          ],
        ),
      ),
    );
  }
}
