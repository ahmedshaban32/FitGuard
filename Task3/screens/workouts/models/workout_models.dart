// ============================================================
// MODELS — ready for backend integration
// Replace mock data with API responses when backend is ready
// ============================================================

class WorkoutDay {
  final String id;
  final String title;
  final String subtitle;
  final int dayNumber;
  final List<Exercise> exercises;
  final String difficulty; // 'Beginner' | 'Intermediate' | 'Intense'
  final int durationMinutes;
  final String focusArea;

  const WorkoutDay({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.dayNumber,
    required this.exercises,
    required this.difficulty,
    required this.durationMinutes,
    required this.focusArea,
  });
}

class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  final String muscleGroup;
  final int sets;
  final String reps;
  final String description;
  final String instructions;
  final String difficulty;
  final int restSeconds;
  final List<String> tips;

  const Exercise({
    required this.id,
    required this.name,
    required this.targetMuscle,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.description,
    required this.instructions,
    required this.difficulty,
    required this.restSeconds,
    required this.tips,
  });
}

// ============================================================
// MOCK DATA — replace with API call: GET /api/workout-plan
// ============================================================
final List<WorkoutDay> mockWorkoutPlan = [
  WorkoutDay(
    id: 'day-1',
    title: 'Chest & Triceps',
    subtitle: 'Upper body power',
    dayNumber: 1,
    difficulty: 'Intermediate',
    durationMinutes: 55,
    focusArea: 'Push',
    exercises: [
      Exercise(
        id: 'ex-1',
        name: 'Barbell Bench Press',
        targetMuscle: 'Pectoralis Major',
        muscleGroup: 'Chest',
        sets: 4,
        reps: '8-10',
        difficulty: 'Intermediate',
        restSeconds: 90,
        description:
            'The king of chest exercises. Develops overall chest thickness and strength with compound movement.',
        instructions:
            'Lie flat on bench, grip bar slightly wider than shoulder-width, lower to chest with control, press explosively.',
        tips: [
          'Keep shoulder blades retracted',
          'Drive feet into the floor',
          'Full range of motion',
        ],
      ),
      Exercise(
        id: 'ex-2',
        name: 'Incline Dumbbell Press',
        targetMuscle: 'Upper Pectoralis',
        muscleGroup: 'Chest',
        sets: 3,
        reps: '10-12',
        difficulty: 'Intermediate',
        restSeconds: 75,
        description:
            'Targets the upper chest for a fuller, rounder appearance. Essential for complete chest development.',
        instructions:
            'Set bench to 30-45°, press dumbbells from shoulder level to full extension, control the descent.',
        tips: [
          'Do not flare elbows excessively',
          'Slight arch in lower back',
          'Squeeze at the top',
        ],
      ),
      Exercise(
        id: 'ex-3',
        name: 'Cable Flyes',
        targetMuscle: 'Pectoralis Minor',
        muscleGroup: 'Chest',
        sets: 3,
        reps: '12-15',
        difficulty: 'Beginner',
        restSeconds: 60,
        description:
            'Isolation movement for chest definition and squeeze. Constant tension throughout the movement.',
        instructions:
            'Set cables at shoulder height, step forward, bring hands together in hugging motion.',
        tips: [
          'Slight bend in elbows throughout',
          'Focus on the chest squeeze',
          'Control the return phase',
        ],
      ),
      Exercise(
        id: 'ex-4',
        name: 'Tricep Pushdowns',
        targetMuscle: 'Triceps Brachii',
        muscleGroup: 'Triceps',
        sets: 4,
        reps: '12-15',
        difficulty: 'Beginner',
        restSeconds: 60,
        description:
            'Primary tricep isolation exercise. Develops the long and lateral heads of the triceps.',
        instructions:
            'Grip rope/bar at chest level, keep elbows pinned to sides, push down to full extension.',
        tips: [
          'Keep elbows stationary',
          'Full lockout at bottom',
          'Slow eccentric phase',
        ],
      ),
    ],
  ),
  WorkoutDay(
    id: 'day-2',
    title: 'Back & Biceps',
    subtitle: 'Pull strength & width',
    dayNumber: 2,
    difficulty: 'Intense',
    durationMinutes: 65,
    focusArea: 'Pull',
    exercises: [
      Exercise(
        id: 'ex-5',
        name: 'Deadlift',
        targetMuscle: 'Erector Spinae',
        muscleGroup: 'Back',
        sets: 4,
        reps: '5-6',
        difficulty: 'Intense',
        restSeconds: 120,
        description:
            'The ultimate full-body strength builder. Engages virtually every muscle from head to toe.',
        instructions:
            'Hip-width stance, hinge at hips, maintain neutral spine, drive through heels to lockout.',
        tips: [
          'Bar stays close to body',
          'Engage lats before lifting',
          'Drive hips forward at top',
        ],
      ),
      Exercise(
        id: 'ex-6',
        name: 'Pull-Ups',
        targetMuscle: 'Latissimus Dorsi',
        muscleGroup: 'Back',
        sets: 4,
        reps: '6-10',
        difficulty: 'Intermediate',
        restSeconds: 90,
        description:
            'King of back exercises. Develops lat width and overall upper body pulling strength.',
        instructions:
            'Hang from bar with pronated grip, pull chest to bar while squeezing lats, lower with control.',
        tips: [
          'Depress shoulders before pulling',
          'Lead with elbows, not hands',
          'Avoid kipping for strength gains',
        ],
      ),
      Exercise(
        id: 'ex-7',
        name: 'Barbell Curl',
        targetMuscle: 'Biceps Brachii',
        muscleGroup: 'Biceps',
        sets: 3,
        reps: '10-12',
        difficulty: 'Beginner',
        restSeconds: 60,
        description:
            'Classic mass builder for biceps. Develops peak and overall arm size.',
        instructions:
            'Stand with feet shoulder-width, curl bar from hip to shoulder level, squeeze at top.',
        tips: [
          'Keep elbows pinned to torso',
          'No body swing or momentum',
          'Full supination at top',
        ],
      ),
    ],
  ),
  WorkoutDay(
    id: 'day-3',
    title: 'Legs & Glutes',
    subtitle: 'Lower body dominance',
    dayNumber: 3,
    difficulty: 'Intense',
    durationMinutes: 70,
    focusArea: 'Legs',
    exercises: [
      Exercise(
        id: 'ex-8',
        name: 'Back Squat',
        targetMuscle: 'Quadriceps',
        muscleGroup: 'Legs',
        sets: 5,
        reps: '5-8',
        difficulty: 'Intense',
        restSeconds: 120,
        description:
            'The foundational lower body compound. Builds overall leg mass and functional strength.',
        instructions:
            'Bar on upper traps, feet shoulder-width, descend until thighs parallel, drive through heels.',
        tips: [
          'Knees track over toes',
          'Chest tall throughout',
          'Brace core before descent',
        ],
      ),
      Exercise(
        id: 'ex-9',
        name: 'Romanian Deadlift',
        targetMuscle: 'Hamstrings',
        muscleGroup: 'Legs',
        sets: 4,
        reps: '10-12',
        difficulty: 'Intermediate',
        restSeconds: 90,
        description:
            'Posterior chain developer. Builds hamstring length and glute strength simultaneously.',
        instructions:
            'Hold bar at hips, hinge forward keeping back flat, feel hamstring stretch, drive hips to return.',
        tips: [
          'Soft bend in knees throughout',
          'Bar stays close to legs',
          'Feel the stretch, not pain',
        ],
      ),
    ],
  ),
  WorkoutDay(
    id: 'day-4',
    title: 'Shoulders & Core',
    subtitle: 'Stability & definition',
    dayNumber: 4,
    difficulty: 'Intermediate',
    durationMinutes: 50,
    focusArea: 'Shoulders',
    exercises: [
      Exercise(
        id: 'ex-10',
        name: 'Overhead Press',
        targetMuscle: 'Anterior Deltoid',
        muscleGroup: 'Shoulders',
        sets: 4,
        reps: '8-10',
        difficulty: 'Intermediate',
        restSeconds: 90,
        description:
            'The premier shoulder pressing movement. Develops strength and mass across all deltoid heads.',
        instructions:
            'Barbell at clavicle level, brace core, press overhead to full lockout, lower with control.',
        tips: [
          'Slight backward lean at top',
          'Bar path slightly back over head',
          'Full lockout for strength gains',
        ],
      ),
      Exercise(
        id: 'ex-11',
        name: 'Lateral Raises',
        targetMuscle: 'Medial Deltoid',
        muscleGroup: 'Shoulders',
        sets: 4,
        reps: '15-20',
        difficulty: 'Beginner',
        restSeconds: 45,
        description:
            'Isolation for shoulder width. The medial deltoid is key for that capped, athletic look.',
        instructions:
            'Hold dumbbells at sides, raise to shoulder height with slight forward lean, control descent.',
        tips: [
          'Lead with pinkies',
          'Do not shrug at top',
          'Slow and controlled beats heavy and sloppy',
        ],
      ),
    ],
  ),
  WorkoutDay(
    id: 'day-5',
    title: 'Active Recovery',
    subtitle: 'Mobility & flexibility',
    dayNumber: 5,
    difficulty: 'Beginner',
    durationMinutes: 35,
    focusArea: 'Recovery',
    exercises: [
      Exercise(
        id: 'ex-12',
        name: 'Hip Flexor Stretch',
        targetMuscle: 'Iliopsoas',
        muscleGroup: 'Core',
        sets: 3,
        reps: '45 sec',
        difficulty: 'Beginner',
        restSeconds: 30,
        description:
            'Essential mobility work for athletes who sit frequently. Opens up the hip flexors for better performance.',
        instructions:
            'Kneel on one knee, push hips forward gently, hold stretch, switch sides.',
        tips: [
          'Do not arch lower back',
          'Engage glute of kneeling leg',
          'Breathe deeply and relax into stretch',
        ],
      ),
    ],
  ),
];
