import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/features/nearby_gyms/models/gym_model.dart';
import 'package:fit_guard_app/features/nearby_gyms/widgets/distance_badge.dart';
import 'package:fit_guard_app/features/nearby_gyms/widgets/rating_widget.dart';
import 'package:flutter/material.dart';

class GymCard extends StatelessWidget {
  final Gym gym;
  final bool focused;
  final VoidCallback onTap;
  final VoidCallback onOpenMaps;

  const GymCard({
    super.key,
    required this.gym,
    required this.focused,
    required this.onTap,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focused ? AppColors.secondary : AppColors.border,
          width: focused ? 1.6 : 1,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: _GymImage(imageUrl: gym.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          gym.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      DistanceBadge(distanceKm: gym.distanceKm),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RatingWidget(
                    rating: gym.rating,
                    totalReviews: gym.totalReviews,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    gym.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _OpenStatus(openNow: gym.openNow),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onOpenMaps,
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Open in Maps'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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

class _GymImage extends StatelessWidget {
  final String? imageUrl;

  const _GymImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: 132,
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Icon(Icons.fitness_center, color: Colors.white, size: 42),
      );
    }

    return Image.network(
      imageUrl!,
      height: 132,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 132,
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Icon(Icons.fitness_center, color: Colors.white, size: 42),
      ),
    );
  }
}

class _OpenStatus extends StatelessWidget {
  final bool? openNow;

  const _OpenStatus({this.openNow});

  @override
  Widget build(BuildContext context) {
    final color = openNow == null
        ? AppColors.textSecondary
        : openNow!
        ? AppColors.success
        : AppColors.error;
    final label = openNow == null
        ? 'Hours unknown'
        : openNow!
        ? 'Open now'
        : 'Closed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
