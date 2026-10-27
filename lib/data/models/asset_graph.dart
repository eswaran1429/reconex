import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/core/utils/json_utils.dart';
import 'package:reconex/data/models/domain.dart';
import 'package:reconex/data/models/severity.dart';

/// `/domain/graph/:id`: a domain with every subdomain's stored ports, SSL and technologies.
class AssetGraph {
  final Domain domain;
  final Map<Severity, int> bySeverity;
  final List<GraphSubdomain> subdomains;

  const AssetGraph({required this.domain, required this.bySeverity, required this.subdomains});

  factory AssetGraph.fromJson(Json json) => AssetGraph(
    domain: Domain.fromJson(json['domain'] as Json),
    bySeverity: {
      for (final e in asMap(asMap(json['summary'])['bySeverity']).entries) ?Severity.tryParse(e.key): asInt(e.value),
    },
    subdomains: asList(json['subdomains']).map((e) => GraphSubdomain.fromJson(asMap(e))).toList(),
  );
}

class GraphSubdomain {
  final String id;
  final String hostname;
  final String? ipAddress;
  final String status;
  final List<GraphPort> ports;
  final GraphSsl? ssl;
  final List<GraphTechnology> technologies;

  /// Worst finding's severity; null when nothing was flagged.
  final Severity? severity;
  final List<GraphFinding> findings;

  const GraphSubdomain({
    required this.id,
    required this.hostname,
    required this.status,
    required this.ports,
    required this.technologies,
    required this.findings,
    this.ipAddress,
    this.ssl,
    this.severity,
  });

  List<GraphPort> get openPorts => ports.where((p) => p.isOpen).toList();

  factory GraphSubdomain.fromJson(Json json) => GraphSubdomain(
    id: json['id'] as String,
    hostname: json['hostname'] as String? ?? '',
    ipAddress: json['ipAddress'] as String?,
    status: json['status'] as String? ?? '',
    ports: asList(json['ports']).map((e) => GraphPort.fromJson(asMap(e))).toList(),
    ssl: json['ssl'] is Map ? GraphSsl.fromJson(asMap(json['ssl'])) : null,
    technologies: asList(json['technologies']).map((e) => GraphTechnology.fromJson(asMap(e))).toList(),
    severity: Severity.tryParse(json['severity']),
    findings: asList(json['findings']).map((e) => GraphFinding.fromJson(asMap(e))).toList(),
  );
}

class GraphPort {
  final int port;
  final String? protocol;
  final String? service;
  final String state;

  const GraphPort({required this.port, required this.state, this.protocol, this.service});

  bool get isOpen => state.toLowerCase() == 'open';

  factory GraphPort.fromJson(Json json) => GraphPort(
    port: asInt(json['port']),
    protocol: json['protocol'] as String?,
    service: json['service'] as String?,
    state: json['state'] as String? ?? '',
  );
}

class GraphSsl {
  final bool? valid;
  final DateTime? expiresAt;
  final Object? issuer;
  final String? tlsVersion;

  const GraphSsl({this.valid, this.expiresAt, this.issuer, this.tlsVersion});

  factory GraphSsl.fromJson(Json json) => GraphSsl(
    valid: json['valid'] as bool?,
    expiresAt: parseDate(json['expiresAt']),
    issuer: json['issuer'],
    tlsVersion: json['tlsVersion'] as String?,
  );
}

class GraphTechnology {
  final String name;
  final String? version;
  final String? category;

  const GraphTechnology({required this.name, this.version, this.category});

  factory GraphTechnology.fromJson(Json json) => GraphTechnology(
    name: json['name'] as String? ?? '',
    version: json['version'] as String?,
    category: json['category'] as String?,
  );
}

class GraphFinding {
  final String ruleId;
  final Severity? severity;

  const GraphFinding({required this.ruleId, this.severity});

  /// Readable text for the backend's risk rule ids.
  String get label => switch (ruleId) {
    'ssl.expired' => 'SSL certificate has expired',
    'ssl.invalid' => 'SSL certificate is invalid',
    'ssl.expiring' => 'SSL certificate expires within 14 days',
    'ssl.old_tls' => 'Outdated TLS version',
    'port.database.exposed' => 'Database port is publicly open',
    'port.remote_admin.exposed' => 'SSH or FTP port is publicly open',
    'port.plaintext_http' => 'Serves HTTP without HTTPS',
    'tech.version_disclosed' => 'Software versions are disclosed',
    _ => humanize(ruleId.replaceAll('.', ' ')),
  };

  factory GraphFinding.fromJson(Json json) =>
      GraphFinding(ruleId: json['ruleId'] as String? ?? '', severity: Severity.tryParse(json['severity']));
}
