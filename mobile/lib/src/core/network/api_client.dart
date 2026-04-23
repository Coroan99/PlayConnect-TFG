import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'api_response.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  if (AppConfig.enableNetworkLogs) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResponse> get(String path) {
    return _request(() => _dio.get<Object?>(_normalize(path)));
  }

  Future<ApiResponse> post(String path, {Object? data}) {
    return _request(() => _dio.post<Object?>(_normalize(path), data: data));
  }

  Future<ApiResponse> _request(
    Future<Response<Object?>> Function() request,
  ) async {
    try {
      final response = await request();
      return _parsePayload(response.data);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  ApiResponse _parsePayload(Object? payload) {
    final json = _asJsonMap(payload);
    final apiResponse = ApiResponse.fromJson(json);

    if (!apiResponse.ok) {
      throw ApiException(apiResponse.message);
    }

    return apiResponse;
  }

  ApiException _toApiException(DioException error) {
    final response = error.response;

    if (response != null) {
      final payload = response.data;

      if (payload is Map) {
        final json = Map<String, Object?>.from(payload);
        final apiResponse = ApiResponse.fromJson(json);

        return ApiException(
          apiResponse.message,
          statusCode: response.statusCode,
        );
      }

      return ApiException(
        'Error HTTP ${response.statusCode ?? ''}'.trim(),
        statusCode: response.statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        'La API no ha respondido a tiempo. Revisa que el backend este activo.',
      );
    }

    return const ApiException(
      'No se pudo conectar con la API. Revisa la URL configurada.',
    );
  }

  Map<String, Object?> _asJsonMap(Object? payload) {
    if (payload is Map<String, Object?>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, Object?>.from(payload);
    }

    throw const ApiException('La API devolvio una respuesta inesperada.');
  }

  String _normalize(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }
}
