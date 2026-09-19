import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  final StorageService _storage = StorageService();

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request & Error Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Attempt automatic token refresh on 401 Unauthorized
          if (error.response?.statusCode == 401 &&
              error.requestOptions.path != ApiConfig.login &&
              error.requestOptions.path != ApiConfig.refresh) {
            final refreshToken = await _storage.getRefreshToken();
            if (refreshToken != null) {
              try {
                final refreshResponse = await Dio().post(
                  '${ApiConfig.baseUrl}${ApiConfig.refresh}',
                  data: {'refreshToken': refreshToken},
                );

                if (refreshResponse.statusCode == 200 && refreshResponse.data['success'] == true) {
                  final newAccessToken = refreshResponse.data['data']['accessToken'];
                  final newRefreshToken = refreshResponse.data['data']['refreshToken'];
                  await _storage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Retry the original request with the new access token
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final retryResponse = await dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
                // Refresh failed: clear storage and proceed with error
                await _storage.clearAll();
              }
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map) {
        return error.response?.data['message'] ?? 'An unexpected server error occurred.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check your internet connection.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to the attendance server. Please ensure backend is running.';
      }
    }
    return error.toString();
  }
}
