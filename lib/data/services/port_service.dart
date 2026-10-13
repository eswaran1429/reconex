import 'package:reconex/core/network/api_client.dart';

class PortService {
  PortService(this._api);

  final ApiClient _api;

  /// Live scan. Returns the open ports.
  Future<List<dynamic>> discover(String subdomainId) async =>
      await _api.get('/port/discover/$subdomainId') as List<dynamic>;

  /// Stored ports, open and closed, sorted by port number.
  Future<List<dynamic>> list(String subdomainId) async => await _api.get('/port/get/$subdomainId') as List<dynamic>;
}
