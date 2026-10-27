import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/severity.dart';

/// An alert belongs to a domain or to a local network, never both.
class AppAlert {
  final String id;
  final String? domainId;
  final String? networkId;
  final String type;
  final Severity? severity;
  final String title;
  final String message;
  final DateTime? createdAt;

  /// Name of the owning domain or network.
  final String sourceName;

  const AppAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.sourceName,
    this.domainId,
    this.networkId,
    this.severity,
    this.createdAt,
  });

  bool get isNetwork => networkId != null;

  factory AppAlert.fromJson(Json json) => AppAlert(
    id: json['id'] as String,
    domainId: json['domainId'] as String?,
    networkId: json['networkId'] as String?,
    sourceName: (json['domainName'] ?? json['networkName']) as String? ?? '',
    type: json['type'] as String? ?? '',
    severity: Severity.tryParse(json['severity']),
    title: json['title'] as String? ?? '',
    message: json['message'] as String? ?? '',
    createdAt: parseDate(json['createdAt']),
  );
}
