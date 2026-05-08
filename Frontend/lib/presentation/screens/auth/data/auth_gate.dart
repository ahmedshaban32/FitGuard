import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/presentation/navigation/curved_bottom_nav.dart';
import 'package:fit_guard_app/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:fit_guard_app/presentation/screens/auth/view/login_screen.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> _checkAuthRole() async {
    final token = await PrefHelper.getToken();
    if (token == null || token.isEmpty || token == 'guest') return null;
    return PrefHelper.getUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _checkAuthRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == 'admin') {
          return const AdminDashboardScreen();
        }

        if (snapshot.data != null) {
          return const CurvedBottomNav();
        }

        return const LoginScreenDark();
      },
    );
  }
}
