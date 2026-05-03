import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:flutter/material.dart';
import 'package:fit_guard_app/presentation/navigation/curved_bottom_nav.dart';
import 'package:fit_guard_app/presentation/screens/auth/data/auth_repo.dart';
import 'package:fit_guard_app/presentation/screens/auth/view/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkAuth() async {
    final token = await PrefHelper.getToken();
    // فقط إذا كان token موجود وليس guest
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const CurvedBottomNav();
        }

        return const LoginScreenDark();
      },
    );
  }
}
