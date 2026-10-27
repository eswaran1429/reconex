import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/utils/formatters.dart';
import 'package:reconex/data/models/severity.dart';

// Local network models. Unknown values stay null and are shown as "Unknown";
// nothing is filled in by the app.

class NetworkProfile {
  final String id;
  final String name;
  final String subnet;
  final DateTime? lastScanAt;
  final int deviceCount;
  final DateTime? createdAt;

  const NetworkProfile({
    required this.id,
    required this.name,
    required this.subnet,
    this.lastScanAt,
    this.deviceCount = 0,
    this.createdAt,
  });

  factory NetworkProfile.fromJson(Json json) => NetworkProfile(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    subnet: json['subnet'] as String? ?? '',
    lastScanAt: parseDate(json['lastScanAt']),
    deviceCount: json['deviceCount'] as int? ?? 0,
    createdAt: parseDate(json['createdAt']),
  );
}

class NetworkScanRecord {
  final String id;
  final String networkId;
  final String status;
  final int? probed;
  final int? total;
  final int? devices;
  final int? newDevices;

  /// Null for PARTIAL scans: an incomplete scan can't say what's missing.
  final int? notSeen;
  final int? openPorts;
  final int changeCount;
  final String? error;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const NetworkScanRecord({
    required this.id,
    required this.networkId,
    required this.status,
    this.probed,
    this.total,
    this.devices,
    this.newDevices,
    this.notSeen,
    this.openPorts,
    this.changeCount = 0,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  bool get isRunning => status == 'RUNNING';

  factory NetworkScanRecord.fromJson(Json json) {
    final progress = json['progress'] is Map ? json['progress'] as Map : const {};
    final summary = json['summary'] is Map ? json['summary'] as Map : const {};
    return NetworkScanRecord(
      id: json['id'] as String,
      networkId: json['networkId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      probed: progress['probed'] as int?,
      total: progress['total'] as int?,
      devices: summary['devices'] as int?,
      newDevices: summary['newDevices'] as int?,
      notSeen: summary['notSeen'] as int?,
      openPorts: summary['openPorts'] as int?,
      changeCount: json['changeCount'] as int? ?? 0,
      error: json['error'] as String?,
      startedAt: parseDate(json['startedAt']),
      completedAt: parseDate(json['completedAt']),
    );
  }
}

class NetworkPort {
  final int port;
  final String protocol;
  final String state;
  final String? service;

  const NetworkPort({required this.port, required this.protocol, required this.state, this.service});

  bool get isOpen => state == 'open';

  factory NetworkPort.fromJson(Json json) => NetworkPort(
    port: json['port'] as int,
    protocol: json['protocol'] as String? ?? 'tcp',
    state: json['state'] as String? ?? 'unknown',
    service: json['service'] as String?,
  );
}

/// What one scan saw at one address.
class NetworkObservation {
  final String deviceId;
  final String? identity;
  final String ipAddress;
  final String? hostname;
  final String? macAddress;
  final String? discoveryMethod;
  final DateTime? observedAt;
  final String? scanId;
  final String? scanStatus;
  final List<NetworkPort> ports;

  const NetworkObservation({
    required this.deviceId,
    required this.ipAddress,
    this.identity,
    this.hostname,
    this.macAddress,
    this.discoveryMethod,
    this.observedAt,
    this.scanId,
    this.scanStatus,
    this.ports = const [],
  });

  factory NetworkObservation.fromJson(Json json) => NetworkObservation(
    deviceId: json['deviceId'] as String? ?? '',
    identity: json['identity'] as String?,
    ipAddress: json['ipAddress'] as String? ?? '',
    hostname: json['hostname'] as String?,
    macAddress: json['macAddress'] as String?,
    discoveryMethod: json['discoveryMethod'] as String?,
    observedAt: parseDate(json['observedAt']),
    scanId: json['scanId'] as String?,
    scanStatus: json['scanStatus'] as String?,
    // Scan devices send `ports`; device history sends only `openPorts`.
    ports: ((json['ports'] ?? json['openPorts']) as List<dynamic>? ?? const [])
        .map((e) => NetworkPort.fromJson(e as Json))
        .toList(),
  );
}

class NetworkDevice {
  final String id;
  final String networkId;

  /// `mac` (stable) or `ip` (identified by address only).
  final String identity;
  final String? ipAddress;
  final String? hostname;
  final String? macAddress;
  final String? vendor;
  final String? discoveryMethod;

  /// `seen` / `not_seen` in the latest completed scan; null before the first one.
  final String? lastStatus;
  final int openPorts;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;

  const NetworkDevice({
    required this.id,
    required this.networkId,
    required this.identity,
    this.ipAddress,
    this.hostname,
    this.macAddress,
    this.vendor,
    this.discoveryMethod,
    this.lastStatus,
    this.openPorts = 0,
    this.firstSeenAt,
    this.lastSeenAt,
  });

  bool get identifiedByAddressOnly => identity == 'ip';

  factory NetworkDevice.fromJson(Json json) => NetworkDevice(
    id: json['id'] as String,
    networkId: json['networkId'] as String? ?? '',
    identity: json['identity'] as String? ?? 'ip',
    ipAddress: json['ipAddress'] as String?,
    hostname: json['hostname'] as String?,
    macAddress: json['macAddress'] as String?,
    vendor: json['vendor'] as String?,
    discoveryMethod: json['discoveryMethod'] as String?,
    lastStatus: json['lastStatus'] as String?,
    openPorts: json['openPorts'] as int? ?? 0,
    firstSeenAt: parseDate(json['firstSeenAt']),
    lastSeenAt: parseDate(json['lastSeenAt']),
  );
}

class NetworkChange {
  final String id;
  final String scanId;
  final String? deviceId;
  final String type;
  final Severity? severity;
  final dynamic before;
  final dynamic after;
  final DateTime? createdAt;

  const NetworkChange({
    required this.id,
    required this.scanId,
    required this.type,
    this.deviceId,
    this.severity,
    this.before,
    this.after,
    this.createdAt,
  });

  factory NetworkChange.fromJson(Json json) => NetworkChange(
    id: json['id'] as String,
    scanId: json['scanId'] as String? ?? '',
    deviceId: json['deviceId'] as String?,
    type: json['type'] as String? ?? '',
    severity: Severity.tryParse(json['severity']),
    before: json['before'],
    after: json['after'],
    createdAt: parseDate(json['createdAt']),
  );
}
