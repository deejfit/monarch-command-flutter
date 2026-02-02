import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

/// Settings screen: API URL (editable for setup), app info, polling interval.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: context.read<AppState>().apiBaseUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AppState>(
        builder: (_, state, __) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'API',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'API base URL',
                  hintText: 'https://your-monarch-core.example.com',
                  border: OutlineInputBorder(),
                ),
                controller: _urlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () async {
                    state.setApiBaseUrl(_urlController.text.trim());
                    await state.refreshMachines();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Polling',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Polling interval'),
                subtitle: Text('${state.pollingIntervalMs} ms'),
                trailing: DropdownButton<int>(
                  value: state.pollingIntervalMs.clamp(1000, 10000),
                  items: const [
                    DropdownMenuItem(value: 1000, child: Text('1 s')),
                    DropdownMenuItem(value: 2000, child: Text('2 s')),
                    DropdownMenuItem(value: 3000, child: Text('3 s')),
                    DropdownMenuItem(value: 5000, child: Text('5 s')),
                    DropdownMenuItem(value: 10000, child: Text('10 s')),
                  ],
                  onChanged: (v) => state.setPollingInterval(v ?? 3000),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'App',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              const ListTile(
                title: Text('Monarch Command'),
                subtitle: Text('Mobile control for Monarch Core\nVersion 1.0.0'),
              ),
            ],
          );
        },
      ),
    );
  }
}
