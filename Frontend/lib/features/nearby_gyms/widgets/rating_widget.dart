import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int totalReviews;

  const RatingWidget({
    super.key,
    required this.rating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) {
      return const Text(
        'No ratings yet',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          final icon = rating >= starValue
              ? Icons.star_rounded
              : rating >= starValue - 0.5
              ? Icons.star_half_rounded
              : Icons.star_border_rounded;
          return Icon(icon, color: AppColors.warning, size: 16);
        }),
        const SizedBox(width: 6),
        Text(
          '${rating.toStringAsFixed(1)} ($totalReviews)',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
