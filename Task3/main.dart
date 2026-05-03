import 'package:fit_guard_app/Core/routes/app_routes.dart';
import 'package:fit_guard_app/presentation/animated_splash_screen.dart';
import 'package:fit_guard_app/presentation/screens/chatbot/chatbot_screen.dart';
import 'package:flutter/material.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/navigation/curved_bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnimatedSplashScreenWidget(), // 👈 أول حاجة
    );
  }
}

// import 'package:fit_guard_app/Core/routes/app_routes.dart';
// import 'package:fit_guard_app/presentation/animated_splash_screen.dart';
// import 'package:fit_guard_app/presentation/screens/chatbot/chatbot_screen.dart';
// import 'package:flutter/material.dart';
// import 'presentation/screens/home/home_screen.dart';
// import 'presentation/navigation/curved_bottom_nav.dart';
// // 1. ضفنا الـ import بتاع الشاشة الجديدة هنا أهو:
// import 'test_upload.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // 2. شيلنا كلمة const من هنا
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       // 3. وقفنا شاشتك القديمة مؤقتاً
//       // home: AnimatedSplashScreenWidget(), // أول حاجة
//       // 4. شغلنا شاشة التست بتاعتنا
//       home: TestUploadScreen(),
//     );
//   }
// }
