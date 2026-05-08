import 'package:flutter/foundation.dart';

class Exercise {
  final String key;
  final String name;
  final String reps;
  final int sets;
  final String difficulty;
  final String instructions;
  final List<String> tips;
  final String type;
  final String defaultWeight;
  final List<String> landmarks;

  const Exercise({
    this.key = '',
    required this.name,
    required this.reps,
    required this.sets,
    required this.difficulty,
    required this.instructions,
    required this.tips,
    this.type = '',
    this.defaultWeight = '',
    this.landmarks = const [],
  });

  factory Exercise.fromConfig(BackendExerciseConfig config) {
    return Exercise(
      key: config.key,
      name: config.displayName,
      reps: _defaultRepsForType(config.type),
      sets: _defaultSetsForType(config.type),
      difficulty: _defaultDifficultyForConfig(config),
      instructions: config.instructions,
      tips: _tipsForConfig(config),
      type: config.type,
      defaultWeight: config.defaultWeight,
      landmarks: config.landmarks,
    );
  }

  static Exercise? tryFromJson(Map<String, dynamic> json) {
    final rawName = _readString(json, [
      'display_name',
      'displayName',
      'name',
      'exercise_name',
      'title',
      'key',
    ]);
    final config = _configForInput(
      rawName,
      action: 'ignoring exercise payload',
    );
    if (config == null) return null;

    return Exercise(
      key: config.key,
      name: config.displayName,
      reps: _readString(json, [
        'reps',
        'repRange',
        'rep_range',
      ], fallback: _defaultRepsForType(config.type)),
      sets: _readInt(json, [
        'sets',
      ], fallback: _defaultSetsForType(config.type)),
      difficulty: _readString(json, [
        'difficulty',
        'level',
      ], fallback: _defaultDifficultyForConfig(config)),
      instructions: config.instructions,
      tips: _tipsForConfig(config),
      type: config.type,
      defaultWeight: config.defaultWeight,
      landmarks: config.landmarks,
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final exercise = tryFromJson(json);
    if (exercise != null) return exercise;

    throw ArgumentError.value(
      json,
      'json',
      'Unsupported workout exercise. Expected a backend exercise key or display name.',
    );
  }
}

class WorkoutDay {
  final int dayNumber;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final List<Exercise> exercises;

  const WorkoutDay({
    required this.dayNumber,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.exercises,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    final exercises = rawExercises is List
        ? rawExercises
              .whereType<Map>()
              .map(
                (item) => Exercise.tryFromJson(Map<String, dynamic>.from(item)),
              )
              .whereType<Exercise>()
              .toList()
        : const <Exercise>[];

    return WorkoutDay(
      dayNumber: _readInt(json, [
        'dayNumber',
        'day_number',
        'day',
      ], fallback: 1),
      title: _readString(json, ['title', 'name'], fallback: 'Workout Day'),
      subtitle: _readString(json, ['subtitle', 'focus', 'focusArea']),
      durationMinutes: _readInt(json, [
        'durationMinutes',
        'duration_minutes',
        'duration',
      ], fallback: exercises.length * 8),
      exercises: exercises,
    );
  }
}

class BackendExerciseConfig {
  final String key;
  final String type;
  final String displayName;
  final String instructions;
  final String defaultWeight;
  final List<String> landmarks;
  final bool machineMode;

