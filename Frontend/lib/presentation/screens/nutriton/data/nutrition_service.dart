import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/presentation/screens/profile/data/profile_repo.dart';
import 'package:http/http.dart' as http;

const _kDefaultAiBaseUrl =
    'https://silver-space-enigma-5grvq594jr5xh46w7-8000.app.github.dev';
const _kAiBaseUrl = String.fromEnvironment(
  'FITGUARD_AI_BASE_URL',
  defaultValue: _kDefaultAiBaseUrl,
);

class NutritionService {
  final http.Client _client;

  NutritionService({http.Client? client}) : _client = client ?? http.Client();

  Future<NutritionPlan> generatePlan(ProfileModel profile) async {
    final response = await _postJson(
      '/nutrition/generate-plan',
      profile.toAiNutritionJson(),
      timeout: const Duration(seconds: 45),
    );
    return NutritionPlan.fromJson(response);
  }

  Future<RecipeDetails> getRecipe({
    required NutritionMeal meal,
    required String goal,
  }) async {
    final response = await _postJson('/nutrition/get-recipe', {
      'name_en': meal.nameEn,
      'name_ar': meal.nameAr,
      'portion': meal.portion,
      'goal': goal,
    }, timeout: const Duration(seconds: 35));
    return RecipeDetails.fromJson(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    required Duration timeout,
  }) async {
    final response = await _client
        .post(
          _aiUri(path),
          headers: const {
            HttpHeaders.acceptHeader: 'application/json',
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(timeout);

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiError(
        message:
            'Nutrition AI failed (${response.statusCode}). Please try again.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw const FormatException('AI response was not an object');
    } catch (_) {
      throw ApiError(message: 'Invalid response from Nutrition AI.');
    }
  }

  Uri _aiUri(String path) {
    final base = _kAiBaseUrl.endsWith('/')
        ? _kAiBaseUrl.substring(0, _kAiBaseUrl.length - 1)
        : _kAiBaseUrl;
    return Uri.parse('$base$path');
  }

  void close() => _client.close();
}

class NutritionPlan {
  final int calories;
  final Map<String, String> macros;
  final String waterIntake;
  final List<String> notes;
  final Map<String, List<NutritionMeal>> meals;

  const NutritionPlan({
    required this.calories,
    required this.macros,
    required this.waterIntake,
    required this.notes,
    required this.meals,
  });

  bool get hasMeals => meals.values.any((items) => items.isNotEmpty);

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();
    if (status == 'error') {
      throw ApiError(
        message: (json['message'] ?? 'Nutrition AI failed.').toString(),
      );
    }
    final source = _map(json['plan']) ?? _map(json['data']) ?? json;
    final meals = _parseMeals(source);
    final dailyTarget =
        _map(source['daily_target']) ??
        _map(source['dailyTarget']) ??
        _map(source['target']) ??
        const <String, dynamic>{};
    final nestedMacros = _parseStringMap(
      source['macros'] ??
          dailyTarget['macros'] ??
          source['nutrition'] ??
          source['nutrition_values'],
    );
    final directMacros = _parseStringMap(_directMealMacros(dailyTarget));

    if (meals.values.every((items) => items.isEmpty)) {
      throw ApiError(message: 'Nutrition AI returned an empty meal plan.');
    }

    return NutritionPlan(
      calories: _readInt(
        source['calories'] ??
            dailyTarget['calories'] ??
            dailyTarget['kcal'] ??
            source['daily_calories'] ??
            source['target_calories'] ??
            source['total_calories'],
        0,
      ),
      macros: nestedMacros.isNotEmpty ? nestedMacros : directMacros,
      waterIntake:
          (source['water_intake'] ??
                  dailyTarget['water_intake'] ??
                  dailyTarget['water'] ??
                  source['water'] ??
                  source['waterIntake'] ??
                  '')
              .toString(),
      notes: _parseStringList(source['notes'] ?? source['recommendations']),
      meals: meals,
    );
  }

  static Map<String, List<NutritionMeal>> _parseMeals(
    Map<String, dynamic> source,
  ) {
    final result = <String, List<NutritionMeal>>{
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snacks': [],
    };

    final mealsSource =
        source['meals'] ??
        source['meal_plan'] ??
        source['weekly_plan'] ??
        source['weeklyPlan'] ??
        source;

    void addMeal(Map<String, dynamic> mealMap, String section) {
      result[section]!.add(NutritionMeal.fromJson(mealMap, section));
    }

    void collect(dynamic value, {String? section, int depth = 0}) {
      if (value == null || depth > 8) return;

      if (value is String && value.trim().isNotEmpty) {
        if (section != null) {
          addMeal({'name': value.trim()}, section);
        }
        return;
      }

      if (value is List) {
        for (final item in value) {
          collect(item, section: section, depth: depth + 1);
        }
        return;
      }

      final map = _map(value);
      if (map == null) return;

      final mealSection =
          _sectionName(
            (map['meal_type'] ??
                    map['mealType'] ??
                    map['type'] ??
                    map['section'])
                ?.toString(),
          ) ??
          section;

      if (mealSection != null && _looksLikeMeal(map)) {
        addMeal(map, mealSection);
        return;
      }

      for (final entry in map.entries) {
        if (_isPlanMetadataKey(entry.key)) continue;
        final nestedSection = _sectionName(entry.key) ?? section;
        collect(entry.value, section: nestedSection, depth: depth + 1);
      }
    }

    collect(mealsSource);
    return result;
  }

  static String? _sectionName(String? value) {
    final text = (value ?? '').toLowerCase();
    if (text.contains('breakfast')) return 'Breakfast';
    if (text.contains('lunch')) return 'Lunch';
    if (text.contains('dinner')) return 'Dinner';
    if (text.contains('snack')) return 'Snacks';
    return null;
  }

  static bool _isPlanMetadataKey(String key) {
    final normalized = key.toLowerCase();
    return normalized == 'daily_target' ||
        normalized == 'dailytarget' ||
        normalized == 'target' ||
        normalized == 'calories' ||
        normalized == 'daily_calories' ||
        normalized == 'target_calories' ||
        normalized == 'total_calories' ||
        normalized == 'macros' ||
        normalized == 'nutrition' ||
        normalized == 'nutrition_values' ||
        normalized == 'water' ||
        normalized == 'water_intake' ||
        normalized == 'waterintake' ||
        normalized == 'notes' ||
        normalized == 'recommendations';
  }

  static bool _looksLikeMeal(Map<String, dynamic> map) {
    const mealKeys = {
      'name_en',
      'nameEn',
      'name_ar',
      'nameAr',
      'name',
      'meal_name',
      'mealName',
      'meal',
      'food',
      'food_name',
      'foodName',
      'dish',
      'dish_name',
      'dishName',
      'title',
      'portion',
      'serving',
      'serving_size',
      'servingSize',
      'items',
      'foods',
      'calories',
      'kcal',
      'protein',
      'protein_g',
      'carbs',
      'carbs_g',
      'fat',
      'fat_g',
    };
    return map.keys.any(mealKeys.contains);
  }
}

class NutritionMeal {
  final String section;
  final String nameEn;
  final String nameAr;
  final String portion;
  final int calories;
  final Map<String, String> macros;
  final String note;

