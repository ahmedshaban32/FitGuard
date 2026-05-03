import 'package:flutter/material.dart';
import '../models/workout_models.dart';
import 'package:fit_guard_app/core/constants/app_colors.dart';

// ============================================================
// DIFFICULTY BADGE
// ============================================================
class DifficultyBadge extends StatelessWidget {
  final String difficulty;
  final bool small;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.small = false,
  });

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'intense':
        return AppColors.tagIntense;
      case 'intermediate':
        return AppColors.tagIntermediate;
      default:
        return AppColors.tagBeginner;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ============================================================
// STAT CHIP — small info pill
// ============================================================
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ============================================================
// MUSCLE GROUP ICON
// ============================================================
class MuscleGroupIcon extends StatelessWidget {
  final String group;

  const MuscleGroupIcon({super.key, required this.group});

  IconData get _icon {
    switch (group.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.arrow_upward;
      case 'legs':
        return Icons.directions_run;
      case 'shoulders':
        return Icons.accessibility_new;
      case 'biceps':
      case 'triceps':
        return Icons.sports_handball;
      case 'core':
        return Icons.circle_outlined;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_icon, color: Colors.white, size: 20),
    );
  }
}

// ============================================================
// GRADIENT ACTION BUTTON
// ============================================================
class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outlined;
  final Color? outlineColor;

  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.outlined = false,
    this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: outlineColor ?? AppColors.primary,
              width: 1.5,
            ),
            color: (outlineColor ?? AppColors.primary).withOpacity(0.08),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: outlineColor ?? AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: outlineColor ?? AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PLACEHOLDER PANEL — for video/camera/results areas
// ============================================================
class PlaceholderPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final double height;

  const PlaceholderPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
      ),
      child: Stack(
        children: [
          // Grid pattern background
          CustomPaint(
            painter: _GridPainter(accentColor.withOpacity(0.05)),
            size: Size.infinite,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ============================================================
// SECTION HEADER
// ============================================================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ============================================================
// EXERCISE CARD — used in Exercise List Screen
// ============================================================
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final int index;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Index + muscle icon
              Stack(
                children: [
                  MuscleGroupIcon(group: exercise.muscleGroup),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.targetMuscle,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatChip(
                          icon: Icons.repeat,
                          label: '${exercise.sets} sets',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        StatChip(
                          icon: Icons.loop,
                          label: '${exercise.reps} reps',
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  DifficultyBadge(difficulty: exercise.difficulty, small: true),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textTertiary,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
