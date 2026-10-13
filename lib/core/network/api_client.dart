import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:reconex/core/network/api_exception.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/storage/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage, {Dio? dio, this.onUnauthorized})
    : _dio =
          dio ?? Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: _connectTimeout, receiveTimeout: _receiveTimeout)) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _attachToken, onError: _handleError));
    // Debug builds only, and not for an injected Dio (tests). Headers stay off so the bearer token isn't printed.
    if (kDebugMode && dio == null) {
      _dio.interceptors.add(PrettyDioLogger(requestBody: true, responseBody: true, error: true));
    }
  }

  static String get baseUrl => 'https://reconex-backend.onrender.com';

  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _receiveTimeout = Duration(seconds: 60);

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Future<void> Function()? onUnauthorized;

  Future<void> _attachToken(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.read();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  Future<void> _handleError(DioException e, ErrorInterceptorHandler handler) async {
    final sentToken = e.requestOptions.headers.containsKey('Authorization');
    if (e.response?.statusCode == 401 && sentToken) {
      await _tokenStorage.clear();
      await onUnauthorized?.call();
    }
    handler.next(e);
  }

  Future<dynamic> get(String path, {Json? query}) => _send(() => _dio.get(path, queryParameters: _clean(query)));

  Future<dynamic> post(String path, {Json? data}) => _send(() => _dio.post(path, data: data));

  Future<dynamic> put(String path, {Json? data}) => _send(() => _dio.put(path, data: data));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  Future<Paginated<T>> getPage<T>(String path, T Function(Json) fromItem, {int? page, int? limit, Json? query}) async {
    final data = await get(path, query: {'page': page, 'limit': limit, ...?query});
    return Paginated.fromJson(data as Json, fromItem);
  }

  /// Unwraps `{ success, message, data }` and returns `data`.
  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final body = (await request()).data;
      if (body is Map && body['success'] == false) {
        throw ApiException(body['message'] as String? ?? 'Request failed');
      }
      return body is Map ? body['data'] : body;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Json? _clean(Json? query) => query == null ? null : (Map.of(query)..removeWhere((_, v) => v == null));
}
