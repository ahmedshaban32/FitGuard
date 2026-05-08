import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';

class DioClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://fitguard-api.fly.dev/api/',
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  DioClient() {
    // _dio.interceptors.add(
    //   LogInterceptor(requestBody: true, responseBody: true),
    // );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await PrefHelper.getToken();
          if (kDebugMode) {
            debugPrint('API ${options.method} ${options.uri}');
          }

          if (token != null && token.isNotEmpty && token != 'guest') {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await PrefHelper.clearAll();
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
