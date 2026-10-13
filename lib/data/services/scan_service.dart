import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/change.dart';
import 'package:reconex/data/models/scan.dart';

class ScanService {
  ScanService(this._api);

  final ApiClient _api;

  /// Starts a background scan and returns the scan record. Throws 409 if one is already queued or running.
  Future<Scan> start(String domainId) async => Scan.fromJson(await _api.post('/domain/scan/$domainId') as Json);

  /// Newest first. `status`: QUEUED, RUNNING, COMPLETED, PARTIAL or FAILED.
  Future<Paginated<Scan>> listForDomain(String domainId, {int? page, int? limit, String? status}) =>
      _api.getPage('/domain/scans/$domainId', Scan.fromJson, page: page, limit: limit, query: {'status': status});

  /// Small payload for polling: status, progress, currentStep, steps.
  Future<Json> status(String scanId) async => await _api.get('/scan/status/$scanId') as Json;

  Future<Scan> get(String scanId) async => Scan.fromJson(await _api.get('/scan/get/$scanId') as Json);

  Future<Paginated<Change>> changes(
    String scanId, {
    int? page,
    int? limit,
    String? category,
    String? type,
    List<String>? severity,
  }) => _api.getPage(
    '/scan/changes/$scanId',
    Change.fromJson,
    page: page,
    limit: limit,
    query: {'category': category, 'type': type, 'severity': severity?.join(',')},
  );
}
