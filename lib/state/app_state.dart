import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/job.dart';
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
  List<Job> _jobs = [];
  int _pollingIntervalMs = 3000;
  String? _error;
  bool _isLoading = false;
  Timer? _pollTimer;

  String get apiBaseUrl => _apiBaseUrl;
  String? get selectedMachineId => _selectedMachineId;
  List<Machine> get machines => List.unmodifiable(_machines);
  List<Job> get jobs => List.unmodifiable(_jobs);
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
    _clearError();
    _isLoading = true;
    notifyListeners();
    try {
      // Monarch Core may have a GET /jobs endpoint; if not, we keep jobs
      // from POST response and poll individual job status.
      // For now we only have GET /jobs/:jobId, so we refresh known jobs.
      final updated = <Job>[];
      for (final job in _jobs) {
        final jobId = job.id;
        if (jobId == null || jobId.isEmpty) {
          updated.add(job);
          continue;
        }
        try {
          updated.add(await _api.getJob(jobId));
        } catch (_) {
          updated.add(job);
        }
      }
      _jobs = updated;
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
      _jobs = [job, ..._jobs];
      _startPolling();
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
    if (_jobs.isNotEmpty && hasValidApiUrl) _startPolling();
  }

  void stopPolling() => _stopPolling();

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
