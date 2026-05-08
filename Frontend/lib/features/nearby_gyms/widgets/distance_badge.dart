import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class DistanceBadge extends StatelessWidget {
  final double distanceKm;

  const DistanceBadge({super.key, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me, color: AppColors.primary, size: 14),
          const SizedBox(width: 4),
          Text(
            '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
