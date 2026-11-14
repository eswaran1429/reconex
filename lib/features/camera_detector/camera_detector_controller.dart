import 'dart:async';

import 'package:get/get.dart';
import 'package:reconex/data/models/lan_device.dart';
import 'package:reconex/data/services/camera_fingerprint.dart';
import 'package:reconex/data/services/hotspot_match.dart';
import 'package:reconex/data/services/hotspot_scan_service.dart';
import 'package:reconex/data/services/lan_scan_service.dart';
import 'package:reconex/routes/app_routes.dart';

/// A device on the current Wi-Fi with everything the camera scan observed.
class CameraSuspect {
  final LanDevice device;
  final Set<int> openPorts;
  final String? httpBanner;
  final CameraVerdict verdict;

  const CameraSuspect({required this.device, required this.openPorts, this.httpBanner, required this.verdict});
}

/// A nearby Wi-Fi access point whose name looks like a camera's own hotspot.
class CameraHotspot {
  final String ssid;
  final String bssid;

  /// Signal in dBm; closer to 0 means closer to the phone.
  final int level;
  final HotspotVerdict verdict;

  const CameraHotspot({required this.ssid, required this.bssid, required this.level, required this.verdict});
}

/// Scans the current Wi-Fi for devices that look like network cameras.
///
/// Discovery, ONVIF and mDNS run in parallel; each found host then gets a
/// camera-port check and an HTTP banner read, a few hosts at a time.
class CameraDetectorController extends GetxController {
  final LanScanService _lan = Get.find();
  final HotspotScanService _hotspotScan = Get.find();

  static const int _maxParallel = 6;
  static final List<int> _ports = cameraPortNames.keys.toList();

  final Rxn<LanSelf> self = Rxn<LanSelf>();
  final RxList<CameraSuspect> suspects = <CameraSuspect>[].obs;
  final RxBool isScanning = false.obs;
  final RxInt hostsFound = 0.obs;
  final RxInt hostsChecked = 0.obs;
  final RxnString error = RxnString();

  /// Nearby camera-like hotspots, strongest signal first.
  final RxList<CameraHotspot> hotspots = <CameraHotspot>[].obs;
  final RxBool hotspotsScanning = false.obs;

  /// Why nearby hotspots couldn't be listed, if they couldn't.
  final RxnString hotspotNote = RxnString();

  /// Bumped on each scan so results from a cancelled scan are dropped.
  int _run = 0;
  StreamSubscription<LanDevice>? _sub;
  Completer<void>? _discovery;
  final List<LanDevice> _queue = [];
  final Set<String> _seen = {};
  int _active = 0;
  bool _discoveryDone = false;
  final Map<String, String?> _onvif = {};
  final Map<String, Set<String>> _mdns = {};
  final Map<String, CameraSuspect> _byIp = {};

  @override
  void onInit() {
    super.onInit();
    scan();
  }

  @override
  void onClose() {
    _run++;
    _cancelDiscovery();
    super.onClose();
  }

  /// Cancelling a subscription doesn't fire onDone, so complete the waiter here.
  void _cancelDiscovery() {
    _sub?.cancel();
    _sub = null;
    final d = _discovery;
    if (d != null && !d.isCompleted) d.complete();
  }

  Future<void> scan() async {
    final run = ++_run;
    _cancelDiscovery();
    _queue.clear();
    _seen.clear();
    _active = 0;
    _discoveryDone = false;
    _onvif.clear();
    _mdns.clear();
    _byIp.clear();
    suspects.clear();
    hostsFound.value = 0;
    hostsChecked.value = 0;
    error.value = null;
    hotspots.clear();
    hotspotNote.value = null;
    isScanning.value = true;

    try {
      await _lan.requestWifiNamePermission();
      if (run != _run) return;
      // Started after the permission prompt, which can't overlap another; runs alongside the LAN scan.
      unawaited(_scanHotspots(run));
      final net = await _lan.currentNetwork();
      if (run != _run) return;
      self.value = net;
      if (!net.onWifi) {
        error.value = 'Connect to the Wi-Fi you want to check, then scan again.';
        isScanning.value = false;
        return;
      }

      // Multicast lookups run alongside discovery; their hits rescore devices as they land.
      final lookups = _lan.withMulticastLock(
        () => Future.wait<void>([
          _lan.onvifProbe().then((hits) {
            if (run == _run) _onvif.addAll(hits);
          }),
          _lan.mdnsLookup(cameraMdnsServices).then((hits) {
            if (run == _run) _mdns.addAll(hits);
          }),
        ]).catchError((_) => <void>[]),
      );

      final discovery = _discovery = Completer<void>();
      _sub = _lan
          .discover(net)
          .listen(
            (device) {
              if (run != _run || device.isSelf || !_seen.add(device.ip)) return;
              hostsFound.value++;
              _queue.add(device);
              _pump(run);
            },
            onDone: discovery.complete,
            onError: (Object e) {
              if (!discovery.isCompleted) discovery.completeError(e);
            },
          );

      await discovery.future;
      await lookups;
      if (run != _run) return;
      _discoveryDone = true;
      _addMulticastOnly(run);
      _rescoreAll();
      _finishIfIdle(run);
    } catch (e) {
      if (run != _run) return;
      error.value = e.toString();
      isScanning.value = false;
    }
  }

