import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/app_alert.dart';

class AlertService {
  AlertService(this._api);

  final ApiClient _api;

  /// Alerts across all domains, newest first.
  Future<Paginated<AppAlert>> list({
    int? page,
    int? limit,
    String? domainId,
    List<String>? severity,
    String? type,
    DateTime? since,
  }) => _api.getPage(
    '/alert/get',
    AppAlert.fromJson,
    page: page,
    limit: limit,
    query: {
      'domainId': domainId,
      'severity': severity?.join(','),
      'type': type,
      'since': since?.toIso8601String().split('T').first,
    },
  );
}
