import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/severity.dart';

class AppAlert {
  final String id;
  final String domainId;
  final String domainName;
  final String type;
  final Severity? severity;
  final String title;
  final String message;
  final DateTime? createdAt;

  const AppAlert({
    required this.id,
    required this.domainId,
    required this.domainName,
    required this.type,
    required this.title,
    required this.message,
    this.severity,
    this.createdAt,
  });

  factory AppAlert.fromJson(Json json) => AppAlert(
    id: json['id'] as String,
    domainId: json['domainId'] as String? ?? '',
    domainName: json['domainName'] as String? ?? '',
    type: json['type'] as String? ?? '',
    severity: Severity.tryParse(json['severity']),
    title: json['title'] as String? ?? '',
    message: json['message'] as String? ?? '',
    createdAt: parseDate(json['createdAt']),
  );
}
