// Renders each screen against canned API data. Fails on layout errors (overflow etc).
// Set SCREENSHOT_DIR to also save a PNG per screen.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/storage/token_storage.dart';
import 'package:reconex/data/services/alert_service.dart';
import 'package:reconex/data/services/auth_service.dart';
import 'package:reconex/data/services/change_service.dart';
import 'package:reconex/data/services/domain_service.dart';
import 'package:reconex/data/services/port_service.dart';
import 'package:reconex/data/services/scan_service.dart';
import 'package:reconex/data/services/subdomain_service.dart';
import 'package:reconex/data/services/technology_service.dart';
import 'package:reconex/features/changes/changes_controller.dart';
import 'package:reconex/features/security/security_controller.dart';
import 'package:reconex/main.dart';
import 'package:reconex/routes/app_routes.dart';

const _now = '2026-10-07T09:30:00Z';

Map<String, dynamic> _page(List<Object> items) => {
  'items': items,
  'pagination': {'page': 1, 'limit': 50, 'total': items.length, 'totalPages': 1},
};

final _change = {
  'id': 'change_1',
  'domainId': 'domain_1',
  'scanId': 'scan_2',
  'category': 'ports',
  'type': 'port_opened',
  'key': 'www.example.com:6379/tcp',
  'severity': 'critical',
  'before': null,
  'after': {'host': 'www.example.com', 'port': 6379, 'protocol': 'tcp', 'service': 'redis'},
  'createdAt': _now,
  'scan': {'id': 'scan_2', 'status': 'COMPLETED', 'createdAt': _now, 'completedAt': _now},
};

final _scan = {
  'id': 'scan_2',
  'domainId': 'domain_1',
  'status': 'PARTIAL',
  'trigger': 'manual',
  'changeCount': 3,
  'error': null,
  'startedAt': '2026-10-07T09:28:00Z',
  'completedAt': _now,
  'createdAt': '2026-10-07T09:28:00Z',
  'steps': {
    'dns': {
      'status': 'completed',
      'startedAt': '2026-10-07T09:28:00Z',
      'completedAt': '2026-10-07T09:28:02Z',
      'counts': {'records': 9},
    },
    'subdomains': {
      'status': 'completed',
      'counts': {'found': 4},
    },
    'ports': {
      'status': 'completed',
      'counts': {'open': 5},
    },
    'ssl': {
      'status': 'failed',
      'error': 'connect ETIMEDOUT',
      'unreachable': ['dev.example.com'],
    },
    'technologies': {'status': 'completed'},
    'headers': {'status': 'completed'},
    'exposed_resources': {'status': 'completed'},
  },
};

