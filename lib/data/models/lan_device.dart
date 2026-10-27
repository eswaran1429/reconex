/// The Wi-Fi the phone is on right now. Unknown fields stay null.
class LanSelf {
  final String? ssid;
  final String? ipAddress;
  final String? gatewayIp;

  /// First three octets, e.g. `192.168.1`. Null when not on Wi-Fi.
  final String? subnet;

  const LanSelf({this.ssid, this.ipAddress, this.gatewayIp, this.subnet});

  bool get onWifi => subnet != null;

  String get subnetLabel => subnet == null ? 'Unknown' : '$subnet.0/24';
}

/// A device seen on the current Wi-Fi. Values come only from the scan; nothing is guessed.
class LanDevice {
  final String ip;
  final String? mac;
  final String? vendor;
  final String? hostname;
  final bool isGateway;
  final bool isSelf;

  /// Open TCP ports, filled only after an on-demand port check. Null = not checked.
  final List<int>? openPorts;

  const LanDevice({
    required this.ip,
    this.mac,
    this.vendor,
    this.hostname,
    this.isGateway = false,
    this.isSelf = false,
    this.openPorts,
  });

  /// Numeric value of the last octet, for sorting.
  int get hostId => int.tryParse(ip.split('.').last) ?? 0;

  String get displayName {
    if (hostname != null && hostname!.isNotEmpty) return hostname!;
    if (vendor != null && vendor!.isNotEmpty) return vendor!;
    return ip;
  }

  LanDevice copyWith({String? mac, String? vendor, String? hostname, List<int>? openPorts}) => LanDevice(
    ip: ip,
    mac: mac ?? this.mac,
    vendor: vendor ?? this.vendor,
    hostname: hostname ?? this.hostname,
    isGateway: isGateway,
    isSelf: isSelf,
    openPorts: openPorts ?? this.openPorts,
  );
}
