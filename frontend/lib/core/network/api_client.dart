import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api',
  );
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(),
        _storage = storage ?? const FlutterSecureStorage() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // Retry original request
        final opts = error.requestOptions;
        final token = await _storage.read(key: _accessTokenKey);
        opts.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    handler.next(error);
  }

  Future<bool> _tryRefreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final response = await Dio().post(
        '$_baseUrl/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.write(
          key: _accessTokenKey,
          value: data['access_token'],
        );
        return true;
      }
    } catch (_) {
      // Refresh failed — clear tokens
      await clearTokens();
    }
    return false;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null;
  }
}
