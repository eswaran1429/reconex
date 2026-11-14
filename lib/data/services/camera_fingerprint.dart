import 'package:reconex/data/models/lan_device.dart';

/// How strongly the signals point to a camera.
enum CameraLikelihood { likely, possible, unlikely }

/// One observed signal and how much it counted.
class CameraSignal {
  final String reason;
  final int weight;

  const CameraSignal(this.reason, this.weight);
}

/// Result of scoring one device. Score is 0–100; [signals] explain it.
class CameraVerdict {
  final int score;
  final CameraLikelihood likelihood;
  final List<CameraSignal> signals;

  const CameraVerdict({required this.score, required this.likelihood, required this.signals});

  static const CameraVerdict none = CameraVerdict(score: 0, likelihood: CameraLikelihood.unlikely, signals: []);
}

/// Ports checked by the camera scan, with what they usually mean.
const Map<int, String> cameraPortNames = {
  80: 'HTTP',
  554: 'RTSP',
  1935: 'RTMP',
  6668: 'Tuya',
  8000: 'Hikvision SDK',
  8080: 'HTTP alt',
  8554: 'RTSP alt',
  8899: 'ONVIF',
  34567: 'XMeye',
  37777: 'Dahua',
};

/// Ports that, when open, point to a video device. Weight per port.
const Map<int, int> _cameraPortWeights = {
  554: 35,
  8554: 35,
  37777: 35,
  34567: 35,
  8899: 20,
  8000: 15,
  1935: 10,
  6668: 10,
};

/// Manufacturers that mainly make cameras, matched against the MAC-vendor name.
const List<String> _cameraVendors = [
  'hikvision',
  'dahua',
  'uniview',
  'reolink',
  'wyze',
  'foscam',
  'amcrest',
  'axis communications',
  'ezviz',
  'hanwha',
  'vivotek',
  'mobotix',
  'arlo',
  'xiongmai',
  'anyka',
  'ingenic',
  'geovision',
  'ring llc',
];

/// Chip vendors common in cheap cameras, but also in plugs and bulbs.
const List<String> _weakVendors = ['espressif', 'tuya'];

/// Words in a page title, Server header or auth realm that name a camera system.
const List<String> _bannerKeywords = [
  'ip camera',
  'ipcam',
  'network camera',
  'webcam',
  'web camera',
  'dvr',
  'nvr',
  'netsurveillance',
  'xmeye',
  'hikvision',
  'dahua',
  'reolink',
  'amcrest',
  'foscam',
  'onvif',
  'live view',
];

/// Hostname fragments that suggest a camera.
const List<String> _hostnameKeywords = ['cam', 'ipc', 'dvr', 'nvr', 'wyze', 'reolink', 'hikvision', 'dahua'];

/// mDNS service types advertised by video devices.
const List<String> cameraMdnsServices = ['_rtsp._tcp', '_onvif._tcp'];

String? _firstMatch(String? text, List<String> words) {
  if (text == null || text.isEmpty) return null;
  final lower = text.toLowerCase();
  for (final w in words) {
    if (lower.contains(w)) return w;
  }
  return null;
}

/// Scores a device from what the scan saw. Pure: no I/O.
///
/// "Likely" needs a score of 60+ and either two independent signals or an
/// ONVIF reply, so a vendor name alone never decides.
CameraVerdict scoreCamera(
  LanDevice device, {
  Set<int> openPorts = const {},
  bool onvifReply = false,
  String? onvifName,
  Set<String> mdnsServices = const {},
  String? httpBanner,
}) {
  if (device.isSelf) return CameraVerdict.none;

  final signals = <CameraSignal>[];

  if (onvifReply) {
    signals.add(CameraSignal(onvifName == null ? 'Answered ONVIF camera discovery' : 'ONVIF camera: $onvifName', 60));
  }

  for (final service in mdnsServices) {
    if (cameraMdnsServices.contains(service)) {
      signals.add(CameraSignal('Advertises $service', 40));
    }
  }

  final vendor = device.vendor;
  final strongVendor = _firstMatch(vendor, _cameraVendors);
  if (strongVendor != null) {
    signals.add(CameraSignal('Camera maker: $vendor', 40));
  } else if (_firstMatch(vendor, _weakVendors) != null) {
    signals.add(CameraSignal('Chip used in cheap cameras: $vendor', 15));
  }

  final ports = openPorts.toList()..sort();
  for (final port in ports) {
    final weight = _cameraPortWeights[port];
    if (weight != null) {
      signals.add(CameraSignal('Port $port open (${cameraPortNames[port]})', weight));
    }
  }

  final bannerWord = _firstMatch(httpBanner, _bannerKeywords);
  if (bannerWord != null) {
    signals.add(CameraSignal('Web page mentions "$bannerWord"', 35));
  }

  final hostWord = _firstMatch(device.hostname, _hostnameKeywords);
  if (hostWord != null) {
    signals.add(CameraSignal('Hostname contains "$hostWord"', 25));
  }

  final raw = signals.fold<int>(0, (sum, s) => sum + s.weight);
  final score = raw > 100 ? 100 : raw;

  final CameraLikelihood likelihood;
  if (score >= 60 && (signals.length >= 2 || onvifReply)) {
    likelihood = CameraLikelihood.likely;
  } else if (score >= 25) {
    likelihood = CameraLikelihood.possible;
  } else {
    likelihood = CameraLikelihood.unlikely;
  }

  return CameraVerdict(score: score, likelihood: likelihood, signals: signals);
}
