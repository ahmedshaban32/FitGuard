import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/features/progress/models/workout_history_entry.dart';
import 'package:fit_guard_app/features/progress/services/progress_repository.dart';
import 'package:fit_guard_app/presentation/screens/workouts/exercise_list_screen.dart';
import 'package:fit_guard_app/presentation/screens/workouts/models/workout_models.dart';
import 'package:fit_guard_app/presentation/screens/workouts/widgets/workout_widgets.dart';
import 'package:flutter/material.dart';

class WorkoutPlanScreen extends StatefulWidget {
  final List<WorkoutDay> initialPlan;

  const WorkoutPlanScreen({super.key, this.initialPlan = const []});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerFade;

  final List<AnimationController> _cardControllers = [];
  final List<Animation<Offset>> _cardSlides = [];

  List<WorkoutDay> _workoutPlan = const [];
  bool _loadedRouteData = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _workoutPlan = _supportedOnly(widget.initialPlan);
    if (_workoutPlan.isEmpty) {
      _workoutPlan = backendSupportedWorkoutPlan;
    }
    _configureCardAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedRouteData) return;
    _loadedRouteData = true;

    final routePlan = _readRoutePlan();
    if (routePlan != null) {
      final supportedRoutePlan = _supportedOnly(routePlan);
      _workoutPlan = supportedRoutePlan.isEmpty
          ? backendSupportedWorkoutPlan
          : supportedRoutePlan;
      _configureCardAnimations();
    }
    _runEntranceAnimations();
  }

  List<WorkoutDay> _supportedOnly(List<WorkoutDay> days) {
    return days
        .map(
          (day) => WorkoutDay(
            dayNumber: day.dayNumber,
            title: day.title,
            subtitle: day.subtitle,
            durationMinutes: day.durationMinutes,
            exercises: day.exercises
                .map(tryNormalizeExerciseForBackend)
                .whereType<Exercise>()
                .toList(),
          ),
        )
        .where((day) => day.exercises.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _headerController.dispose();
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<WorkoutDay>? _readRoutePlan() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is List<WorkoutDay>) return args;
    if (args is List) {
      return args
          .whereType<Map>()
          .map((item) => WorkoutDay.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (args is Map) {
      final plan = args['workoutPlan'] ?? args['plan'] ?? args['days'];
      if (plan is List) {
        return plan
            .whereType<Map>()
            .map((item) => WorkoutDay.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    }
    return null;
  }

  void _configureCardAnimations() {
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    _cardControllers.clear();
    _cardSlides.clear();

    for (int i = 0; i < _workoutPlan.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      final slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
          );
      _cardControllers.add(controller);
      _cardSlides.add(slide);
    }
  }

  Future<void> _runEntranceAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _headerController.forward();
    for (final controller in _cardControllers) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _workoutPlan.isEmpty ? _buildEmptyState() : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildDayCard(index),
              childCount: _workoutPlan.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR PROGRAM',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Workout Plan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showCardioSheet,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Future<void> _showCardioSheet() async {
    final savedType = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddCardioSheet(onSave: _saveCardioEntry),
    );

    if (!mounted || savedType == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$savedType saved to history.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _saveCardioEntry(_CardioEntryDraft draft) async {
    final entry = WorkoutHistoryEntry(
      id: 'cardio-${DateTime.now().microsecondsSinceEpoch}',
      exerciseId: draft.type.toLowerCase().replaceAll(' ', '_'),
      exerciseName: draft.type,
      sessionAt: DateTime.now(),
      caloriesBurned: draft.calories,
      durationSeconds: draft.minutes * 60,
      mistakes: draft.distance.isEmpty
          ? const []
          : ['Distance: ${draft.distance} km'],
      type: WorkoutHistoryType.cardio,
      source: WorkoutHistorySource.cardio,
    );
    await ProgressRepository().saveSession(entry);
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('${_workoutPlan.length}', 'Days', AppColors.primary),
          _buildDivider(),
          _buildStat(
            '${_workoutPlan.fold<int>(0, (sum, d) => sum + d.exercises.length)}',
            'Exercises',
            AppColors.secondary,
          ),
          _buildDivider(),
          _buildStat(
            '${_workoutPlan.fold<int>(0, (sum, d) => sum + d.durationMinutes)} min',
            'Total',
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 32, color: AppColors.border);
  }

  Widget _buildDayCard(int index) {
    final day = _workoutPlan[index];
    return SlideTransition(
      position: _cardSlides[index],
      child: FadeTransition(
        opacity: _cardControllers[index],
        child: GestureDetector(
          onTap: () => _navigateToExerciseList(day),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: _DayCardContent(day: day, index: index),
          ),
        ),
      ),
    );
  }

  void _navigateToExerciseList(WorkoutDay day) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => ExerciseListScreen(day: day),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, color: AppColors.textTertiary, size: 64),
            SizedBox(height: 16),
            Text(
              'No workout plan yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Backend-supported AI exercises are ready to track.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardioEntryDraft {
  final String type;
  final int minutes;
  final int calories;
  final String distance;

  const _CardioEntryDraft({
    required this.type,
    required this.minutes,
    required this.calories,
    required this.distance,
  });
}

class _AddCardioSheet extends StatefulWidget {
  final Future<void> Function(_CardioEntryDraft draft) onSave;

  const _AddCardioSheet({required this.onSave});

  @override
  State<_AddCardioSheet> createState() => _AddCardioSheetState();
}

class _AddCardioSheetState extends State<_AddCardioSheet> {
  final TextEditingController _durationCtrl = TextEditingController();
  final TextEditingController _caloriesCtrl = TextEditingController();
  final TextEditingController _distanceCtrl = TextEditingController();

  String _type = 'Running';
  bool _saving = false;

  @override
  void dispose() {
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final minutes = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    final calories = int.tryParse(_caloriesCtrl.text.trim()) ?? 0;
    final distance = _distanceCtrl.text.trim();
    final type = _type;

    if (minutes <= 0 || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter duration and calories.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        _CardioEntryDraft(
          type: type,
          minutes: minutes,
          calories: calories,
          distance: distance,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(type);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        22,
        22,
        MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Cardio',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Cardio type'),
            items: const ['Running', 'Walking', 'Cycling', 'Jump rope']
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationCtrl,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Duration (minutes)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _caloriesCtrl,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Calories burned'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _distanceCtrl,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Distance km (optional)'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Cardio'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCardContent extends StatelessWidget {
  final WorkoutDay day;
  final int index;

  const _DayCardContent({required this.day, required this.index});

  Color get _accentColor {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
    ];
    return colors[index % colors.length];
  }

  String get _difficulty {
    if (day.exercises.isEmpty) return 'Beginner';
    final hasIntense = day.exercises.any(
      (exercise) => exercise.difficulty.toLowerCase() == 'intense',
    );
    if (hasIntense) return 'Intense';
    final hasIntermediate = day.exercises.any(
      (exercise) => exercise.difficulty.toLowerCase() == 'intermediate',
    );
    return hasIntermediate ? 'Intermediate' : day.exercises.first.difficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_accentColor, _accentColor.withValues(alpha: 0.3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAY ${day.dayNumber}',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Flexible(
                              child: StatChip(
                                icon: Icons.bolt,
                                label: '${day.exercises.length} exercises',
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: StatChip(
                                icon: Icons.timer_outlined,
                                label: '${day.durationMinutes} min',
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      DifficultyBadge(difficulty: _difficulty),
                      const SizedBox(height: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: _accentColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
