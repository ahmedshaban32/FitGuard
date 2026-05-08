enum WorkoutHistorySource { ai, manual, cardio }

enum WorkoutHistoryType { strength, cardio, aiTracked }

class WorkoutHistoryEntry {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final DateTime sessionAt;
  final int totalReps;
  final int correctReps;
  final int wrongReps;
  final List<String> mistakes;
  final int caloriesBurned;
  final int durationSeconds;
  final WorkoutHistoryType type;
  final WorkoutHistorySource source;
  final bool synced;

  const WorkoutHistoryEntry({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.sessionAt,
    this.totalReps = 0,
    this.correctReps = 0,
    this.wrongReps = 0,
    this.mistakes = const [],
    this.caloriesBurned = 0,
    this.durationSeconds = 0,
    required this.type,
    required this.source,
    this.synced = false,
  });

  double get correctRate {
    if (totalReps <= 0) return 0;
    return (correctReps / totalReps).clamp(0, 1);
  }

  WorkoutHistoryEntry copyWith({bool? synced}) {
    return WorkoutHistoryEntry(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sessionAt: sessionAt,
      totalReps: totalReps,
      correctReps: correctReps,
      wrongReps: wrongReps,
      mistakes: mistakes,
      caloriesBurned: caloriesBurned,
      durationSeconds: durationSeconds,
      type: type,
      source: source,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sessionAt': sessionAt.toIso8601String(),
    'totalReps': totalReps,
    'correctReps': correctReps,
    'wrongReps': wrongReps,
    'mistakes': mistakes,
    'caloriesBurned': caloriesBurned,
    'durationSeconds': durationSeconds,
    'type': type.name,
    'source': source.name,
    'synced': synced,
  };

  Map<String, dynamic> toBackendJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sessionAt': sessionAt.toIso8601String(),
    'totalReps': totalReps,
    'correctReps': correctReps,
    'wrongReps': wrongReps,
    'mistakes': mistakes,
    'caloriesBurned': caloriesBurned,
    'durationSeconds': durationSeconds,
    'sessionType': type.name,
    'source': source.name,
    'tracked': source == WorkoutHistorySource.ai,
  };

  factory WorkoutHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutHistoryEntry(
      id: _string(json['id'], DateTime.now().microsecondsSinceEpoch.toString()),
      exerciseId: _string(json['exerciseId'] ?? json['exercise_id'], ''),
      exerciseName: _string(
        json['exerciseName'] ?? json['exercise_name'],
        'Workout',
      ),
      sessionAt:
          DateTime.tryParse(
            _string(json['sessionAt'] ?? json['session_at'], ''),
          ) ??
          DateTime.now(),
      totalReps: _int(json['totalReps'] ?? json['total_reps'], 0),
      correctReps: _int(json['correctReps'] ?? json['correct_reps'], 0),
      wrongReps: _int(json['wrongReps'] ?? json['wrong_reps'], 0),
      mistakes: _strings(json['mistakes'] ?? json['errors']),
      caloriesBurned: _int(
        json['caloriesBurned'] ?? json['calories_burned'],
        0,
      ),
      durationSeconds: _int(
        json['durationSeconds'] ?? json['duration_seconds'],
        0,
      ),
      type: _historyType(
        json['type'] ?? json['sessionType'] ?? json['session_type'],
      ),
      source: _source(json['source']),
      synced: json['synced'] == true,
    );
  }
}

class ProgressSummary {
  final int totalWorkouts;
  final int cardioSessions;
  final int caloriesBurned;
  final int activeMinutes;
  final int totalReps;
  final int correctReps;
  final int workoutStreak;
  final WorkoutHistoryEntry? latest;

  const ProgressSummary({
    this.totalWorkouts = 0,
    this.cardioSessions = 0,
    this.caloriesBurned = 0,
    this.activeMinutes = 0,
    this.totalReps = 0,
    this.correctReps = 0,
    this.workoutStreak = 0,
    this.latest,
  });

  double get accuracy {
    if (totalReps <= 0) return 0;
    return (correctReps / totalReps).clamp(0, 1);
  }

  factory ProgressSummary.fromEntries(List<WorkoutHistoryEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => b.sessionAt.compareTo(a.sessionAt));
    return ProgressSummary(
      totalWorkouts: entries
          .where((item) => item.type != WorkoutHistoryType.cardio)
          .length,
      cardioSessions: entries
          .where((item) => item.type == WorkoutHistoryType.cardio)
          .length,
      caloriesBurned: entries.fold(0, (sum, item) => sum + item.caloriesBurned),
      activeMinutes: entries.fold(
        0,
        (sum, item) => sum + (item.durationSeconds / 60).round(),
      ),
      totalReps: entries.fold(0, (sum, item) => sum + item.totalReps),
      correctReps: entries.fold(0, (sum, item) => sum + item.correctReps),
      workoutStreak: _streak(entries),
      latest: sorted.isEmpty ? null : sorted.first,
    );
  }
}

int estimateCalories({
  required WorkoutHistoryType type,
  required int durationSeconds,
  required int totalReps,
}) {
  if (durationSeconds > 0) {
    final minutes = durationSeconds / 60;
    final perMinute = type == WorkoutHistoryType.cardio ? 9 : 6;
    return (minutes * perMinute).round().clamp(0, 3000);
  }
  return (totalReps * 2.4).round().clamp(0, 1200);
}

int _streak(List<WorkoutHistoryEntry> entries) {
  if (entries.isEmpty) return 0;
  final days = entries
      .map(
        (item) => DateTime(
          item.sessionAt.year,
          item.sessionAt.month,
          item.sessionAt.day,
        ),
      )
      .toSet();
  var cursor = DateTime.now();
  var count = 0;
  while (days.contains(DateTime(cursor.year, cursor.month, cursor.day))) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}

String _string(dynamic value, String fallback) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

List<String> _strings(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  if (value is String && value.trim().isNotEmpty) return [value.trim()];
  return const [];
}

WorkoutHistoryType _historyType(dynamic value) {
  final text = value?.toString().toLowerCase() ?? '';
  if (text.contains('cardio')) return WorkoutHistoryType.cardio;
  if (text.contains('ai')) return WorkoutHistoryType.aiTracked;
  return WorkoutHistoryType.strength;
}

WorkoutHistorySource _source(dynamic value) {
  final text = value?.toString().toLowerCase() ?? '';
  if (text.contains('manual')) return WorkoutHistorySource.manual;
  if (text.contains('cardio')) return WorkoutHistorySource.cardio;
  return WorkoutHistorySource.ai;
}
