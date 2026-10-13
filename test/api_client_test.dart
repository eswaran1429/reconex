import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/network/api_exception.dart';
import 'package:reconex/core/storage/token_storage.dart';
import 'package:reconex/data/services/alert_service.dart';
import 'package:reconex/data/services/auth_service.dart';

/// Returns a canned response and records the last request.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.status, this.body);

  final int status;
  final Object body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage tokenStorage;
  late FakeAdapter adapter;

  ApiClient client(int status, Object body, {Future<void> Function()? onUnauthorized}) {
    adapter = FakeAdapter(status, body);
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter;
    return ApiClient(tokenStorage, dio: dio, onUnauthorized: onUnauthorized);
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    tokenStorage = TokenStorage();
  });

  test('unwraps data from success response', () async {
    final api = client(200, {
      'success': true,
      'message': 'ok',
      'data': [1, 2],
    });
    expect(await api.get('/domain/get'), [1, 2]);
  });

  test('throws ApiException with server message on error status', () async {
    final api = client(409, {'success': false, 'message': 'Domain already exists'});
    await expectLater(
      api.post('/domain/add'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Domain already exists')),
    );
  });

  test('sends bearer token when stored, none otherwise', () async {
    var api = client(200, {'success': true, 'data': null});
    await api.get('/x');
    expect(adapter.lastRequest!.headers.containsKey('Authorization'), isFalse);

    await tokenStorage.save('abc');
    api = client(200, {'success': true, 'data': null});
    await api.get('/x');
    expect(adapter.lastRequest!.headers['Authorization'], 'Bearer abc');
  });

  test('401 with token clears it and calls onUnauthorized', () async {
    await tokenStorage.save('abc');
    var called = false;
    final api = client(
      401,
      {'success': false, 'message': 'Token revoked, please log in again'},
      onUnauthorized: () async {
        called = true;
      },
    );

    await expectLater(api.get('/domain/get'), throwsA(isA<ApiException>()));
    expect(called, isTrue);
    expect(await tokenStorage.read(), isNull);
  });

  test('paginated query drops nulls and joins severity', () async {
    final api = client(200, {
      'success': true,
      'data': {
        'items': [],
        'pagination': {'page': 2, 'limit': 50, 'total': 60, 'totalPages': 2},
      },
    });
    final page = await AlertService(api).list(page: 2, severity: ['high', 'critical']);

    expect(adapter.lastRequest!.queryParameters, {'page': 2, 'severity': 'high,critical'});
    expect(page.totalPages, 2);
  });

  test('login stores returned token', () async {
    final api = client(200, {
      'success': true,
      'data': {'id': 'user_1', 'name': 'Ann', 'email': 'a@b.co', 'token': 'tok', 'createdAt': '2026-10-01T00:00:00Z'},
    });
    final user = await AuthService(api, tokenStorage).login(email: 'a@b.co', password: 'password1');

    expect(user.id, 'user_1');
    expect(await tokenStorage.read(), 'tok');
  });
}
