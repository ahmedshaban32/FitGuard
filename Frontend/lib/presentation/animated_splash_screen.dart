import 'package:fit_guard_app/presentation/screens/auth/data/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';


class AnimatedSplashScreenWidget extends StatelessWidget {
  const AnimatedSplashScreenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Lottie.asset('assets/Running brains.json'),
      backgroundColor: const Color(0xFF1B1B1B),

      /// 🔥 التعديل المهم
      nextScreen: const AuthGate(),

      duration: 12000,
      splashIconSize: 300,
      splashTransition: SplashTransition.fadeTransition,
    );
  }
}
