import 'package:flutter_test/flutter_test.dart';
import 'package:reconex/data/services/camera_fingerprint.dart';
import 'package:reconex/data/services/hotspot_match.dart';

void main() {
  const wpa = '[WPA2-PSK-CCMP][RSN-PSK-CCMP][ESS]';
  const open = '[ESS]';

  group('matchCameraSsid', () {
    test('known camera hotspot names match', () {
      for (final ssid in [
        'HDWiFiCam-8A3F',
        'IPC_1234',
        'IPC-HFW1230',
        'Cam-0042',
        'CAM_88',
        'WiFi Cam 01',
        'MiniCam_7',
        'Spy-Cam',
        'HD-CAM-55',
        'A9_12ab',
        'IPCAM-xyz',
        'Hikvision-Lobby',
        'HIK_00',
        'DAHUA_123',
        'EZVIZ_C6N',
        'Wyze_Cam',
        'YI_8899',
        'Reolink_E1',
        'V380-123456',
        'XM_ab12',
        'XMEYE-1',
        'Tuya_Camera',
        'SmartLife-4F2A',
      ]) {
        expect(matchCameraSsid(ssid), isNotNull, reason: ssid);
      }
    });

    test('ordinary networks do not match', () {
      for (final ssid in [
        'Camden Office',
        'TP-Link_5G',
        'Pixel_7',
        'Starbucks',
        'Campus WiFi',
        'Spyglass Cafe',
        'Hikers Lodge',
        'DIRECT-xy-HP LaserJet',
        'Yield_Guest',
        '',
      ]) {
        expect(matchCameraSsid(ssid), isNull, reason: ssid);
      }
    });

    test('matching is case-insensitive', () {
      expect(matchCameraSsid('hdwificam-1'), isNotNull);
      expect(matchCameraSsid('ipcam'), isNotNull);
    });

    test('dedicated camera names are likely, generic ones possible', () {
      expect(matchCameraSsid('HDWiFiCam-1')!.likelihood, CameraLikelihood.likely);
      expect(matchCameraSsid('Reolink_E1', capabilities: wpa)!.likelihood, CameraLikelihood.possible);
    });

    test('open network upgrades a camera-like name', () {
      final v = matchCameraSsid('Reolink_E1', capabilities: open)!;
      expect(v.likelihood, CameraLikelihood.likely);
      expect(v.reason, contains('open'));
    });

    test('open Tuya setup hotspot stays possible', () {
      expect(matchCameraSsid('SmartLife-4F2A', capabilities: open)!.likelihood, CameraLikelihood.possible);
    });
  });
}
