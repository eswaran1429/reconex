import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/severity.dart';

class Change {
  final String id;
  final String domainId;
  final String scanId;
  final String category;
  final String type;
  final String key;
  final Severity? severity;
  final dynamic before;
  final dynamic after;
  final DateTime? createdAt;

  /// Only on `GET /change/get/:id`: `{ id, status, createdAt, completedAt }`.
  final Json? scan;

  const Change({
    required this.id,
    required this.domainId,
    required this.scanId,
    required this.category,
    required this.type,
    required this.key,
    this.severity,
    this.before,
    this.after,
    this.createdAt,
    this.scan,
  });

  factory Change.fromJson(Json json) => Change(
    id: json['id'] as String,
    domainId: json['domainId'] as String? ?? '',
    scanId: json['scanId'] as String? ?? '',
    category: json['category'] as String? ?? '',
    type: json['type'] as String? ?? '',
    key: json['key'] as String? ?? '',
    severity: Severity.tryParse(json['severity']),
    before: json['before'],
    after: json['after'],
    createdAt: parseDate(json['createdAt']),
    scan: json['scan'] is Map ? Json.from(json['scan'] as Map) : null,
  );
}
