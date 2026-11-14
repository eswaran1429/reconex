import 'package:flutter_test/flutter_test.dart';
import 'package:reconex/data/models/lan_device.dart';
import 'package:reconex/data/services/camera_fingerprint.dart';
import 'package:reconex/data/services/lan_scan_service.dart';

void main() {
  const plain = LanDevice(ip: '192.168.1.20');

  group('scoreCamera', () {
    test('nothing observed is unlikely', () {
      final v = scoreCamera(plain);
      expect(v.score, 0);
      expect(v.likelihood, CameraLikelihood.unlikely);
      expect(v.signals, isEmpty);
    });

    test('this phone is never scored', () {
      const me = LanDevice(ip: '192.168.1.5', isSelf: true, vendor: 'Hangzhou Hikvision');
      expect(scoreCamera(me, openPorts: {554}).likelihood, CameraLikelihood.unlikely);
    });

    test('camera vendor alone is only possible', () {
      const d = LanDevice(ip: '192.168.1.30', vendor: 'Hangzhou Hikvision Digital Technology Co.,Ltd.');
      final v = scoreCamera(d);
      expect(v.likelihood, CameraLikelihood.possible);
      expect(v.signals.single.reason, contains('Hikvision'));
    });

    test('RTSP port alone is only possible', () {
      expect(scoreCamera(plain, openPorts: {554}).likelihood, CameraLikelihood.possible);
    });

    test('vendor plus RTSP is likely', () {
      const d = LanDevice(ip: '192.168.1.31', vendor: 'Zhejiang Dahua Technology');
      final v = scoreCamera(d, openPorts: {80, 554});
      expect(v.likelihood, CameraLikelihood.likely);
      expect(v.score, 75);
    });

    test('ONVIF reply alone is likely and names the device', () {
      final v = scoreCamera(plain, onvifReply: true, onvifName: 'IPC-2120');
      expect(v.likelihood, CameraLikelihood.likely);
      expect(v.signals.single.reason, contains('IPC-2120'));
    });

    test('score is capped at 100', () {
      const d = LanDevice(ip: '192.168.1.32', vendor: 'Reolink', hostname: 'reolink-cam');
      final v = scoreCamera(
        d,
        openPorts: {554, 8000},
        onvifReply: true,
        mdnsServices: {'_rtsp._tcp'},
        httpBanner: 'Reolink · IP Camera',
      );
      expect(v.score, 100);
    });

    test('printer on 9100 and web UI is not flagged', () {
      const d = LanDevice(ip: '192.168.1.40', vendor: 'HP Inc.', hostname: 'HPLaserJet');
      final v = scoreCamera(d, openPorts: {80, 443, 9100}, httpBanner: 'HP LaserJet MFP');
      expect(v.likelihood, CameraLikelihood.unlikely);
    });

    test('router admin page is not flagged', () {
      const d = LanDevice(ip: '192.168.1.1', isGateway: true, vendor: 'TP-LINK TECHNOLOGIES CO.,LTD.');
      final v = scoreCamera(d, openPorts: {53, 80, 443}, httpBanner: 'TP-Link Archer C6');
      expect(v.likelihood, CameraLikelihood.unlikely);
    });

    test('Espressif smart plug is unlikely', () {
      const d = LanDevice(ip: '192.168.1.50', vendor: 'Espressif Inc.');
      final v = scoreCamera(d, openPorts: {80});
      expect(v.likelihood, CameraLikelihood.unlikely);
      expect(v.score, 15);
    });

    test('cheap Espressif cam with web page and port is likely', () {
      const d = LanDevice(ip: '192.168.1.51', vendor: 'Espressif Inc.');
      final v = scoreCamera(d, openPorts: {80, 554}, httpBanner: 'ESP32 Webcam');
      expect(v.likelihood, CameraLikelihood.likely);
    });
  });

  group('LanScanService parsers', () {
    test('reads ONVIF name scope', () {
      const body =
          '<d:Scopes>onvif://www.onvif.org/type/video_encoder onvif://www.onvif.org/hardware/DS-2CD2143 '
          'onvif://www.onvif.org/name/Front%20Door</d:Scopes>';
      expect(LanScanService.parseOnvifName(body), 'Front Door');
    });

    test('falls back to hardware scope', () {
      const body = '<d:Scopes>onvif://www.onvif.org/hardware/IPC-HFW1230</d:Scopes>';
      expect(LanScanService.parseOnvifName(body), 'IPC-HFW1230');
    });

    test('ONVIF reply without scopes gives null', () {
      expect(LanScanService.parseOnvifName('<ProbeMatch/>'), isNull);
    });

    test('reads HTML title', () {
      expect(LanScanService.parseHtmlTitle('<html><TITLE> NetSurveillance WEB </TITLE>'), 'NetSurveillance WEB');
      expect(LanScanService.parseHtmlTitle('<title></title>'), isNull);
      expect(LanScanService.parseHtmlTitle('no title'), isNull);
    });
  });
}
