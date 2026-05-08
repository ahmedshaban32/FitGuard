import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/network/api_exceptions.dart';
import 'package:fit_guard_app/Core/network/dio_client.dart';
import 'package:fit_guard_app/features/food_scanner/models/food_scan_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FoodScannerService {
  final Dio _dio;

  FoodScannerService({Dio? dio}) : _dio = dio ?? DioClient().dio;

  Future<FoodScanResult> scanFood(File image) async {
    if (!image.existsSync()) {
      throw ApiError(message: 'Selected food image was not found.');
    }

    final endpoint =
        dotenv.maybeGet('FOOD_SCAN_ENDPOINT')?.trim().isNotEmpty == true
        ? dotenv.get('FOOD_SCAN_ENDPOINT')
        : '/ai/food-scan';

    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.uri.pathSegments.isNotEmpty
              ? image.uri.pathSegments.last
              : 'food.jpg',
        ),
      });
      final response = await _dio
          .post(endpoint, data: form)
          .timeout(const Duration(seconds: 45));
      final data = response.data;
      if (data is Map<String, dynamic>) return FoodScanResult.fromJson(data);
      if (data is Map) {
        return FoodScanResult.fromJson(Map<String, dynamic>.from(data));
      }
      throw ApiError(message: 'Food scanner returned an invalid response.');
    } on DioException catch (error) {
      final handled = ApiExceptions.handleError(error);
      if (handled.statusCode == 404) {
        throw ApiError(
          message:
              'Food scan proxy is not available yet. Add a backend multipart endpoint at /api/ai/food-scan and keep vision API keys on the server.',
          statusCode: 404,
        );
      }
      throw handled;
    } catch (error) {
      if (error is ApiError) rethrow;
      throw ApiError(message: error.toString());
    }
  }
}
