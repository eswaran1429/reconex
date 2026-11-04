import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/severity.dart';

/// Score bands from the API: low 0-19, moderate 20-39, high 40-59, very_high 60-79, critical 80-100.
enum RiskLevel {
  low,
  moderate,
  high,
  veryHigh,
  critical;

  static RiskLevel? tryParse(Object? value) => switch (value) {
    'low' => RiskLevel.low,
    'moderate' => RiskLevel.moderate,
    'high' => RiskLevel.high,
    'very_high' => RiskLevel.veryHigh,
    'critical' => RiskLevel.critical,
    _ => null,
  };
}

/// One asset a finding affects: a subdomain, or a URL.
class RiskAsset {
  final String type;
  final String? id;
  final String? hostname;
  final String? ipAddress;
  final String? url;

  const RiskAsset({required this.type, this.id, this.hostname, this.ipAddress, this.url});

  String get label => hostname ?? url ?? ipAddress ?? id ?? 'Unknown asset';

  factory RiskAsset.fromJson(Json json) => RiskAsset(
    type: json['type'] as String? ?? 'asset',
    id: json['id'] as String?,
    hostname: json['hostname'] as String?,
    ipAddress: json['ipAddress'] as String?,
    url: json['url'] as String?,
  );
}

/// How one category adds to the score. `points` is after the per-category `cap`.
class RiskBreakdown {
  final String category;
  final int findings;
  final int rawPoints;
  final int points;
  final int cap;

  const RiskBreakdown({
    required this.category,
    required this.findings,
    required this.rawPoints,
    required this.points,
    required this.cap,
  });

  /// True when the category hit its ceiling, so more findings there don't add more.
  bool get capped => rawPoints > points;

  factory RiskBreakdown.fromJson(Json json) => RiskBreakdown(
    category: json['category'] as String? ?? '',
    findings: json['findings'] as int? ?? 0,
    rawPoints: json['rawPoints'] as int? ?? 0,
    points: json['points'] as int? ?? 0,
    cap: json['cap'] as int? ?? 0,
  );
}

class RiskFinding {
  final String id;
  final String domainId;
  final String category;
  final String ruleId;
  final String title;
  final String? description;
  final Severity? severity;
  final int scoreContribution;
  final List<RiskAsset> affectedAssets;
  final String? remediation;
  final String status;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;
  final DateTime? resolvedAt;

  const RiskFinding({
    required this.id,
    required this.domainId,
    required this.category,
    required this.ruleId,
    required this.title,
    required this.status,
    this.description,
    this.severity,
    this.scoreContribution = 0,
    this.affectedAssets = const [],
    this.remediation,
    this.firstSeenAt,
    this.lastSeenAt,
    this.resolvedAt,
  });

  bool get isOpen => status == 'OPEN';

  factory RiskFinding.fromJson(Json json) => RiskFinding(
    id: json['id'] as String,
    domainId: json['domainId'] as String? ?? '',
    category: json['category'] as String? ?? '',
    ruleId: json['ruleId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String?,
    severity: Severity.tryParse(json['severity']),
    scoreContribution: json['scoreContribution'] as int? ?? 0,
    affectedAssets: (json['affectedAssets'] as List<dynamic>? ?? const [])
        .map((e) => RiskAsset.fromJson(e as Json))
        .toList(),
    remediation: json['remediation'] as String?,
    status: json['status'] as String? ?? 'OPEN',
    firstSeenAt: parseDate(json['firstSeenAt']),
    lastSeenAt: parseDate(json['lastSeenAt']),
    resolvedAt: parseDate(json['resolvedAt']),
  );
}

/// Full finding, adds evidence and scan context on top of [RiskFinding].
class RiskDetail {
  final RiskFinding finding;
  final Json evidence;
  final Json? lastScan;

  const RiskDetail({required this.finding, this.evidence = const {}, this.lastScan});

  factory RiskDetail.fromJson(Json json) => RiskDetail(
    finding: RiskFinding.fromJson(json),
    evidence: json['evidence'] is Map ? Json.from(json['evidence'] as Map) : const {},
    lastScan: json['lastScan'] is Map ? Json.from(json['lastScan'] as Map) : null,
  );
}

class RiskScore {
  final int score;
  final RiskLevel? level;
  final String levelLabel;
  final int? previousScore;
  final int? delta;
  final int findingCount;
  final Map<String, int> bySeverity;
  final Map<String, int> byCategory;
  final List<RiskBreakdown> breakdown;
  final List<RiskFinding> topRisks;
  final DateTime? calculatedAt;

  const RiskScore({
    required this.score,
    required this.levelLabel,
    this.level,
    this.previousScore,
    this.delta,
    this.findingCount = 0,
    this.bySeverity = const {},
    this.byCategory = const {},
    this.breakdown = const [],
    this.topRisks = const [],
    this.calculatedAt,
  });

  int severityCount(Severity s) => bySeverity[s.name] ?? 0;

  factory RiskScore.fromJson(Json json) => RiskScore(
    score: json['score'] as int? ?? 0,
    level: RiskLevel.tryParse(json['level']),
    levelLabel: json['levelLabel'] as String? ?? humanize((json['level'] as String?) ?? 'low'),
    previousScore: json['previousScore'] as int?,
    delta: json['delta'] as int?,
    findingCount: json['findingCount'] as int? ?? 0,
    bySeverity: _intMap(json['bySeverity']),
    byCategory: _intMap(json['byCategory']),
    breakdown: (json['breakdown'] as List<dynamic>? ?? const []).map((e) => RiskBreakdown.fromJson(e as Json)).toList(),
    topRisks: (json['topRisks'] as List<dynamic>? ?? const []).map((e) => RiskFinding.fromJson(e as Json)).toList(),
    calculatedAt: parseDate(json['calculatedAt']),
  );

  static Map<String, int> _intMap(Object? value) =>
      value is Map ? value.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)) : const {};
}

/// One point on the history chart: score at a past scan.
class RiskHistoryPoint {
  final String scanId;
  final int score;
  final RiskLevel? level;
  final DateTime? calculatedAt;

  const RiskHistoryPoint({required this.scanId, required this.score, this.level, this.calculatedAt});

  factory RiskHistoryPoint.fromJson(Json json) => RiskHistoryPoint(
    scanId: json['scanId'] as String? ?? '',
    score: json['score'] as int? ?? 0,
    level: RiskLevel.tryParse(json['level']),
    calculatedAt: parseDate(json['calculatedAt']),
  );
}
