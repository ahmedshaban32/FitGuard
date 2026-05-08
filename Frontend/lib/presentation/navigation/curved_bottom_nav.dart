import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:fit_guard_app/presentation/screens/home/home_screen.dart';
import 'package:fit_guard_app/presentation/screens/workouts/workout_plan_screen.dart';
import 'package:fit_guard_app/presentation/screens/nutriton/nutrition_screen.dart';
import 'package:fit_guard_app/presentation/screens/settings/settings_screen.dart';
import 'package:fit_guard_app/presentation/screens/profile/profile_screen.dart';

class CurvedBottomNav extends StatefulWidget {
  final int initialIndex;

  const CurvedBottomNav({super.key, this.initialIndex = 0});

  @override
  State<CurvedBottomNav> createState() => _CurvedBottomNavState();
}

class _CurvedBottomNavState extends State<CurvedBottomNav> {
  late int index;
  late List<Widget> screens;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;

    screens = [
      HomeScreenDark(
        onTabChange: (newIndex) {
          setState(() {
            index = newIndex;
          });
        },
      ),
      const WorkoutPlanScreen(),
      const NutritionScreen(),
      const SettingsScreen(),
      const ProfileScreen(),
    ];
  }

  final items = const <Widget>[
    Icon(Icons.home, size: 30, color: Colors.white),
    Icon(Icons.fitness_center, size: 30, color: Colors.white),
    Icon(Icons.apple_rounded, size: 30, color: Colors.white),
    Icon(Icons.settings, size: 30, color: Colors.white),
    Icon(Icons.person, size: 30, color: Colors.white),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: screens[index],

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 75,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      31,
                      96,
                      96,
                      129,
                    ).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color.fromARGB(
                        255,
                        224,
                        222,
                        222,
                      ).withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            CurvedNavigationBar(
              items: items,
              index: index,
              height: 75,
              color: Colors.transparent,
              backgroundColor: Colors.transparent,
              buttonBackgroundColor: Colors.blue.withOpacity(0.8),
              animationDuration: const Duration(milliseconds: 400),
              onTap: (newIndex) {
                setState(() => index = newIndex);
              },
            ),
          ],
        ),
      ),
    );
  }
}
