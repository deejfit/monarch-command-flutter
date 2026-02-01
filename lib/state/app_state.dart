import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/job.dart';
import '../models/job_timeline.dart';
import '../models/machine.dart';
import '../services/api_client.dart';

/// App state. All state is read from the API; no local inference.
class AppState extends ChangeNotifier {
  AppState() {
    _api = ApiClient(baseUrl: _apiBaseUrl);
  }

  String _apiBaseUrl = 'http://localhost:3000';
  late ApiClient _api;
  String? _selectedMachineId;
  List<Machine> _machines = [];
  List<JobWithTimeline> _jobTimelines = [];
  int _pollingIntervalMs = 3000;
  String? _error;
  bool _isLoading = false;
  Timer? _pollTimer;

  String get apiBaseUrl => _apiBaseUrl;
  String? get selectedMachineId => _selectedMachineId;
  List<Machine> get machines => List.unmodifiable(_machines);
  List<JobWithTimeline> get jobTimelines => List.unmodifiable(_jobTimelines);

  /// Flattened timeline: newest job first, then per job user → response → completed. (With reverse ListView, first item is at bottom.)
  List<JobTimelineEntry> get entriesInOrder => [
        for (final j in _jobTimelines) ...j.entries,
      ];

  int get pollingIntervalMs => _pollingIntervalMs;
  String? get error => _error;
  bool get isLoading => _isLoading;

  void setApiBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed == _apiBaseUrl) return;
    _apiBaseUrl = trimmed;
    _api = ApiClient(baseUrl: _apiBaseUrl.isEmpty ? 'http://localhost:300' : _apiBaseUrl);
    _error = null;
    _stopPolling();
    notifyListeners();
  }

  void setSelectedMachine(String? machineId) {
    if (_selectedMachineId == machineId) return;
    _selectedMachineId = machineId;
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
      notifyListeners();
    }
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

  Future<Job?> createJob(String prompt) async {
    if (!hasValidApiUrl) {
      _error = 'API base URL not set';
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
      );
      // Store job (id from POST response) for polling GET /jobs/:jobId
      _jobTimelines = [JobWithTimeline.fromJob(job), ..._jobTimelines];
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
