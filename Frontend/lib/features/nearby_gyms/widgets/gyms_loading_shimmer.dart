import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class GymsLoadingShimmer extends StatefulWidget {
  const GymsLoadingShimmer({super.key});

  @override
  State<GymsLoadingShimmer> createState() => _GymsLoadingShimmerState();
}

class _GymsLoadingShimmerState extends State<GymsLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 210,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  height: 112,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _bar(width: double.infinity),
                      const SizedBox(height: 10),
                      _bar(width: 180),
                      const SizedBox(height: 10),
                      _bar(width: double.infinity, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar({required double width, double height = 16}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
