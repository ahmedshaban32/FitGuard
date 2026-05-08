import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fit_guard_app/core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/presentation/navigation/curved_bottom_nav.dart';
import 'package:fit_guard_app/presentation/screens/profile/data/profile_repo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserInfoScreen
// Shown right after signup. Collects fitness profile, food prefs, health info.
// On "Generate Plan" → saves to SharedPreferences → navigates to main nav.
// ─────────────────────────────────────────────────────────────────────────────

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // ── Step animation ─────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Profile values ─────────────────────────────────────────
  int _age = 25;
  int _height = 175;
  int _weight = 75;
  int _meals = 3;
  String _gender = 'Male';
  String _goal = 'Muscle Building';
  String _activityLevel = 'Moderate';

  // ── Food preferences ───────────────────────────────────────
  String _dietaryPreference = 'No restriction';
  final _dislikesCtrl = TextEditingController();

  // ── Health ─────────────────────────────────────────────────
  final _healthCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();

  // ── Submit state ───────────────────────────────────────────
  bool _submitting = false;

  // ── Options ────────────────────────────────────────────────
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

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    _dislikesCtrl.dispose();
    _healthCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }

  // ── Build payload ──────────────────────────────────────────

  Map<String, dynamic> _buildPayload() => {
    'profile': {
      'age': _age,
      'height_cm': _height,
      'weight_kg': _weight,
      'meals_per_day': _meals,
      'gender': _gender,
      'goal': _goal,
      'activity_level': _activityLevel,
    },
    'food_preferences': {
      'dietary_preference': _dietaryPreference,
      'food_dislikes': _dislikesCtrl.text.trim(),
    },
    'health': {
      'health_conditions': _healthCtrl.text.trim(),
      'allergies': _allergiesCtrl.text.trim(),
    },
  };

  // ── Submit ─────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final payload = _buildPayload();
    debugPrint(
      'USER INFO PAYLOAD:\n${const JsonEncoder.withIndent('  ').convert(payload)}',
    );

    try {
      final profile = ProfileModel(
        age: _age,
        heightCm: _height.toDouble(),
        weightKg: _weight.toDouble(),
        mealsPerDay: _meals,
        gender: _gender,
        goal: _goal,
        activityLevel: _activityLevel,
        dietaryPreference: _dietaryPreference,
        foodDislikes: _dislikesCtrl.text.trim(),
        healthConditions: _healthCtrl.text.trim(),
        allergies: _allergiesCtrl.text.trim(),
      );
      final saved = await ProfileRepo().updateProfile(profile);
      await PrefHelper.saveUserInfo(saved.toLocalUserInfoJson());
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CurvedBottomNav()),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            controller: _scrollCtrl,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Section 1: Profile ──────────────────
                    _SectionHeader(
                      icon: Icons.person_outline_rounded,
                      title: 'Your Profile',
                      subtitle: 'Basic body & fitness info',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    _buildProfileSection(),

                    const SizedBox(height: 28),

                    // ── Section 2: Food preferences ─────────
                    _SectionHeader(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Food Preferences',
                      subtitle: 'Help us personalise your meals',
                      color: AppColors.secondary,
                    ),
                    const SizedBox(height: 16),
                    _buildFoodSection(),

                    const SizedBox(height: 28),

                    // ── Section 3: Health ────────────────────
                    _SectionHeader(
                      icon: Icons.favorite_outline_rounded,
                      title: 'Health & Allergies',
                      subtitle: 'For your safety',
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    _buildHealthSection(),

                    const SizedBox(height: 36),

                    // ── Submit button ────────────────────────
                    _buildSubmitButton(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false,
      expandedHeight: 130,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.12),
                AppColors.background,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (r) =>
                    AppColors.primaryGradient.createShader(r),
                child: const Text(
                  'Build Your Plan',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tell us about yourself so we can personalise everything',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION 1 — PROFILE
  // ─────────────────────────────────────────────────────────────

  Widget _buildProfileSection() {
    return _Card(
      child: Column(
        children: [
          // ── Steppers row ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StepperField(
                  label: 'Age',
                  unit: 'yrs',
                  value: _age,
                  min: 10,
                  max: 100,
                  onChanged: (v) => setState(() => _age = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StepperField(
                  label: 'Height',
                  unit: 'cm',
                  value: _height,
                  min: 100,
                  max: 250,
                  onChanged: (v) => setState(() => _height = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StepperField(
                  label: 'Weight',
                  unit: 'kg',
                  value: _weight,
                  min: 30,
                  max: 300,
                  onChanged: (v) => setState(() => _weight = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StepperField(
                  label: 'Meals/day',
                  unit: 'meals',
                  value: _meals,
                  min: 1,
                  max: 8,
                  onChanged: (v) => setState(() => _meals = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _Divider(),

          // ── Gender ────────────────────────────────────────
          const SizedBox(height: 16),
          _FieldLabel(label: 'Gender'),
          const SizedBox(height: 10),
          Row(
            children: ['Male', 'Female'].map((g) {
              final selected = _gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: g == 'Male' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          g == 'Male'
                              ? Icons.male_rounded
                              : Icons.female_rounded,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          g,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          _Divider(),
          const SizedBox(height: 16),

          // ── Goal ──────────────────────────────────────────
          _FieldLabel(label: 'Fitness Goal'),
          const SizedBox(height: 10),
          _StyledDropdown<String>(
            value: _goal,
            items: _goals,
            onChanged: (v) => setState(() => _goal = v!),
            icon: Icons.flag_outlined,
          ),

          const SizedBox(height: 16),

          // ── Activity ──────────────────────────────────────
          _FieldLabel(label: 'Activity Level'),
          const SizedBox(height: 10),
          _StyledDropdown<String>(
            value: _activityLevel,
            items: _activities,
            onChanged: (v) => setState(() => _activityLevel = v!),
            icon: Icons.bolt_outlined,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION 2 — FOOD PREFERENCES
  // ─────────────────────────────────────────────────────────────

  Widget _buildFoodSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'Dietary Preference'),
          const SizedBox(height: 10),
          _StyledDropdown<String>(
            value: _dietaryPreference,
            items: _diets,
            onChanged: (v) => setState(() => _dietaryPreference = v!),
            icon: Icons.eco_outlined,
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Food Dislikes'),
          const SizedBox(height: 10),
          _MultilineField(
            controller: _dislikesCtrl,
            hint: 'e.g. liver, okra, mushrooms...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECTION 3 — HEALTH
  // ─────────────────────────────────────────────────────────────

  Widget _buildHealthSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'Health Conditions'),
          const SizedBox(height: 10),
          _MultilineField(
            controller: _healthCtrl,
            hint: 'e.g. diabetes, high blood pressure, knee injury...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Allergies'),
          const SizedBox(height: 10),
          _MultilineField(
            controller: _allergiesCtrl,
            hint: 'e.g. nuts, lactose, gluten, shellfish...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SUBMIT BUTTON
  // ─────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submitting ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: _submitting
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.5),
                    AppColors.secondary.withOpacity(0.5),
                  ],
                )
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _submitting
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Generate Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

// ── Card wrapper ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.border.withOpacity(0.5));
  }
}

// ── Stepper field (value ± buttons) ──────────────────────────────────────────

class _StepperField extends StatelessWidget {
  final String label;
  final String unit;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepperField({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Minus
              _StepBtn(
                icon: Icons.remove,
                onTap: value > min ? () => onChanged(value - 1) : null,
              ),

              // Value
              Column(
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              // Plus
              _StepBtn(
                icon: Icons.add,
                onTap: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          color: active ? AppColors.primary : AppColors.textTertiary,
          size: 16,
        ),
      ),
    );
  }
}

// ── Styled dropdown ───────────────────────────────────────────────────────────

class _StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final IconData icon;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: AppColors.primary.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.toString(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Multiline text field ──────────────────────────────────────────────────────

class _MultilineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _MultilineField({
    required this.controller,
    required this.hint,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        height: 1.5,
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 13,
          height: 1.5,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
