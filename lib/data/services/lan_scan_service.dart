import 'package:network_info_plus/network_info_plus.dart';
import 'package:network_tools/network_tools.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reconex/data/models/lan_device.dart';

/// Discovers devices on the Wi-Fi the phone is currently connected to.
///
/// Everything runs on the phone: it reads the local Wi-Fi details, pings the
/// addresses in its own subnet, and reads the ARP table for MAC addresses. No
/// private address is sent to the backend, and no network is probed that the
/// phone isn't already on.
class LanScanService {
  final NetworkInfo _info = NetworkInfo();
  bool _configured = false;

  /// Common ports checked when the user opens a device. Observations, not a verdict.
  static const List<int> _commonPorts = [21, 22, 23, 53, 80, 139, 443, 445, 554, 1883, 3306, 5000, 8080, 8443, 9100];

  /// network_tools needs a writable directory for its MAC-vendor database.
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    final dir = await getApplicationSupportDirectory();
    await configureNetworkTools(dir.path, enableDebugging: false);
    _configured = true;
  }

  /// Asked before reading the Wi-Fi name; the scan itself works without it.
  Future<bool> requestWifiNamePermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Reads the current Wi-Fi. `subnet` is null when the phone isn't on Wi-Fi.
  Future<LanSelf> currentNetwork() async {
    final ip = await _info.getWifiIP();
    final gateway = await _tryGet(_info.getWifiGatewayIP);
    final ssid = _stripQuotes(await _tryGet(_info.getWifiName));
    final subnet = (ip != null && ip.contains('.')) ? ip.substring(0, ip.lastIndexOf('.')) : null;
    return LanSelf(ssid: ssid, ipAddress: ip, gatewayIp: gateway, subnet: subnet);
  }

  /// Streams devices as they answer. Each comes with whatever the scan could read.
  Stream<LanDevice> discover(LanSelf net) async* {
    if (net.subnet == null) return;
    await _ensureConfigured();

    final stream = HostScannerService.instance.getAllPingableDevices(net.subnet!, timeoutInSeconds: 2);
    await for (final host in stream) {
      final ip = host.address;
      yield LanDevice(
        ip: ip,
        mac: await _tryGet(() => host.getMacAddress()),
        vendor: (await _tryGet(() => host.vendor))?.vendorName,
        hostname: await _tryGet(() => host.hostName),
        isGateway: ip == net.gatewayIp,
        isSelf: ip == net.ipAddress,
      );
    }
  }

  /// On-demand TCP port check for one device.
  Future<List<int>> scanPorts(String ip) async {
    await _ensureConfigured();
    final open = <int>{};
    final stream = PortScannerService.instance.customDiscover(ip, portList: _commonPorts);
    await for (final host in stream) {
      for (final port in host.openPorts) {
        if (port.isOpen) open.add(port.port);
      }
    }
    final sorted = open.toList()..sort();
    return sorted;
  }

  static Future<T?> _tryGet<T>(Future<T?> Function() getter) async {
    try {
      return await getter();
    } catch (_) {
      return null;
    }
  }

  static String? _stripQuotes(String? value) {
    if (value == null || value.isEmpty || value == '<unknown ssid>') return null;
    return value.replaceAll('"', '');
  }
}
