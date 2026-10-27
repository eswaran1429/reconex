import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/network.dart';

/// Saved local networks and their stored scan results.
class NetworkService {
  NetworkService(this._api);

  final ApiClient _api;

  /// `subnet` must be a private IPv4 CIDR, /22 or smaller (checked by the server).
  Future<NetworkProfile> add({required String name, required String subnet}) async =>
      NetworkProfile.fromJson(await _api.post('/network/add', data: {'name': name, 'subnet': subnet}) as Json);

  Future<List<NetworkProfile>> getAll() async =>
      (await _api.get('/network/get') as List<dynamic>).map((e) => NetworkProfile.fromJson(e as Json)).toList();

  Future<NetworkProfile> getById(String networkId) async =>
      NetworkProfile.fromJson(await _api.get('/network/get/$networkId') as Json);

  Future<void> rename(String networkId, String name) => _api.put('/network/update/$networkId', data: {'name': name});

  /// Also deletes the network's scans, devices, changes and alerts.
  Future<void> delete(String networkId) => _api.delete('/network/delete/$networkId');

  Future<Json> dashboard(String networkId) async => await _api.get('/network/dashboard/$networkId') as Json;

  /// Newest first.
  Future<Paginated<NetworkScanRecord>> scans(String networkId, {int? page}) =>
      _api.getPage('/network/scans/$networkId', NetworkScanRecord.fromJson, page: page);

  Future<NetworkScanRecord> scan(String scanId) async =>
      NetworkScanRecord.fromJson(await _api.get('/network-scan/get/$scanId') as Json);

  /// Devices seen in one scan, sorted by IP.
  Future<Paginated<NetworkObservation>> scanDevices(String scanId, {int? page}) =>
      _api.getPage('/network-scan/devices/$scanId', NetworkObservation.fromJson, page: page);

  /// `seenLatest`: only devices seen in the latest completed scan.
  Future<Paginated<NetworkDevice>> devices(String networkId, {int? page, bool seenLatest = false}) => _api.getPage(
    '/network/devices/$networkId',
    NetworkDevice.fromJson,
    page: page,
    query: {'seen': seenLatest ? 'latest' : null},
  );

  Future<Paginated<NetworkChange>> changes(String networkId, {int? page, String? scanId}) =>
      _api.getPage('/network/changes/$networkId', NetworkChange.fromJson, page: page, query: {'scanId': scanId});

  Future<NetworkDevice> device(String deviceId) async =>
      NetworkDevice.fromJson(await _api.get('/network-device/get/$deviceId') as Json);

  Future<List<NetworkPort>> devicePorts(String deviceId) async =>
      (await _api.get('/network-device/ports/$deviceId') as List<dynamic>)
          .map((e) => NetworkPort.fromJson(e as Json))
          .toList();

  Future<Paginated<NetworkObservation>> deviceHistory(String deviceId, {int? page}) => _api.getPage(
    '/network-device/history/$deviceId',
    (j) => NetworkObservation.fromJson({...j, 'deviceId': deviceId}),
    page: page,
  );
}
