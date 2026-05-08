import 'package:dio/dio.dart';
import 'package:fit_guard_app/Core/network/api_exceptions.dart';
import 'package:fit_guard_app/Core/network/dio_client.dart';

class ApiService {
  final DioClient _dioClient = DioClient();

  /// CRUD METHODS

  /// get
  Future<dynamic> get(String endPoint, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dioClient.dio.get(
        _cleanPath(endPoint),
        queryParameters: query,
      );
      return response.data;
    } on DioException catch (e) {
      return ApiExceptions.handleError(e);
    }
  }

  /// post
  Future<dynamic> post(String endPoint, dynamic body) async {
    try {
      final response = await _dioClient.dio.post(_cleanPath(endPoint), data: body);
      return response.data;
    } on DioException catch (e) {
      return ApiExceptions.handleError(e);
    }
  }

  Future<dynamic> patch(String endPoint, dynamic body) async {
    try {
      final response = await _dioClient.dio.patch(_cleanPath(endPoint), data: body);
      return response.data;
    } on DioException catch (e) {
      return ApiExceptions.handleError(e);
    }
  }

  /// put || update
  Future<dynamic> put(String endPoint, dynamic body) async {
    try {
      final response = await _dioClient.dio.put(_cleanPath(endPoint), data: body);
      return response.data;
    } on DioException catch (e) {
      return ApiExceptions.handleError(e);
    }
  }

  /// delete
  Future<dynamic> delete(String endPoint, [dynamic body]) async {
    try {
      final response = await _dioClient.dio.delete(_cleanPath(endPoint), data: body);
      return response.data;
    } on DioException catch (e) {
      return ApiExceptions.handleError(e);
    }
  }

  String _cleanPath(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }
}
