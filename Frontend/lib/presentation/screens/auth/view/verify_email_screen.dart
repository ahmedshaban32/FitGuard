// lib/presentation/screens/auth/view/verify_email_screen.dart

import 'package:flutter/material.dart';
import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/presentation/screens/auth/data/auth_repo.dart';
import 'package:fit_guard_app/presentation/navigation/curved_bottom_nav.dart';
import 'package:fit_guard_app/presentation/screens/auth/view/login_screen.dart';

/// Standalone screen called from deep link / email button.
/// Usage:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => VerifyEmailScreen(token: 'abc123'),
///   ));
class VerifyEmailScreen extends StatefulWidget {
  final String token;
  const VerifyEmailScreen({super.key, required this.token});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _repo = AuthRepo();

  // 'loading' | 'success' | 'error'
  String _state = 'loading';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    setState(() => _state = 'loading');
    try {
      await _repo.verifyEmail(widget.token);
      if (!mounted) return;
      setState(() => _state = 'success');

      // Brief pause so user sees the success state, then navigate home
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CurvedBottomNav()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = 'error';
        _errorMessage = e is ApiError ? e.message : 'Verification failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case 'loading':
        return _buildLoading();
      case 'success':
        return _buildSuccess();
      case 'error':
        return _buildError();
      default:
        return _buildLoading();
    }
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Verifying Your Email',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Please wait a moment...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 44,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Email Verified!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your account is now active. Redirecting you...',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cancel_rounded,
            color: AppColors.error,
            size: 44,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Verification Failed',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 32),

        // Retry button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _verify,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: const Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Go to login
        TextButton(
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreenDark()),
            (_) => false,
          ),
          child: const Text(
            'Go to Login',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
