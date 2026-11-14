import 'package:reconex/data/services/camera_fingerprint.dart';

/// Why a nearby Wi-Fi name looks like a camera's own hotspot.
class HotspotVerdict {
  final CameraLikelihood likelihood;
  final String reason;

  const HotspotVerdict(this.likelihood, this.reason);
}

class _Pattern {
  final RegExp re;
  final String reason;
  final bool likely;

  /// Open setup hotspots are normal for this kind, so "open" adds nothing.
  final bool openIsNormal;

  _Pattern(String pattern, this.reason, {this.likely = false, this.openIsNormal = false})
    : re = RegExp(pattern, caseSensitive: false);
}

// Tokens must start the name or follow a separator, and can't run into more letters
// ("Cam-01" matches, "Camden" doesn't).
const _pre = r'(?:^|[^a-z0-9])';
const _post = r'(?![a-z])';

final List<_Pattern> _patterns = [
  _Pattern('${_pre}hd[ _-]?wi[ _-]?fi[ _-]?cam$_post', 'Spy-camera hotspot name', likely: true),
  _Pattern('${_pre}wi[ _-]?fi[ _-]?cam$_post', 'Wi-Fi camera hotspot name', likely: true),
  _Pattern('${_pre}mini[ _-]?cam$_post', 'Mini-camera hotspot name', likely: true),
  _Pattern('${_pre}hd[ _-]?cam$_post', 'HD camera hotspot name', likely: true),
  _Pattern('${_pre}ip[ _-]?cam$_post', 'IP camera hotspot name', likely: true),
  _Pattern('${_pre}spy$_post', 'Name says "spy"', likely: true),
  _Pattern('${_pre}v380$_post', 'V380 camera app hotspot', likely: true),
  _Pattern('${_pre}xm[ _-]?eye$_post', 'XMEye camera hotspot', likely: true),
  _Pattern('^a9[_-]', 'A9 mini-camera hotspot', likely: true),
  _Pattern('^ipc[_-]', 'IP camera (IPC) hotspot'),
  _Pattern('${_pre}cam(?:[ _-]|\\d|\$)', 'Camera-style name'),
  _Pattern('${_pre}hikvision|^hik[_-]', 'Hikvision camera brand'),
  _Pattern('${_pre}dahua$_post', 'Dahua camera brand'),
  _Pattern('${_pre}ezviz$_post', 'EZVIZ camera brand'),
  _Pattern('${_pre}wyze$_post', 'Wyze camera brand'),
  _Pattern('${_pre}reolink$_post', 'Reolink camera brand'),
  _Pattern('^yi[_-]', 'YI camera hotspot'),
  _Pattern('^xm[_-]', 'XiongMai camera hotspot'),
  _Pattern(
    '${_pre}tuya$_post|^smart ?life[_-]',
    'Tuya setup hotspot (camera or other smart device)',
    openIsNormal: true,
  ),
];

/// Matches a nearby Wi-Fi name against known camera hotspot patterns. Null when it doesn't look like one.
///
/// [capabilities] is the Android security string (e.g. `[WPA2-PSK-CCMP][ESS]`); an open
/// network with a camera-like name is rated higher, since cheap cameras ship open.
HotspotVerdict? matchCameraSsid(String ssid, {String capabilities = ''}) {
  final name = ssid.trim();
  if (name.isEmpty) return null;
  for (final p in _patterns) {
    if (!p.re.hasMatch(name)) continue;
    final open = capabilities.isNotEmpty && !RegExp('WPA|WEP|RSN|SAE', caseSensitive: false).hasMatch(capabilities);
    if (open && !p.openIsNormal) return HotspotVerdict(CameraLikelihood.likely, '${p.reason} · open network');
    return HotspotVerdict(p.likely ? CameraLikelihood.likely : CameraLikelihood.possible, p.reason);
  }
  return null;
}
