import 'package:flutter/material.dart';

import 'package:fit_guard_app/features/ai_coach/screens/ai_coach_chat_screen.dart';
import 'package:fit_guard_app/features/coach_chat/screens/coaches_screen.dart';
import 'package:fit_guard_app/features/food_scanner/screens/food_scanner_screen.dart';
import 'package:fit_guard_app/presentation/navigation/curved_bottom_nav.dart';
import 'package:fit_guard_app/presentation/animated_splash_screen.dart';
import 'package:fit_guard_app/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:fit_guard_app/features/nearby_gyms/screens/nearby_gyms_screen.dart';
import 'package:fit_guard_app/features/progress/screens/history_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/splash': (context) => const AnimatedSplashScreenWidget(),
    '/main': (context) => const CurvedBottomNav(),
    '/admin': (context) => const AdminDashboardScreen(),
    '/nearby-gyms': (context) => const NearbyGymsScreen(),
    '/ai-coach': (context) => const AiCoachChatScreen(),
    '/chatbot': (context) => const AiCoachChatScreen(),
    '/coaches': (context) => const CoachesScreen(),
    '/coach-conversations': (context) => const ConversationsScreen(),
    '/food-scanner': (context) => const FoodScannerScreen(),
    '/history': (context) => const HistoryScreen(),
  };
}