  /// Never throws: a failed hotspot scan only sets [hotspotNote].
  Future<void> _scanHotspots(int run) async {
    hotspotsScanning.value = true;
    try {
      final result = await _hotspotScan.scan();
      if (run != _run) return;
      hotspotNote.value = result.note;
      final byBssid = <String, CameraHotspot>{};
      for (final ap in result.accessPoints) {
        final verdict = matchCameraSsid(ap.ssid, capabilities: ap.capabilities);
        if (verdict == null) continue;
        byBssid[ap.bssid] = CameraHotspot(ssid: ap.ssid, bssid: ap.bssid, level: ap.level, verdict: verdict);
      }
      hotspots.assignAll(byBssid.values.toList()..sort((a, b) => b.level.compareTo(a.level)));
    } catch (_) {
      if (run == _run) hotspotNote.value = 'Couldn\'t list nearby Wi-Fi hotspots.';
    } finally {
      if (run == _run) hotspotsScanning.value = false;
    }
  }

  void _pump(int run) {
    while (_active < _maxParallel && _queue.isNotEmpty) {
      final device = _queue.removeAt(0);
      _active++;
      _probe(device, run).whenComplete(() {
        if (run != _run) return;
        _active--;
        hostsChecked.value++;
        _pump(run);
        _finishIfIdle(run);
      });
    }
  }

  Future<void> _probe(LanDevice device, int run) async {
    Set<int> ports;
    try {
      ports = (await _lan.scanPorts(device.ip, ports: _ports, timeout: const Duration(milliseconds: 1500))).toSet();
    } catch (_) {
      // A failed port check still leaves vendor/ONVIF/mDNS signals to score.
      ports = {};
    }
    String? banner;
    for (final port in const [80, 8080]) {
      if (!ports.contains(port)) continue;
      banner = await _lan.httpBanner(device.ip, port);
      if (banner != null) break;
    }
    if (run != _run) return;
    _put(device.copyWith(openPorts: ports.toList()..sort()), ports, banner);
  }

  /// Devices that answered ONVIF/mDNS but never answered ping still deserve a row.
  void _addMulticastOnly(int run) {
    final subnet = self.value?.subnet;
    for (final ip in {..._onvif.keys, ..._mdns.keys}) {
      // mDNS can return 0.0.0.0 on a failed lookup, or IPv6; only real hosts in this /24 count.
      if (subnet == null || !ip.startsWith('$subnet.') || ip == self.value?.ipAddress || !_seen.add(ip)) continue;
      hostsFound.value++;
      _queue.add(LanDevice(ip: ip, isGateway: ip == self.value?.gatewayIp));
    }
    _pump(run);
  }

  void _put(LanDevice device, Set<int> ports, String? banner) {
    _byIp[device.ip] = CameraSuspect(
      device: device,
      openPorts: ports,
      httpBanner: banner,
      verdict: _score(device, ports, banner),
    );
    _publish();
  }

  void _rescoreAll() {
    for (final entry in _byIp.entries.toList()) {
      final s = entry.value;
      _byIp[entry.key] = CameraSuspect(
        device: s.device,
        openPorts: s.openPorts,
        httpBanner: s.httpBanner,
        verdict: _score(s.device, s.openPorts, s.httpBanner),
      );
    }
    _publish();
  }

  CameraVerdict _score(LanDevice device, Set<int> ports, String? banner) => scoreCamera(
    device,
    openPorts: ports,
    onvifReply: _onvif.containsKey(device.ip),
    onvifName: _onvif[device.ip],
    mdnsServices: _mdns[device.ip] ?? const {},
    httpBanner: banner,
  );

  void _publish() {
    final list = _byIp.values.toList()
      ..sort((a, b) {
        final byScore = b.verdict.score.compareTo(a.verdict.score);
        return byScore != 0 ? byScore : a.device.hostId.compareTo(b.device.hostId);
      });
    suspects.assignAll(list);
  }

  void _finishIfIdle(int run) {
    if (run == _run && _discoveryDone && _queue.isEmpty && _active == 0) isScanning.value = false;
  }

  int countOf(CameraLikelihood l) => suspects.where((s) => s.verdict.likelihood == l).length;

  void openDevice(CameraSuspect s) => Get.toNamed(AppRoutes.lanDevice, arguments: s.device);
}
