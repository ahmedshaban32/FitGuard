class FoodScanResult {
  final String foodName;
  final String servingEstimate;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final double confidence;
  final List<String> notes;

  const FoodScanResult({
    required this.foodName,
    required this.servingEstimate,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.confidence = 0,
    this.notes = const [],
  });

  factory FoodScanResult.fromJson(Map<String, dynamic> json) {
    final source = json['result'] is Map
        ? Map<String, dynamic>.from(json['result'] as Map)
        : json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    return FoodScanResult(
      foodName:
          (source['foodName'] ??
                  source['food_name'] ??
                  source['name'] ??
                  source['food'] ??
                  'Detected food')
              .toString(),
      servingEstimate:
          (source['servingEstimate'] ??
                  source['serving_estimate'] ??
                  source['serving'] ??
                  source['portion'] ??
                  '1 serving')
              .toString(),
      calories: _int(source['calories'] ?? source['kcal'], 0),
      protein: _double(source['protein'] ?? source['protein_g'], 0),
      carbs: _double(
        source['carbs'] ?? source['carbohydrates'] ?? source['carbs_g'],
        0,
      ),
      fats: _double(source['fats'] ?? source['fat'] ?? source['fat_g'], 0),
      confidence: _double(source['confidence'], 0),
      notes: _strings(source['notes']),
    );
  }
}

int _int(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _double(dynamic value, double fallback) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

List<String> _strings(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  if (value is String && value.trim().isNotEmpty) return [value.trim()];
  return const [];
}