Object? _respond(String path) {
  if (path == '/domain/get') {
    return [
      {'id': 'domain_1', 'name': 'Example', 'url': 'https://example.com', 'status': 'ACTIVE', 'createdAt': _now},
      {'id': 'domain_2', 'name': 'Staging portal', 'url': 'https://staging.example.org', 'status': 'INACTIVE'},
    ];
  }
  if (path.startsWith('/domain/dashboard/')) {
    return {
      'domain': {
        'id': 'domain_1',
        'name': 'Example',
        'url': 'https://example.com',
        'status': 'ACTIVE',
        'createdAt': _now,
      },
      'lastScanAt': '2026-10-07T07:30:00Z',
      'lastScan': {'id': 'scan_2', 'status': 'COMPLETED', 'changeCount': 3, 'startedAt': _now, 'completedAt': _now},
      'subdomains': {
        'total': 4,
        'byStatus': {'ACTIVE': 4},
      },
      'ports': {
        'open': 7,
        'byPort': {'443/https': 3},
      },
      'dns': {
        'total': 9,
        'byType': {'A': 2, 'MX': 5},
      },
      'technologies': {
        'total': 3,
        'items': [
          {
            'name': 'Nginx',
            'category': 'web_server',
            'versions': ['1.25.3'],
            'subdomains': 3,
          },
          {'name': 'Cloudflare', 'category': 'cdn', 'versions': [], 'subdomains': 4},
          {
            'name': 'Next.js',
            'category': 'framework',
            'versions': ['14.1'],
            'subdomains': ['www.example.com'],
          },
        ],
      },
      'ssl': {
        'total': 4,
        'valid': 3,
        'invalid': 1,
        'expired': 0,
        'expiringSoon': [
          {'hostname': 'api.example.com', 'expiresAt': '2026-10-19T00:00:00Z'},
        ],
        'nextExpiry': {'hostname': 'api.example.com', 'expiresAt': '2026-10-19T00:00:00Z'},
      },
      'securityHeaders': {
        'scannedAt': _now,
        'checked': 7,
        'present': 4,
        'missing': ['a', 'b', 'c'],
        'bySeverity': {},
      },
      'exposedResources': {'scannedAt': null, 'checked': 0, 'accessible': [], 'bySeverity': {}},
      'alerts': {
        'total': 12,
        'lastSevenDays': 5,
        'bySeverity': {},
        'recent': [
          {
            'id': 'alert_1',
            'severity': 'critical',
            'title': 'Redis port opened',
            'message': 'Port 6379/tcp is now open on www.example.com.',
            'createdAt': _now,
          },
        ],
      },
      'recentChanges': [
        _change,
        {
          ..._change,
          'id': 'change_2',
          'type': 'subdomain_added',
          'category': 'subdomains',
          'key': 'api.example.com',
          'severity': 'medium',
        },
      ],
    };
  }
  if (path == '/alert/get') {
    return _page([
      {
        'id': 'alert_1',
        'domainId': 'domain_1',
        'domainName': 'Example',
        'type': 'port_opened',
        'severity': 'critical',
        'title': 'Redis port opened',
        'message': 'Port 6379/tcp (redis) is now open on www.example.com.',
        'createdAt': _now,
      },
      {
        'id': 'alert_2',
        'domainId': 'domain_1',
        'domainName': 'Example',
        'type': 'ssl_expiring',
        'severity': 'medium',
        'title': 'Certificate expiring soon',
        'message': 'api.example.com expires in 12 days.',
        'createdAt': '2026-10-05T09:30:00Z',
      },
    ]);
  }
  if (path.startsWith('/scan/get/')) return _scan;
  if (path.startsWith('/domain/scans/')) {
    return _page([
      _scan,
      {..._scan, 'id': 'scan_1', 'status': 'COMPLETED', 'changeCount': 0},
    ]);
  }
  if (path.startsWith('/domain/changes/')) {
    return _page([
      _change,
      {
        ..._change,
        'id': 'change_3',
        'category': 'headers',
        'type': 'header_removed',
        'key': 'content-security-policy',
        'severity': 'high',
      },
    ]);
  }
  if (path.startsWith('/change/get/')) return _change;
  if (path.startsWith('/subdomain/list/')) {
    return _page([
      {
        'id': 'subdomain_1',
        'domainId': 'domain_1',
        'hostname': 'www.example.com',
        'ipAddress': '93.184.216.34',
        'status': 'ACTIVE',
        'lastSeenAt': _now,
      },
      {
        'id': 'subdomain_2',
        'domainId': 'domain_1',
        'hostname': 'staging-internal-admin.example.com',
        'ipAddress': null,
        'status': 'INACTIVE',
        'lastSeenAt': _now,
      },
    ]);
  }
  if (path.startsWith('/subdomain/')) {
    return {
      'id': 'subdomain_1',
      'domainId': 'domain_1',
      'hostname': 'www.example.com',
      'ipAddress': '93.184.216.34',
      'status': 'ACTIVE',
      'firstSeenAt': _now,
      'lastSeenAt': _now,
    };
  }
  if (path.startsWith('/port/get/')) {
    return [
      {'port': 22, 'service': 'ssh', 'status': 'open'},
      {'port': 80, 'service': 'http', 'status': 'open'},
      {'port': 443, 'service': 'https', 'status': 'open'},
      {'port': 3306, 'service': 'mysql', 'status': 'closed'},
      {'port': 6379, 'service': 'redis', 'status': 'open'},
    ];
  }
  if (path.startsWith('/domain/dns/')) {
    return [
      {'type': 'A', 'name': 'example.com', 'value': '93.184.216.34', 'ttl': 300},
      {'type': 'MX', 'name': 'example.com', 'value': '10 mail.example.com', 'ttl': 3600},
      {'type': 'TXT', 'name': 'example.com', 'value': 'v=spf1 include:_spf.google.com ~all', 'ttl': 3600},
    ];
  }
  if (path.startsWith('/domain/history/')) {
    return _page([
      {
        'type': 'headers',
        'scannedAt': _now,
        'total': 3,
        'issues': 2,
        'results': [
          {
            'headerName': 'strict-transport-security',
            'present': true,
            'value': 'max-age=63072000; includeSubDomains',
            'severity': null,
          },
          {'headerName': 'content-security-policy', 'present': false, 'value': null, 'severity': 'high'},
          {'headerName': 'x-frame-options', 'present': false, 'value': null, 'severity': 'medium'},
        ],
      },
    ]);
  }
  return null;
}

