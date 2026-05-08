import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/presentation/screens/workouts/models/workout_models.dart';
import 'package:flutter/material.dart';

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
      case 'advanced':
      case 'hard':
        return AppColors.tagIntense;
      case 'intermediate':
      case 'medium':
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
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
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
    final disabled = onTap == null;
    final color = outlineColor ?? AppColors.primary;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: outlined || disabled ? null : AppColors.primaryGradient,
            color: outlined ? color.withOpacity(0.08) : null,
            borderRadius: BorderRadius.circular(16),
            border: outlined ? Border.all(color: color, width: 1.5) : null,
            boxShadow: outlined || disabled
                ? null
                : [
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
              Icon(icon, color: outlined ? color : Colors.white, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: outlined ? color : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

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
              _ExerciseIcon(index: index),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.type.isEmpty
                          ? exercise.instructions
                          : '${exercise.type.toUpperCase()} - ${exercise.instructions}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: StatChip(
                            icon: Icons.repeat,
                            label: '${exercise.sets} sets',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: StatChip(
                            icon: Icons.monitor_heart_outlined,
                            label: exercise.defaultWeight.isEmpty
                                ? exercise.reps
                                : exercise.defaultWeight,
                            color: AppColors.secondary,
                          ),
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

class _ExerciseIcon extends StatelessWidget {
  final int index;

  const _ExerciseIcon({required this.index});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: Colors.white,
            size: 20,
          ),
        ),
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
    );
  }
}
