import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';

class Subdomain {
  final String id;
  final String domainId;
  final String hostname;
  final String? ipAddress;
  final String status;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;

  const Subdomain({
    required this.id,
    required this.domainId,
    required this.hostname,
    required this.status,
    this.ipAddress,
    this.firstSeenAt,
    this.lastSeenAt,
  });

  factory Subdomain.fromJson(Json json) => Subdomain(
    id: json['id'] as String,
    domainId: json['domainId'] as String? ?? '',
    hostname: json['hostname'] as String? ?? '',
    ipAddress: json['ipAddress'] as String?,
    status: json['status'] as String? ?? '',
    firstSeenAt: parseDate(json['firstSeenAt']),
    lastSeenAt: parseDate(json['lastSeenAt']),
  );
}
