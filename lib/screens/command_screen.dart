import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/message_bubble.dart';

/// Command screen (home): ChatGPT-like layout with job list and input.
class CommandScreen extends StatefulWidget {
  const CommandScreen({super.key});

  @override
  State<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends State<CommandScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<AppState>().refreshMachines();
      context.read<AppState>().startPolling();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    _controller.clear();
    context.read<AppState>().createJob(prompt).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  void _showMachineSelector(BuildContext context) {
    final state = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select machine',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (state.machines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No machines. Set API URL and refresh.'),
                )
              else
                ...state.machines.map((m) {
                  final machineId = m.machineId ?? m.id;
                  final isSelected = state.selectedMachineId == machineId;
                  return ListTile(
                    title: Text(machineId.isNotEmpty ? machineId : '—'),
                    subtitle: Text(m.status ?? '—'),
                    selected: isSelected,
                    onTap: () {
                      state.setSelectedMachine(
                        isSelected ? null : (machineId.isNotEmpty ? machineId : null),
                      );
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ListTile(
                title: const Text('None'),
                subtitle: const Text('No specific machine'),
                selected: state.selectedMachineId == null,
                onTap: () {
                  state.setSelectedMachine(null);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monarch Command'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AppState>().refreshMachines();
              context.read<AppState>().refreshJobs();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Machine selector bar
          Consumer<AppState>(
            builder: (_, state, __) {
              final machineId = state.selectedMachineId;
              return Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: InkWell(
                  onTap: () => _showMachineSelector(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.computer,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (machineId != null && machineId.isNotEmpty)
                                ? machineId
                                : 'Select machine',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Error banner
          Consumer<AppState>(
            builder: (_, state, __) {
              if (state.error == null) return const SizedBox.shrink();
              return Material(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Message list (timeline: prompt + additive status updates)
          Expanded(
            child: Consumer<AppState>(
              builder: (_, state, __) {
                final entries = state.entriesInOrder;
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Send a command to get started',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    return MessageBubble(entry: entries[i]);
                  },
                );
              },
            ),
          ),
          // Input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter command...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<AppState>(
                  builder: (_, state, __) {
                    return IconButton.filled(
                      onPressed: state.isLoading ? null : _send,
                      icon: state.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.send),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