class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = _respond(options.path);
    return ResponseBody.fromString(
      jsonEncode({'success': data != null, 'message': data == null ? 'Not found' : 'ok', 'data': data}),
      data == null ? 404 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final _shotDir = Platform.environment['SCREENSHOT_DIR'];
final _boundaryKey = GlobalKey();

Future<void> _loadFonts() async {
  final mono = FontLoader('JetBrainsMono')
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'));
  await mono.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final file = File('$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
    if (file.existsSync()) {
      final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
      await icons.load();
    }
  }
}

void _registerFakes() {
  final storage = Get.put(TokenStorage());
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = _FakeAdapter();
  final api = Get.put(ApiClient(storage, dio: dio));
  Get.put(AuthService(api, storage));
  Get.put(DomainService(api));
  Get.put(ScanService(api));
  Get.put(ChangeService(api));
  Get.put(AlertService(api));
  Get.put(SubdomainService(api));
  Get.put(PortService(api));
  Get.put(TechnologyService(api));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (_shotDir == null) return;
  await tester.runAsync(() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_shotDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(_loadFonts);
  tearDown(Get.reset);

  testWidgets('screens render with sample data', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});

    // Registered first, so InitialBinding's Get.put keeps these fakes. Token stored, so splash opens home.
    _registerFakes();
    await tester.pumpWidget(RepaintBoundary(key: _boundaryKey, child: const MyApp()));
    await tester.pump(const Duration(seconds: 3));
    await _settle(tester);
    expect(find.text('Example'), findsWidgets);
    await _shot(tester, '01_domains');

    Future<void> visit(String route, Object args, String name) async {
      Get.toNamed(route, arguments: args);
      await _settle(tester);
      await _shot(tester, name);
    }

    await tester.tap(find.text('Alerts').last);
    await _settle(tester);
    await _shot(tester, '02_alerts');

    await tester.tap(find.text('Account').last);
    await _settle(tester);
    await _shot(tester, '03_account');

    await visit(AppRoutes.domainDetail, 'domain_1', '04_domain_detail');
    for (final (label, name) in [
      ('Open ports', '04a_sheet_ports'),
      ('Technologies', '04b_sheet_technologies'),
      ('Valid SSL certs', '04c_sheet_ssl'),
      ('Alerts (7 days)', '04d_sheet_alerts'),
    ]) {
      await tester.tap(find.text(label));
      await _settle(tester);
      await _shot(tester, name);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await _settle(tester);
    }
    await tester.drag(find.byType(CustomScrollView).last, const Offset(0, -900));
    await _settle(tester);
    await _shot(tester, '05_domain_detail_scrolled');

    await visit(AppRoutes.scans, 'domain_1', '06_scans');
    await visit(AppRoutes.scanDetail, 'scan_2', '07_scan_detail');
    await visit(AppRoutes.changes, const ChangesArgs(domainId: 'domain_1'), '08_changes');
    await visit(AppRoutes.changeDetail, 'change_1', '09_change_detail');
    await visit(AppRoutes.subdomains, 'domain_1', '10_subdomains');
    await visit(AppRoutes.subdomainDetail, 'subdomain_1', '11_subdomain_detail');
    await visit(AppRoutes.dns, 'domain_1', '12_dns');
    await visit(AppRoutes.security, const SecurityArgs(domainId: 'domain_1'), '13_security');
  });
}