  const NutritionMeal({
    required this.section,
    required this.nameEn,
    required this.nameAr,
    required this.portion,
    required this.calories,
    required this.macros,
    required this.note,
  });

  factory NutritionMeal.fromJson(Map<String, dynamic> json, String section) {
    final name = _readMealName(json);
    return NutritionMeal(
      section: section,
      nameEn: name,
      nameAr: (json['name_ar'] ?? json['nameAr'] ?? name).toString(),
      portion:
          (json['portion'] ??
                  json['serving'] ??
                  json['serving_size'] ??
                  json['servingSize'] ??
                  json['amount'] ??
                  json['quantity'] ??
                  '1 serving')
              .toString(),
      calories: _readInt(json['calories'] ?? json['kcal'], 0),
      macros: _parseStringMap(
        json['macros'] ?? json['nutrition'] ?? _directMealMacros(json),
      ),
      note:
          (json['health_note'] ??
                  json['healthNote'] ??
                  json['note'] ??
                  json['notes'] ??
                  json['tag'] ??
                  '')
              .toString(),
    );
  }

  static String _readMealName(Map<String, dynamic> json) {
    final direct =
        json['name_en'] ??
        json['nameEn'] ??
        json['name'] ??
        json['meal_name'] ??
        json['mealName'] ??
        json['meal'] ??
        json['food'] ??
        json['food_name'] ??
        json['foodName'] ??
        json['dish'] ??
        json['dish_name'] ??
        json['dishName'] ??
        json['title'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }

    final items = json['items'] ?? json['foods'];
    if (items is List) {
      final names = items
          .map((item) {
            final map = _map(item);
            if (map != null) return _readMealName(map);
            return item.toString().trim();
          })
          .where((item) => item.isNotEmpty && item != 'Meal')
          .toList();
      if (names.isNotEmpty) return names.join(', ');
    }

    final description = json['description'];
    if (description != null && description.toString().trim().isNotEmpty) {
      return description.toString().trim();
    }
    return 'Meal';
  }
}

class RecipeDetails {
  final String title;
  final List<String> ingredients;
  final List<String> steps;
  final int calories;
  final Map<String, String> nutritionValues;

  const RecipeDetails({
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.calories,
    required this.nutritionValues,
  });

  factory RecipeDetails.fromJson(Map<String, dynamic> json) {
    final source = _map(json['recipe']) ?? _map(json['data']) ?? json;
    return RecipeDetails(
      title:
          (source['title'] ?? source['name_en'] ?? source['name'] ?? 'Recipe')
              .toString(),
      ingredients: _parseStringList(source['ingredients']),
      steps: _parseStringList(
        source['preparation_steps'] ??
            source['preparation'] ??
            source['how_to_make'] ??
            source['howToMake'] ??
            source['steps'] ??
            source['instructions'],
      ),
      calories: _readInt(source['calories'] ?? source['kcal'], 0),
      nutritionValues: _parseStringMap(
        source['nutrition_values'] ?? source['nutrition'] ?? source['macros'],
      ),
    );
  }
}

Map<String, dynamic>? _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int _readInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

Map<String, String> _parseStringMap(dynamic value) {
  final map = _map(value);
  if (map == null) return {};
  return map.map((key, value) => MapEntry(key.toString(), value.toString()));
}

Map<String, dynamic> _directMealMacros(Map<String, dynamic> json) {
  final macros = <String, dynamic>{};
  final protein = json['protein'] ?? json['protein_g'] ?? json['proteinG'];
  final carbs = json['carbs'] ?? json['carbs_g'] ?? json['carbsG'];
  final fat = json['fat'] ?? json['fat_g'] ?? json['fatG'] ?? json['fats'];
  if (protein != null) macros['protein'] = protein;
  if (carbs != null) macros['carbs'] = carbs;
  if (fat != null) macros['fat'] = fat;
  return macros;
}

List<String> _parseStringList(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(RegExp(r'\n|\. '))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}