  const BackendExerciseConfig({
    required this.key,
    required this.type,
    required this.displayName,
    required this.instructions,
    required this.defaultWeight,
    required this.landmarks,
    this.machineMode = false,
  });
}

const List<String> backendExerciseKeyOrder = [
  'bicep_curl',
  'hammer_curl',
  'deadlift',
  'kettlebell_swing',
  'bodyweight_squat',
  'leg_press_machine',
  'lunge',
  'pushup',
  'chest_press_machine',
  'lat_pulldown',
  'seated_row',
  'plank',
  'wall_sit',
];

const Set<String> backendExerciseKeys = {
  'bicep_curl',
  'hammer_curl',
  'deadlift',
  'kettlebell_swing',
  'bodyweight_squat',
  'leg_press_machine',
  'lunge',
  'pushup',
  'chest_press_machine',
  'lat_pulldown',
  'seated_row',
  'plank',
  'wall_sit',
};

const Map<String, BackendExerciseConfig> backendExerciseConfig = {
  'bicep_curl': BackendExerciseConfig(
    key: 'bicep_curl',
    type: 'curl',
    displayName: 'Standard Bicep Curl',
    instructions:
        'Palms facing forward, elbows pinned to your sides, curl toward shoulders.',
    defaultWeight: '10kg dumbbells',
    landmarks: ['shoulder', 'elbow', 'wrist'],
  ),
  'hammer_curl': BackendExerciseConfig(
    key: 'hammer_curl',
    type: 'curl',
    displayName: 'Hammer Curl',
    instructions: 'Palms facing each other and thumbs up through the full rep.',
    defaultWeight: '12kg dumbbells',
    landmarks: ['shoulder', 'elbow', 'wrist'],
  ),
  'deadlift': BackendExerciseConfig(
    key: 'deadlift',
    type: 'hinge',
    displayName: 'Deadlift / Hip Hinge',
    instructions:
        'Push hips back, keep chest up, and return to a tall lockout.',
    defaultWeight: '20kg barbell',
    landmarks: ['shoulder', 'hip', 'knee', 'ankle'],
  ),
  'kettlebell_swing': BackendExerciseConfig(
    key: 'kettlebell_swing',
    type: 'hinge',
    displayName: 'Kettlebell Swing',
    instructions:
        'Drive from hips, keep arms relaxed, and snap hips to chest height.',
    defaultWeight: '16kg kettlebell',
    landmarks: ['shoulder', 'hip', 'knee', 'ankle'],
  ),
  'bodyweight_squat': BackendExerciseConfig(
    key: 'bodyweight_squat',
    type: 'squat',
    displayName: 'Bodyweight Squat',
    instructions:
        'Sit hips back and down, keep knees tracking over toes, and stand tall.',
    defaultWeight: 'Bodyweight',
    landmarks: ['hip', 'knee', 'ankle', 'shoulder'],
  ),
  'leg_press_machine': BackendExerciseConfig(
    key: 'leg_press_machine',
    type: 'squat',
    displayName: 'Leg Press Machine',
    instructions:
        'Lower with control until knees are bent, then press back without locking hard.',
    defaultWeight: '60kg',
    landmarks: ['hip', 'knee', 'ankle'],
    machineMode: true,
  ),
  'lunge': BackendExerciseConfig(
    key: 'lunge',
    type: 'lunge',
    displayName: 'Alternating Lunge',
    instructions:
        'Step back, lower until front knee is near 90 degrees, then drive up.',
    defaultWeight: 'Bodyweight or 8kg dumbbells',
    landmarks: ['shoulder', 'hip', 'knee', 'ankle'],
  ),
  'pushup': BackendExerciseConfig(
    key: 'pushup',
    type: 'press',
    displayName: 'Push-Up',
    instructions:
        'Maintain a straight line from shoulders to ankles and press fully at top.',
    defaultWeight: 'Bodyweight',
    landmarks: ['shoulder', 'elbow', 'wrist', 'hip', 'ankle'],
  ),
  'chest_press_machine': BackendExerciseConfig(
    key: 'chest_press_machine',
    type: 'press',
    displayName: 'Chest Press Machine',
    instructions:
        'Press handles forward with control and avoid shrugging shoulders.',
    defaultWeight: '40kg',
    landmarks: ['shoulder', 'elbow', 'wrist'],
    machineMode: true,
  ),
  'lat_pulldown': BackendExerciseConfig(
    key: 'lat_pulldown',
    type: 'pull',
    displayName: 'Lat Pulldown',
    instructions:
        'Pull elbows down toward ribs, chest tall, and avoid excessive lean back.',
    defaultWeight: '35kg',
    landmarks: ['shoulder', 'elbow', 'wrist', 'hip'],
  ),
  'seated_row': BackendExerciseConfig(
    key: 'seated_row',
    type: 'pull',
    displayName: 'Seated Row',
    instructions:
        'Lead with elbows and keep torso stable while pulling to your midline.',
    defaultWeight: '30kg',
    landmarks: ['shoulder', 'elbow', 'wrist', 'hip'],
  ),
  'plank': BackendExerciseConfig(
    key: 'plank',
    type: 'hold',
    displayName: 'Plank Hold',
    instructions: 'Keep a straight body line, brace core, and avoid hip sag.',
    defaultWeight: 'Bodyweight',
    landmarks: ['shoulder', 'hip', 'ankle'],
  ),
  'wall_sit': BackendExerciseConfig(
    key: 'wall_sit',
    type: 'hold',
    displayName: 'Wall Sit',
    instructions:
        'Back against wall, knees around 90 degrees, and hold steady.',
    defaultWeight: 'Bodyweight',
    landmarks: ['hip', 'knee', 'ankle'],
  ),
};

final List<Exercise> backendSupportedExercises = backendExerciseKeyOrder
    .map(_exerciseForBackendKey)
    .whereType<Exercise>()
    .toList(growable: false);

final List<WorkoutDay> backendSupportedWorkoutPlan = [
  WorkoutDay(
    dayNumber: 1,
    title: 'Chest & Triceps',
    subtitle: 'Push strength and pressing control',
    durationMinutes: 35,
    exercises: _exercisesForKeys(['pushup', 'chest_press_machine']),
  ),
  WorkoutDay(
    dayNumber: 2,
    title: 'Back & Biceps',
    subtitle: 'Pull mechanics and arm control',
    durationMinutes: 45,
    exercises: _exercisesForKeys(['lat_pulldown', 'seated_row', 'bicep_curl']),
  ),
  WorkoutDay(
    dayNumber: 3,
    title: 'Legs & Glutes',
    subtitle: 'Squat, hinge, and unilateral stability',
    durationMinutes: 50,
    exercises: _exercisesForKeys(['bodyweight_squat', 'deadlift', 'lunge']),
  ),
  WorkoutDay(
    dayNumber: 4,
    title: 'Shoulders & Core',
    subtitle: 'Grip, brace, and isometric control',
    durationMinutes: 40,
    exercises: _exercisesForKeys(['hammer_curl', 'plank', 'wall_sit']),
  ),
  WorkoutDay(
    dayNumber: 5,
    title: 'Active Recovery',
    subtitle: 'Mobility-focused holds only',
    durationMinutes: 25,
    exercises: _exercisesForKeys(['plank', 'wall_sit']),
  ),
];

List<Exercise> _exercisesForKeys(List<String> keys) {
  return keys
      .map(_exerciseForBackendKey)
      .whereType<Exercise>()
      .toList(growable: false);
}

Exercise? _exerciseForBackendKey(String key) {
  final backendKey = mapExerciseName(key);
  if (backendKey.isEmpty) return null;

  final config = backendExerciseConfig[backendKey];
  if (config == null) {
    _logIgnoredExercise(
      key,
      reason: 'resolved key "$backendKey" is not in config',
    );
    return null;
  }

  return Exercise.fromConfig(config);
}

String? resolveExerciseKey(String uiName) {
  final normalized = uiName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  if (backendExerciseKeys.contains(normalized)) return normalized;

  for (final config in backendExerciseConfig.values) {
    final display = config.displayName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (display == normalized) return config.key;
  }

  return null;
}

String mapExerciseName(String uiName) {
  final key = resolveExerciseKey(uiName);
  if (key != null) return key;

  _logIgnoredExercise(uiName, reason: 'unable to resolve backend key');
  return '';
}

Exercise? tryNormalizeExerciseForBackend(Exercise exercise) {
  final rawName = exercise.name.isNotEmpty ? exercise.name : exercise.key;
  final backendKey =
      resolveExerciseKey(exercise.key) ?? resolveExerciseKey(exercise.name);
  if (backendKey == null) {
    _logIgnoredExercise(rawName, reason: 'unable to resolve backend key');
    return null;
  }

  final config = backendExerciseConfig[backendKey];
  if (config == null) {
    _logIgnoredExercise(
      rawName,
      reason: 'resolved key "$backendKey" is not in config',
    );
    return null;
  }

  return Exercise(
    key: backendKey,
    name: config.displayName,
    reps: exercise.reps.isNotEmpty
        ? exercise.reps
        : _defaultRepsForType(config.type),
    sets: exercise.sets > 0 ? exercise.sets : _defaultSetsForType(config.type),
    difficulty: exercise.difficulty.isNotEmpty
        ? exercise.difficulty
        : _defaultDifficultyForConfig(config),
    instructions: config.instructions,
    tips: exercise.tips.isNotEmpty ? exercise.tips : _tipsForConfig(config),
    type: config.type,
    defaultWeight: config.defaultWeight,
    landmarks: config.landmarks,
  );
}

Exercise normalizeExerciseForBackend(Exercise exercise) {
  final normalized = tryNormalizeExerciseForBackend(exercise);
  if (normalized != null) return normalized;

  throw ArgumentError.value(
    exercise.name.isNotEmpty ? exercise.name : exercise.key,
    'exercise',
    'Unsupported workout exercise. Expected a backend exercise key or display name.',
  );
}

BackendExerciseConfig? _configForInput(String input, {required String action}) {
  final backendKey = resolveExerciseKey(input);
  if (backendKey == null) {
    _logIgnoredExercise(
      input,
      reason: 'unable to resolve backend key; $action',
    );
    return null;
  }

  final config = backendExerciseConfig[backendKey];
  if (config == null) {
    _logIgnoredExercise(
      input,
      reason: 'resolved key "$backendKey" is not in config; $action',
    );
    return null;
  }

  return config;
}

void _logIgnoredExercise(String value, {required String reason}) {
  debugPrint('[WorkoutModels] Ignored exercise "$value": $reason.');
}

String _defaultRepsForType(String type) {
  return type == 'hold' ? '30-45 sec' : '8-12 reps';
}

int _defaultSetsForType(String type) {
  return type == 'hold' ? 3 : 4;
}

String _defaultDifficultyForConfig(BackendExerciseConfig config) {
  return config.machineMode ? 'Intermediate' : 'Beginner';
}

List<String> _tipsForConfig(BackendExerciseConfig config) {
  return [
    'Tracked by ${config.type} AI processor',
    'Landmarks: ${config.landmarks.join(', ')}',
  ];
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}

int _readInt(
  Map<String, dynamic> json,
  List<String> keys, {
  required int fallback,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}
