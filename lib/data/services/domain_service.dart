import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/domain.dart';

class DomainService {
  DomainService(this._api);

  final ApiClient _api;

  /// `url` must start with http:// or https://. Throws 409 if the name already exists.
  Future<void> add({required String name, required String url}) =>
      _api.post('/domain/add', data: {'name': name, 'url': url});

  Future<List<Domain>> getAll() async =>
      (await _api.get('/domain/get') as List<dynamic>).map((e) => Domain.fromJson(e as Json)).toList();

  Future<Domain> getById(String domainId) async => Domain.fromJson(await _api.get('/domain/get/$domainId') as Json);

  /// `status` is `ACTIVE` or `INACTIVE`. At least one field is required.
  Future<void> update(String domainId, {String? name, String? url, String? status}) =>
      _api.put('/domain/update/$domainId', data: {'name': ?name, 'url': ?url, 'status': ?status});

  /// Also deletes the domain's subdomains, scans, changes, alerts and findings.
  Future<void> delete(String domainId) => _api.delete('/domain/delete/$domainId');

  Future<Json> dashboard(String domainId) async => await _api.get('/domain/dashboard/$domainId') as Json;

  /// Live scan.
  Future<List<dynamic>> dns(String domainId) async => await _api.get('/domain/dns/$domainId') as List<dynamic>;

  /// Live scan.
  Future<List<dynamic>> securityHeaders(String domainId) async =>
      await _api.get('/domain/security-headers/$domainId') as List<dynamic>;

  /// Live scan.
  Future<List<dynamic>> exposedResources(String domainId) async =>
      await _api.get('/domain/exposed-resources/$domainId') as List<dynamic>;

  /// `type` is `headers` or `exposed_resources`. Items: `{ type, scannedAt, total, issues, results }`.
  Future<Paginated<Json>> history(String domainId, {int? page, int? limit, String? type}) =>
      _api.getPage('/domain/history/$domainId', (j) => j, page: page, limit: limit, query: {'type': type});

  /// Ports across all subdomains, each with `hostname` and `ipAddress`. `state` is `open` or `closed`.
  Future<Paginated<Json>> ports(String domainId, {int? page, int? limit, String? state}) =>
      _api.getPage('/domain/ports/$domainId', (j) => j, page: page, limit: limit, query: {'state': state});

  /// Items: `{ name, category, subdomainCount, subdomains: [{ hostname, version }] }`.
  Future<List<dynamic>> technologies(String domainId) async {
    final data = await _api.get('/domain/technologies/$domainId');
    return data is Map ? data['items'] as List<dynamic> : data as List<dynamic>;
  }
}
