import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/data/models/risk.dart';

/// Attack-surface risk scoring. Scores are computed server-side after each scan;
/// the app only reads and renders them.
class RiskService {
  RiskService(this._api);

  final ApiClient _api;

  /// Latest score, change vs the previous scan, and top 5 open risks.
  /// Throws ApiException 404 "No risk score yet, run a scan first" when never scanned.
  Future<RiskScore> score(String domainId) async =>
      RiskScore.fromJson(await _api.get('/domain/$domainId/risk-score') as Json);

  /// Paginated findings. `status`: OPEN | RESOLVED | ALL. `severity`: comma list. `category` filter.
  Future<Paginated<RiskFinding>> findings(
    String domainId, {
    int? page,
    String? status,
    List<String>? severity,
    String? category,
  }) => _api.getPage(
    '/domain/$domainId/risks',
    RiskFinding.fromJson,
    page: page,
    query: {'status': status, 'severity': severity?.join(','), 'category': category},
  );

  Future<RiskDetail> detail(String riskId) async => RiskDetail.fromJson(await _api.get('/risk/$riskId') as Json);

  /// Score per scan, newest first.
  Future<Paginated<RiskHistoryPoint>> history(String domainId, {int? page, int? limit}) =>
      _api.getPage('/domain/$domainId/risk-history', RiskHistoryPoint.fromJson, page: page, limit: limit);
}
