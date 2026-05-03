import 'package:fit_guard_app/presentation/screens/workouts/exercise_detail_screen.dart';
import 'package:fit_guard_app/presentation/screens/workouts/models/workout_models.dart';
import 'package:fit_guard_app/presentation/screens/workouts/widgets/workout_widgets.dart';
import 'package:flutter/material.dart';
import 'package:fit_guard_app/core/constants/app_colors.dart';

// ============================================================
// EXERCISE LIST SCREEN
// Backend integration point: GET /api/workout-days/{dayId}/exercises
// ============================================================
class ExerciseListScreen extends StatefulWidget {
  final WorkoutDay day;

  const ExerciseListScreen({super.key, required this.day});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _cardFades = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    for (int i = 0; i < widget.day.exercises.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _cardFades.add(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
      _cardControllers.add(ctrl);
    }
    _runStagger();
  }

  void _runStagger() async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i < _cardControllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) _cardControllers[i].forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildDayOverview()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildCard(index),
                    childCount: widget.day.exercises.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primary,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Day ${widget.day.dayNumber}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'EXERCISES',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.day.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.day.subtitle,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDayOverview() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.15),
              AppColors.secondary.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildOverviewStat(
              '${widget.day.exercises.length}',
              'Exercises',
              Icons.fitness_center,
              AppColors.primary,
            ),
            _buildVertDivider(),
            _buildOverviewStat(
              '${widget.day.durationMinutes}',
              'Minutes',
              Icons.timer_outlined,
              AppColors.secondary,
            ),
            _buildVertDivider(),
            _buildOverviewStat(
              '${widget.day.exercises.fold(0, (s, e) => s + e.sets)}',
              'Total Sets',
              Icons.repeat,
              AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildVertDivider() {
    return Container(width: 1, height: 40, color: AppColors.border);
  }

  Widget _buildCard(int index) {
    final exercise = widget.day.exercises[index];
    return FadeTransition(
      opacity: _cardFades[index],
      child: ExerciseCard(
        exercise: exercise,
        index: index,
        onTap: () => _navigateToDetail(exercise),
      ),
    );
  }

  void _navigateToDetail(Exercise exercise) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            ExerciseDetailScreen(exercise: exercise),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }
}
