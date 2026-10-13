import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/subdomain.dart';

class SubdomainService {
  SubdomainService(this._api);

  final ApiClient _api;

  /// Live scan. Returns the subdomains found for the domain.
  Future<List<Subdomain>> discover(String domainId) async =>
      (await _api.get('/subdomain/discover/$domainId') as List<dynamic>)
          .map((e) => Subdomain.fromJson(e as Json))
          .toList();

  /// Sorted by hostname.
  Future<Paginated<Subdomain>> list(String domainId, {int? page, int? limit}) =>
      _api.getPage('/subdomain/list/$domainId', Subdomain.fromJson, page: page, limit: limit);

  Future<Subdomain> get(String subdomainId) async =>
      Subdomain.fromJson(await _api.get('/subdomain/$subdomainId') as Json);

  /// Live scan. Throws 502 if the host can't be reached or has no certificate.
  Future<Json> ssl(String subdomainId) async => await _api.get('/subdomain/ssl/$subdomainId') as Json;
}
