import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

/// Nearby access points, or why they couldn't be listed.
class HotspotScanResult {
  final List<WiFiAccessPoint> accessPoints;

  /// Set when nothing could be read; [accessPoints] is then empty.
  final String? note;

  const HotspotScanResult(this.accessPoints, [this.note]);
}

/// Lists Wi-Fi access points the phone can hear, connected or not.
///
/// Read-only: it never joins or probes the networks it lists.
class HotspotScanService {
  final WiFiScan _wifi = WiFiScan.instance;

  Future<HotspotScanResult> scan() async {
    // wifi_scan checks fine location on every Android version; nearby-Wi-Fi is the 13+ permission
    // (a no-op below 13).
    final statuses = await [Permission.locationWhenInUse, Permission.nearbyWifiDevices].request();
    if (statuses[Permission.locationWhenInUse]?.isGranted != true) {
      return const HotspotScanResult([], 'Allow location access to list nearby Wi-Fi hotspots.');
    }

    final can = await _wifi.canGetScannedResults(askPermissions: false);
    switch (can) {
      case CanGetScannedResults.yes:
        break;
      case CanGetScannedResults.noLocationServiceDisabled:
        return const HotspotScanResult([], 'Turn on Location to list nearby Wi-Fi hotspots.');
      case CanGetScannedResults.notSupported:
        return const HotspotScanResult([], 'This phone can\'t list nearby Wi-Fi hotspots.');
      default:
        return const HotspotScanResult([], 'Allow precise location access to list nearby Wi-Fi hotspots.');
    }

    // Android allows ~4 scans per 2 minutes; when refused, the last cached results still work.
    if (await _wifi.canStartScan(askPermissions: false) == CanStartScan.yes) {
      try {
        // Subscribe before starting, so a fast result isn't missed.
        final done = _wifi.onScannedResultsAvailable.first.timeout(const Duration(seconds: 6));
        if (await _wifi.startScan()) {
          await done;
        } else {
          unawaited(done.catchError((_) => <WiFiAccessPoint>[]));
        }
      } catch (_) {
        // Timed out or refused: fall through to cached results.
      }
    }
    return HotspotScanResult(await _wifi.getScannedResults());
  }
}
