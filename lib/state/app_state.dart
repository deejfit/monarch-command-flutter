import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/job.dart';
import '../models/job_timeline.dart';
import '../models/machine.dart';
import '../services/api_client.dart';

const String _defaultApiBaseUrl = 'http://localhost:3000';
const String _apiBaseUrlFromEnv = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: _defaultApiBaseUrl,
);

/// App state. All state is read from the API; no local inference.
class AppState extends ChangeNotifier {
  AppState() : _apiBaseUrl = _apiBaseUrlFromEnv {
    _api = ApiClient(baseUrl: _apiBaseUrl);
  }

  String _apiBaseUrl;
  late ApiClient _api;
  String? _selectedMachineId;
  String? _selectedClient;
  List<Machine> _machines = [];
  List<JobWithTimeline> _jobTimelines = [];
  int _pollingIntervalMs = 3000;
  String? _error;
  bool _isLoading = false;
  Timer? _pollTimer;

  String get apiBaseUrl => _apiBaseUrl;
  String? get selectedMachineId => _selectedMachineId;
  String? get selectedClient => _selectedClient;

  /// Clients available for selection: selected machine's clients, or union of all machines' when no machine selected.
  List<String> get availableClients {
    if (_selectedMachineId != null) {
      final match =
          _machines.where((m) => m.id == _selectedMachineId).toList();
      return match.isEmpty ? const <String>[] : match.first.clients;
    }
    final union = <String>{};
    for (final m in _machines) {
      union.addAll(m.clients);
    }
    return union.toList()..sort();
  }

  List<Machine> get machines => List.unmodifiable(_machines);
  List<JobWithTimeline> get jobTimelines => List.unmodifiable(_jobTimelines);

  /// Flattened timeline: oldest job first, then per job entries by timestamp. Reads top-to-bottom as chronological chat.
  List<JobTimelineEntry> get entriesInOrder => [
        for (final j in _jobTimelines.reversed) ...j.entries,
      ];

  int get pollingIntervalMs => _pollingIntervalMs;
  String? get error => _error;
  bool get isLoading => _isLoading;

  void setApiBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed == _apiBaseUrl) return;
    _apiBaseUrl = trimmed;
    _api = ApiClient(
        baseUrl: _apiBaseUrl.isEmpty ? _defaultApiBaseUrl : _apiBaseUrl);
    _error = null;
    _stopPolling();
    notifyListeners();
  }

  void setSelectedMachine(String? machineId) {
    if (_selectedMachineId == machineId) return;
    _selectedMachineId = machineId;
    if (machineId != null) {
      final match =
          _machines.where((m) => m.id == machineId).toList();
      final allowed =
          match.isEmpty ? const <String>[] : match.first.clients;
      if (_selectedClient != null && !allowed.contains(_selectedClient)) {
        _selectedClient = null;
      }
    }
    if (_selectedClient == null) {
      final c = availableClients;
      if (c.isNotEmpty) _selectedClient = c.first;
    }
    notifyListeners();
  }

  void setSelectedClient(String? client) {
    if (_selectedClient == client) return;
    _selectedClient = client;
    notifyListeners();
  }

  void setPollingInterval(int ms) {
    if (_pollingIntervalMs == ms) return;
    _pollingIntervalMs = ms;
    _restartPollingIfActive();
    notifyListeners();
  }

  bool get hasValidApiUrl => _apiBaseUrl.trim().isNotEmpty;

  Future<void> refreshMachines() async {
    if (!hasValidApiUrl) return;
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      _machines = await _api.getMachines();
      if (_machines.length == 1) {
        final id = _machines.single.machineId ?? _machines.single.id;
        if (id.isNotEmpty) _selectedMachineId = id;
      } else if (_selectedMachineId != null) {
        final exists = _machines.any((m) => m.id == _selectedMachineId);
        if (!exists) _selectedMachineId = null;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      if (_selectedClient == null) {
        final c = availableClients;
        if (c.isNotEmpty) _selectedClient = c.first;
      }
      notifyListeners();
    }
  }

  /// Clears all job timelines (chat). Stops polling.
  void clearChat() {
    _jobTimelines = [];
    _stopPolling();
    notifyListeners();
  }

  Future<void> refreshJobs() async {
    if (!hasValidApiUrl) return;
    final hasIncomplete = _jobTimelines.any((jt) {
      final s = jt.job.status;
      return s != JobStatus.done && s != JobStatus.error;
    });
    if (!hasIncomplete) {
      _stopPolling();
      return;
    }
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      final updated = <JobWithTimeline>[];
      for (final jt in _jobTimelines) {
        final job = jt.job;
        final status = job.status;
        if (status == JobStatus.done || status == JobStatus.error) {
          updated.add(jt);
          continue;
        }
        final jobId = job.id;
        if (jobId == null || jobId.isEmpty) {
          updated.add(jt);
          continue;
        }
        try {
          final fetched = await _api.getJob(jobId);
          updated.add(jt.applyStatusFromApi(fetched));
        } catch (_) {
          updated.add(jt);
        }
      }
      _jobTimelines = updated;
      final allComplete = updated.every((jt) {
        final s = jt.job.status;
        return s == JobStatus.done || s == JobStatus.error;
      });
      if (allComplete) _stopPolling();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Job?> createJob(String prompt, {required String client}) async {
    if (!hasValidApiUrl) {
      _error = 'API base URL not set';
      notifyListeners();
      return null;
    }
    if (client.trim().isEmpty) {
      _error = 'Select an app client';
      notifyListeners();
      return null;
    }
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      final job = await _api.postJob(
        prompt: prompt,
        machineId: _selectedMachineId,
        client: client,
      );
      // Store job (id from POST response) for polling GET /jobs/:jobId
      _jobTimelines = [
        JobWithTimeline.fromJob(job, client: client),
        ..._jobTimelines
      ];
      _startPolling();
      // Poll immediately so we don't wait for first timer tick
      refreshJobs();
      return job;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(
      Duration(milliseconds: _pollingIntervalMs),
      (_) => refreshJobs(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _restartPollingIfActive() {
    if (_pollTimer != null) {
      _startPolling();
    }
  }

  void startPolling() {
    if (_jobTimelines.isNotEmpty && hasValidApiUrl) _startPolling();
  }

  void stopPolling() => _stopPolling();

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
