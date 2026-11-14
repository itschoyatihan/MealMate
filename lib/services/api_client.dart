import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin Dio wrapper: base configuration, bearer-token injection and
/// conversion of transport failures into [ApiException]s.
class ApiClient {
  ApiClient({required this.tokenStorage, Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
              connectTimeout: AppConstants.apiConnectTimeout,
              receiveTimeout: AppConstants.apiReceiveTimeout,
              sendTimeout: AppConstants.apiSendTimeout,
              contentType: Headers.jsonContentType,
              responseType: ResponseType.json,
              headers: const {'Accept': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _attachAccessToken));
  }

  final Dio _dio;
  final TokenStorage tokenStorage;

  Future<void> _attachAccessToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      try {
        final token = await tokenStorage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // A storage failure should not block the request; the API will
        // respond with 401 and the UI will route to login.
      }
    }
    handler.next(options);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
  }) {
    return _run(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _options(authenticated),
      ),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    bool authenticated = true,
  }) {
    return _run(
      () => _dio.post<dynamic>(
        path,
        data: data,
        options: _options(authenticated),
      ),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? data,
    bool authenticated = true,
  }) {
    return _run(
      () =>
          _dio.put<dynamic>(path, data: data, options: _options(authenticated)),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? data,
    bool authenticated = true,
  }) {
    return _run(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        options: _options(authenticated),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? data,
    bool authenticated = true,
  }) {
    return _run(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        options: _options(authenticated),
      ),
    );
  }

  Options _options(bool authenticated) {
    return Options(extra: {'skipAuth': !authenticated});
  }

  Future<Map<String, dynamic>> _run(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data;
      if (body is Map) return Map<String, dynamic>.from(body);
      return <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
