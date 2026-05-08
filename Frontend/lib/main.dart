import 'package:fit_guard_app/Core/routes/app_routes.dart';
import 'package:fit_guard_app/presentation/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Features that require API keys show setup guidance if .env is absent.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
      home: const AnimatedSplashScreenWidget(),
    );
  }
}
