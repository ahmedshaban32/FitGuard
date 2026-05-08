import 'package:dio/dio.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';

class ApiExceptions {
  static ApiError handleError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    final backendMessage = _messageFromBody(data);
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return ApiError(message: backendMessage, statusCode: statusCode);
    }

    if (response == null) {
      return ApiError(message: 'No response from server. Please try again');
    }

    switch (statusCode) {
      case 400:
      case 422:
        return ApiError(message: 'Invalid input data', statusCode: statusCode);
      case 401:
        return ApiError(
          message: 'Session expired or credentials are invalid',
          statusCode: statusCode,
        );
      case 403:
        return ApiError(message: 'You do not have access', statusCode: statusCode);
      case 409:
        return ApiError(
          message: 'This email or subscription already exists',
          statusCode: statusCode,
        );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return ApiError(message: 'Connection timeout. Check your internet');
      case DioExceptionType.receiveTimeout:
        return ApiError(message: 'Server took too long to respond');
      case DioExceptionType.badResponse:
        return ApiError(
          message: 'Request failed (${statusCode ?? 'unknown'})',
          statusCode: statusCode,
        );
      default:
        return ApiError(message: 'Unexpected error occurred');
    }
  }

  static String? _messageFromBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }
      for (final key in ['message', 'detail']) {
        final value = data[key];
        if (value != null) return value.toString();
      }
    }
    return null;
  }
}
