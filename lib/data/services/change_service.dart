import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/change.dart';

class ChangeService {
  ChangeService(this._api);

  final ApiClient _api;

  /// Newest first.
  Future<Paginated<Change>> listForDomain(
    String domainId, {
    int? page,
    int? limit,
    String? category,
    String? type,
    List<String>? severity,
    String? scanId,
  }) => _api.getPage(
    '/domain/changes/$domainId',
    Change.fromJson,
    page: page,
    limit: limit,
    query: {'category': category, 'type': type, 'severity': severity?.join(','), 'scanId': scanId},
  );

  Future<Change> get(String changeId) async => Change.fromJson(await _api.get('/change/get/$changeId') as Json);
}
