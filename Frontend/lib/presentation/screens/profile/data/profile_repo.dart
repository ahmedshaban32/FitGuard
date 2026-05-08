import 'package:dio/dio.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/network/api_exceptions.dart';
import 'package:fit_guard_app/Core/network/api_service.dart';

class ProfileModel {
  final String? name;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final int? mealsPerDay;
  final String? gender;
  final String? goal;
  final String? activityLevel;
  final String? dietaryPreference;
  final String? foodDislikes;
  final String? healthConditions;
  final String? allergies;

  const ProfileModel({
    this.name,
    this.age,
    this.heightCm,
    this.weightKg,
    this.mealsPerDay,
    this.gender,
    this.goal,
    this.activityLevel,
    this.dietaryPreference,
    this.foodDislikes,
    this.healthConditions,
    this.allergies,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final source = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : json['user'] is Map && (json['user'] as Map)['profile'] is Map
        ? Map<String, dynamic>.from((json['user'] as Map)['profile'] as Map)
        : json;

    return ProfileModel(
      name: _string(source['name']),
      age: _int(source['age']),
      heightCm: _double(
        source['heightCm'] ?? source['height_cm'] ?? source['height'],
      ),
      weightKg: _double(
        source['weightKg'] ?? source['weight_kg'] ?? source['weight'],
      ),
      mealsPerDay: _int(source['mealsPerDay'] ?? source['meals_per_day']),
      gender: _string(source['gender']),
      goal: _string(source['goal']),
      activityLevel: _string(
        source['activityLevel'] ?? source['activity_level'],
      ),
      dietaryPreference: _string(
        source['dietaryPreference'] ?? source['dietary_preference'],
      ),
      foodDislikes: _string(source['foodDislikes'] ?? source['food_dislikes']),
      healthConditions: _string(
        source['healthConditions'] ?? source['health_conditions'],
      ),
      allergies: _string(source['allergies']),
    );
  }

  Map<String, dynamic> toBackendJson() => {
    if (name != null) 'name': name,
    if (age != null) 'age': age,
    if (heightCm != null) 'heightCm': heightCm,
    if (weightKg != null) 'weightKg': weightKg,
    if (mealsPerDay != null) 'mealsPerDay': mealsPerDay,
    if (gender != null) 'gender': gender,
    if (goal != null) 'goal': goal,
    if (activityLevel != null) 'activityLevel': activityLevel,
    if (dietaryPreference != null) 'dietaryPreference': dietaryPreference,
    if (foodDislikes != null) 'foodDislikes': foodDislikes,
    if (healthConditions != null) 'healthConditions': healthConditions,
    if (allergies != null) 'allergies': allergies,
  };

  Map<String, dynamic> toAiNutritionJson() {
    final missing = <String>[
      if (age == null) 'age',
      if (gender == null || gender!.isEmpty) 'gender',
      if (weightKg == null) 'weight',
      if (heightCm == null) 'height',
      if (mealsPerDay == null) 'meals per day',
      if (goal == null || goal!.isEmpty) 'goal',
      if (activityLevel == null || activityLevel!.isEmpty) 'activity level',
      if (dietaryPreference == null || dietaryPreference!.isEmpty)
        'dietary preference',
    ];

    if (missing.isNotEmpty) {
      throw ApiError(
        message:
            'Complete your profile first: ${missing.join(', ')} are required.',
      );
    }

    return {
      'age': age,
      'gender': gender,
      'weight': weightKg,
      'height': heightCm,
      'meals_per_day': mealsPerDay,
      'goal': goal,
      'activity': activityLevel,
      'diet_pref': dietaryPreference,
      'dislikes': foodDislikes ?? '',
      'health_conditions': healthConditions ?? '',
      'allergies': allergies ?? '',
    };
  }

  Map<String, dynamic> toLocalUserInfoJson() => {
    'profile': {
      'age': age,
      'height_cm': heightCm?.round(),
      'weight_kg': weightKg?.round(),
      'meals_per_day': mealsPerDay,
      'gender': gender,
      'goal': goal,
      'activity_level': activityLevel,
    },
    'food_preferences': {
      'dietary_preference': dietaryPreference,
      'food_dislikes': foodDislikes ?? '',
    },
    'health': {
      'health_conditions': healthConditions ?? '',
      'allergies': allergies ?? '',
    },
  };

  ProfileModel copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    int? mealsPerDay,
    String? gender,
    String? goal,
    String? activityLevel,
    String? dietaryPreference,
    String? foodDislikes,
    String? healthConditions,
    String? allergies,
  }) => ProfileModel(
    name: name ?? this.name,
    age: age ?? this.age,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    mealsPerDay: mealsPerDay ?? this.mealsPerDay,
    gender: gender ?? this.gender,
    goal: goal ?? this.goal,
    activityLevel: activityLevel ?? this.activityLevel,
    dietaryPreference: dietaryPreference ?? this.dietaryPreference,
    foodDislikes: foodDislikes ?? this.foodDislikes,
    healthConditions: healthConditions ?? this.healthConditions,
    allergies: allergies ?? this.allergies,
  );

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _double(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class ProfileRepo {
  final ApiService _api = ApiService();

  Future<ProfileModel> getProfile() async {
    try {
      final response = await _api.get('/users/me/profile');
      if (response is ApiError) throw response;
      if (response is Map<String, dynamic>) {
        return ProfileModel.fromJson(response);
      }
      if (response is Map) {
        return ProfileModel.fromJson(Map<String, dynamic>.from(response));
      }
      throw ApiError(message: 'Invalid profile response from server');
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    try {
      final response = await _api.patch(
        '/users/me/profile',
        profile.toBackendJson(),
      );
      if (response is ApiError) throw response;
      if (response is Map<String, dynamic>) {
        return ProfileModel.fromJson(response);
      }
      if (response is Map) {
        return ProfileModel.fromJson(Map<String, dynamic>.from(response));
      }
      return profile;
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  Future<void> generateAiPlan() async {
    try {
      final response = await _api.post('/users/me/ai-plan', {});
      if (response is ApiError) throw response;
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }
}
