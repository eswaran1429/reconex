import 'package:reconex/core/network/api_client.dart';

class TechnologyService {
  TechnologyService(this._api);

  final ApiClient _api;

  /// Live scan. Returns everything ever detected on the subdomain. Throws 502 if unreachable.
  Future<List<dynamic>> detect(String subdomainId) async => await _api.get('/technology/$subdomainId') as List<dynamic>;
}
