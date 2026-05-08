import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/core/constants/app_colors.dart';
import 'package:fit_guard_app/presentation/navigation/curved_bottom_nav.dart';
import 'package:fit_guard_app/presentation/screens/auth/data/auth_repo.dart';
import 'package:fit_guard_app/presentation/screens/auth/view/login_screen.dart';
import 'package:flutter/material.dart';

class SignupScreenDark extends StatefulWidget {
  const SignupScreenDark({super.key});

  @override
  State<SignupScreenDark> createState() => _SignupScreenDarkState();
}

class _SignupScreenDarkState extends State<SignupScreenDark> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final mealsController = TextEditingController(text: '3');

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  String _gender = 'Male';
  String _goal = 'Maintain';
  String _activityLevel = 'Moderate';
  String _dietaryPreference = 'No restriction';

  static const _genders = ['Male', 'Female'];
  static const _goals = ['Muscle Building', 'Weight Loss', 'Maintain'];
  static const _activities = [
    'Sedentary',
    'Light',
    'Moderate',
    'Active',
    'Very Active',
  ];
  static const _diets = [
    'No restriction',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Low-carb',
  ];

  final authRepo = AuthRepo();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    mealsController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    if (!formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      _showSnack('Please agree to Terms & Conditions', AppColors.warning);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    final profile = _buildProfilePayload();

    try {
      final user = await authRepo.signup(
        nameController.text.trim(),
        emailController.text.trim(),
        passController.text.trim(),
        profile,
      );

      if (user != null && mounted) {
        await PrefHelper.saveUser(
          name: user.name,
          email: user.email,
          token: user.token ?? '',
          image: user.image,
          role: user.role,
        );
        await PrefHelper.saveUserInfo(_buildLocalUserInfoPayload(profile));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CurvedBottomNav()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e is ApiError ? e.message : 'Signup failed', AppColors.error);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Map<String, dynamic> _buildProfilePayload() {
    return {
      'age': int.parse(ageController.text.trim()),
      'heightCm': double.parse(heightController.text.trim()),
      'weightKg': double.parse(weightController.text.trim()),
      'mealsPerDay': int.parse(mealsController.text.trim()),
      'gender': _gender,
      'goal': _goal,
      'activityLevel': _activityLevel,
      'dietaryPreference': _dietaryPreference,
      'foodDislikes': '',
      'healthConditions': '',
      'allergies': '',
    };
  }

  Map<String, dynamic> _buildLocalUserInfoPayload(Map<String, dynamic> profile) {
    return {
      'profile': {
        'age': profile['age'],
        'height_cm': (profile['heightCm'] as num).round(),
        'weight_kg': (profile['weightKg'] as num).round(),
        'meals_per_day': profile['mealsPerDay'],
        'gender': profile['gender'],
        'goal': profile['goal'],
        'activity_level': profile['activityLevel'],
      },
      'food_preferences': {
        'dietary_preference': profile['dietaryPreference'],
        'food_dislikes': profile['foodDislikes'],
      },
      'health': {
        'health_conditions': profile['healthConditions'],
        'allergies': profile['allergies'],
      },
    };
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildLogo(),
                const SizedBox(height: 48),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your fitness journey today with personalized workouts and nutrition plans.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  label: 'Full Name',
                  controller: nameController,
                  hint: 'John Doe',
                  icon: Icons.person_outline,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Name required'
                          : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Email',
                  controller: emailController,
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Email required';
                    if (!email.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 28),
                _buildProfileSection(),
                const SizedBox(height: 20),
                _buildTermsCheckbox(),
                const SizedBox(height: 32),
                _buildSignupButton(),
                const SizedBox(height: 32),
                _buildDividerText(),
                const SizedBox(height: 24),
                _buildSocialButtons(),
                const SizedBox(height: 32),
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'FitGuard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'These fields are required to create your AI fitness profile.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Age',
                controller: ageController,
                hint: '25',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (value) => _validateIntRange(value, 8, 110, 'Age'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Meals/day',
                controller: mealsController,
                hint: '3',
                icon: Icons.restaurant_outlined,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    _validateIntRange(value, 1, 12, 'Meals/day'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Height (cm)',
                controller: heightController,
                hint: '175',
                icon: Icons.height,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    _validateNumRange(value, 80, 260, 'Height'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'Weight (kg)',
                controller: weightController,
                hint: '75',
                icon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) =>
                    _validateNumRange(value, 20, 350, 'Weight'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Gender',
          value: _gender,
          items: _genders,
          icon: Icons.person_outline,
          onChanged: (value) => setState(() => _gender = value),
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Goal',
          value: _goal,
          items: _goals,
          icon: Icons.flag_outlined,
          onChanged: (value) => setState(() => _goal = value),
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Activity Level',
          value: _activityLevel,
          items: _activities,
          icon: Icons.directions_run_outlined,
          onChanged: (value) => setState(() => _activityLevel = value),
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Dietary Preference',
          value: _dietaryPreference,
          items: _diets,
          icon: Icons.eco_outlined,
          onChanged: (value) => setState(() => _dietaryPreference = value),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: TextFormField(
            controller: passController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: AppColors.textSecondary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password required';
              if (value.length < 8) return 'Min 8 characters';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.cardBackground,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() => _agreeToTerms = value ?? false);
            },
            activeColor: AppColors.primary,
            side: BorderSide(color: AppColors.border, width: 2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              children: const [
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : signup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildDividerText() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: Icons.g_mobiledata,
            label: 'Google',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.apple,
            label: 'Apple',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreenDark()),
            );
          },
          child: const Text(
            'Login',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateIntRange(
    String? value,
    int min,
    int max,
    String label,
  ) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) return '$label must be a whole number';
    if (parsed < min || parsed > max) {
      return '$label must be between $min and $max';
    }
    return null;
  }

  String? _validateNumRange(
    String? value,
    num min,
    num max,
    String label,
  ) {
    final parsed = num.tryParse(value?.trim() ?? '');
    if (parsed == null) return '$label must be a number';
    if (parsed < min || parsed > max) {
      return '$label must be between $min and $max';
    }
    return null;
  }
}
