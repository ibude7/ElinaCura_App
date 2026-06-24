import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../auth/secure_token_store.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    SecureTokenStore? tokenStore,
  })  : _tokenStore = tokenStore ?? SecureTokenStore(),
        _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConfig.apiBase,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 20),
        )) {
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  final Dio _dio;
  final SecureTokenStore _tokenStore;

  Future<String?> getValidToken({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _tokenStore.readToken();
      if (cached != null) return cached;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken(forceRefresh);
    if (token == null) return null;
    await _tokenStore.persistToken(token);
    return token;
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await getValidToken();
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final appCheck = await FirebaseAppCheck.instance.getToken();
      if (appCheck != null) {
        headers['X-Firebase-AppCheck'] = appCheck;
      }
    } catch (_) {
      // App Check optional in dev
    }
    return headers;
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    return _withRetry(() async {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return response.data as T;
    });
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _withRetry(() async {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as T;
    });
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _withRetry(() async {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as T;
    });
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _withRetry(() async {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as T;
    });
  }

  Future<T> postMultipart<T>(
    String path, {
    required FormData formData,
  }) async {
    return _withRetry(() async {
      final response = await _dio.post<T>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data as T;
    });
  }

  Future<T> delete<T>(String path) async {
    return _withRetry(() async {
      final response = await _dio.delete<T>(
        path,
      );
      return response.data as T;
    });
  }

  Future<T> _withRetry<T>(Future<T> Function() fn, {int attempts = 3}) async {
    Object? lastError;
    for (var i = 0; i < attempts; i++) {
      try {
        return await fn();
      } on DioException catch (e) {
        lastError = e;
        final status = e.response?.statusCode;
        if (status == 401) {
          try {
            await getValidToken(forceRefresh: true);
            return await fn();
          } catch (_) {
            throw TokenRefreshExhaustedError('Session expired');
          }
        }
        if (status != null && status >= 400 && status < 500 && status != 408) {
          rethrow;
        }
        if (i == attempts - 1) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 250 * (1 << i)));
      }
    }
    throw lastError ?? Exception('Request failed');
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);
  final ApiClient _client;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final headers = await _client.authHeaders();
    options.headers.addAll(headers);
    handler.next(options);
  }
}
