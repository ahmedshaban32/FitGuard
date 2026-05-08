// lib/presentation/screens/coaches/data/coach_repo.dart

import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/network/api_exceptions.dart';
import 'package:fit_guard_app/Core/network/api_service.dart';
import 'package:dio/dio.dart';

// ══════════════════════════════════════════════════════════════
// MODELS
// ══════════════════════════════════════════════════════════════

class CoachModel {
  final String id;
  final String name;
  final String? bio;
  final List<String> specialties;
  final String? image;
  final double? rating;

  const CoachModel({
    required this.id,
    required this.name,
    this.bio,
    this.specialties = const [],
    this.image,
    this.rating,
  });

  factory CoachModel.fromJson(Map<String, dynamic> j) => CoachModel(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    bio: j['bio']?.toString(),
    specialties: List<String>.from(j['specialties'] ?? []),
    image: j['image']?.toString(),
    rating: (j['rating'] as num?)?.toDouble(),
  );
}

// ══════════════════════════════════════════════════════════════
// REPO
// ══════════════════════════════════════════════════════════════

class CoachRepo {
  final _api = ApiService();

  /// GET /coaches/public  — list all public coaches
  Future<List<CoachModel>> getCoaches() async {
    try {
      final res = await _api.get('coaches/public');
      if (res is ApiError) throw res;
      final list = (res['coaches'] ?? res) as List<dynamic>;
      return list
          .map((c) => CoachModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  /// POST /coaches/applications  — apply to become a coach
  /// [data] fields: motivation, specialties, experience
  Future<void> applyAsCoach(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('coaches/applications', data);
      if (res is ApiError) throw res;
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }
}
