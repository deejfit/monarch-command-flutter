import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/job.dart';
import '../models/machine.dart';

/// API client for Monarch Core.
/// All state is read from the API; no local inference.
class ApiClient {
  ApiClient({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// GET /machines
  Future<List<Machine>> getMachines() async {
    final response = await http.get(_uri('/machines'));
    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to fetch machines: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Machine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /machines/:machineId
  Future<Machine> getMachine(String machineId) async {
    final response = await http.get(_uri('/machines/$machineId'));
    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to fetch machine: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return Machine.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// POST /jobs
  /// Sends a job prompt. Optionally include machineId.
  Future<Job> postJob({
    required String prompt,
    String? machineId,
  }) async {
    final body = <String, dynamic>{'prompt': prompt};
    if (machineId != null && machineId.isNotEmpty) {
      body['machineId'] = machineId;
    }
    final response = await http.post(
      _uri('/jobs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        'Failed to create job: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return Job.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// GET /jobs/:jobId
  Future<Job> getJob(String jobId) async {
    final response = await http.get(_uri('/jobs/$jobId'));
    if (response.statusCode != 200) {
      throw ApiException(
        'Failed to fetch job: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return Job.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
