import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fit_guard_app/core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/presentation/navigation/curved_bottom_nav.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // ── Animation Controllers ──
  late AnimationController _progressController;
  late AnimationController _slideController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  // ── Form Data ──
  // Page 1 – Body Metrics
  String _selectedGender = '';
  int _age = 25;
  double _heightCm = 170;
  double _weightKg = 70;

  // Page 2 – Fitness Goal
  String _selectedGoal = '';

  // Page 3 – Activity Level
  String _selectedActivity = '';

  // Page 4 – Target & Preferences
  double _targetWeightKg = 65;
  int _weeklyWorkouts = 3;
  String _selectedEquipment = '';

  // Page 5 – Health Info
  bool _hasHeartCondition = false;
  bool _hasDiabetes = false;
  bool _hasJointIssues = false;
  bool _hasHypertension = false;
  String _fitnessExperience = '';

  final int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1 / _totalPages)
        .animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
        );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _progressController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (!_validateCurrentPage()) return;

    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      _progressController.animateTo(
        (_currentPage + 1) / _totalPages,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );

      HapticFeedback.lightImpact();
    } else {
      _saveAndContinue();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _progressController.animateTo(
        _currentPage / _totalPages,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
      HapticFeedback.selectionClick();
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        if (_selectedGender.isEmpty) {
          _showError('Please select your gender');
          return false;
        }
        return true;
      case 1:
        if (_selectedGoal.isEmpty) {
          _showError('Please select your fitness goal');
          return false;
        }
        return true;
      case 2:
        if (_selectedActivity.isEmpty) {
          _showError('Please select your activity level');
          return false;
        }
        return true;
      case 3:
        if (_selectedEquipment.isEmpty) {
          _showError('Please select equipment availability');
          return false;
        }
        return true;
      case 4:
        if (_fitnessExperience.isEmpty) {
          _showError('Please select your experience level');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    HapticFeedback.vibrate();
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);
    try {
      await PrefHelper.saveUserInfo(
        gender: _selectedGender,
        age: _age,
        heightCm: _heightCm,
        weightKg: _weightKg,
        targetWeightKg: _targetWeightKg,
        fitnessGoal: _selectedGoal,
        activityLevel: _selectedActivity,
        weeklyWorkouts: _weeklyWorkouts,
        equipment: _selectedEquipment,
        experience: _fitnessExperience,
        hasHeartCondition: _hasHeartCondition,
        hasDiabetes: _hasDiabetes,
        hasJointIssues: _hasJointIssues,
        hasHypertension: _hasHypertension,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CurvedBottomNav()),
      );
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + step indicator
                  Row(
                    children: [
                      if (_currentPage > 0)
                        GestureDetector(
                          onTap: _goToPreviousPage,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 40),

                      const Spacer(),

                      // Step counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Step ${_currentPage + 1} of $_totalPages',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (_, __) => LinearProgressIndicator(
                        value: (_currentPage + 1) / _totalPages,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _totalPages,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _currentPage ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Pages ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1BodyMetrics(),
                  _buildPage2FitnessGoal(),
                  _buildPage3ActivityLevel(),
                  _buildPage4TargetPreferences(),
                  _buildPage5HealthInfo(),
                ],
              ),
            ),

            // ── Bottom Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _goToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _totalPages - 1
                                  ? 'Get Started!'
                                  : 'Continue',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _totalPages - 1
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════
  // PAGE 1 — Body Metrics
  // ════════════════════════════════════════
  Widget _buildPage1BodyMetrics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.person_outline_rounded,
            title: 'Body Metrics',
            subtitle: 'Help us personalize your experience',
          ),

          const SizedBox(height: 28),

          // Gender
          const _SectionLabel(label: 'Gender'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SelectionCard(
                  icon: Icons.male_rounded,
                  label: 'Male',
                  isSelected: _selectedGender == 'male',
                  onTap: () => setState(() => _selectedGender = 'male'),
                  iconColor: const Color(0xFF42A5F5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectionCard(
                  icon: Icons.female_rounded,
                  label: 'Female',
                  isSelected: _selectedGender == 'female',
                  onTap: () => setState(() => _selectedGender = 'female'),
                  iconColor: const Color(0xFFEC407A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectionCard(
                  icon: Icons.transgender_rounded,
                  label: 'Other',
                  isSelected: _selectedGender == 'other',
                  onTap: () => setState(() => _selectedGender = 'other'),
                  iconColor: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Age Slider
          _SliderField(
            label: 'Age',
            value: _age.toDouble(),
            min: 10,
            max: 90,
            unit: 'yrs',
            displayValue: '$_age',
            divisions: 80,
            onChanged: (v) => setState(() => _age = v.round()),
          ),

          const SizedBox(height: 20),

          // Height Slider
          _SliderField(
            label: 'Height',
            value: _heightCm,
            min: 100,
            max: 230,
            unit: 'cm',
            displayValue: '${_heightCm.round()}',
            divisions: 130,
            onChanged: (v) => setState(() => _heightCm = v),
          ),

          const SizedBox(height: 20),

          // Weight Slider
          _SliderField(
            label: 'Weight',
            value: _weightKg,
            min: 30,
            max: 200,
            unit: 'kg',
            displayValue: _weightKg.toStringAsFixed(1),
            divisions: 170,
            onChanged: (v) => setState(() => _weightKg = v),
          ),

          const SizedBox(height: 20),

          // BMI Display
          _BmiCard(heightCm: _heightCm, weightKg: _weightKg),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // PAGE 2 — Fitness Goal
  // ════════════════════════════════════════
  Widget _buildPage2FitnessGoal() {
    final goals = [
      {
        'id': 'lose_weight',
        'icon': Icons.trending_down_rounded,
        'label': 'Lose Weight',
        'desc': 'Burn fat and get lean',
        'color': 0xFFFF6B6B,
      },
      {
        'id': 'build_muscle',
        'icon': Icons.fitness_center_rounded,
        'label': 'Build Muscle',
        'desc': 'Gain strength & size',
        'color': 0xFF9B5DE5,
      },
      {
        'id': 'improve_endurance',
        'icon': Icons.directions_run_rounded,
        'label': 'Improve Endurance',
        'desc': 'Run further, train harder',
        'color': 0xFF00D9FF,
      },
      {
        'id': 'stay_active',
        'icon': Icons.self_improvement_rounded,
        'label': 'Stay Active',
        'desc': 'Maintain a healthy lifestyle',
        'color': 0xFF00D9A0,
      },
      {
        'id': 'flexibility',
        'icon': Icons.sports_gymnastics_rounded,
        'label': 'Flexibility & Mobility',
        'desc': 'Stretch, balance & move freely',
        'color': 0xFFF4A538,
      },
      {
        'id': 'sport_performance',
        'icon': Icons.sports_soccer_rounded,
        'label': 'Sport Performance',
        'desc': 'Peak performance for your sport',
        'color': 0xFF42A5F5,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.flag_outlined,
            title: 'Your Fitness Goal',
            subtitle: 'What are you working towards?',
          ),
          const SizedBox(height: 28),
          ...goals.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalCard(
                icon: g['icon'] as IconData,
                label: g['label'] as String,
                desc: g['desc'] as String,
                color: Color(g['color'] as int),
                isSelected: _selectedGoal == g['id'] as String,
                onTap: () => setState(() => _selectedGoal = g['id'] as String),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // PAGE 3 — Activity Level
  // ════════════════════════════════════════
  Widget _buildPage3ActivityLevel() {
    final levels = [
      {
        'id': 'sedentary',
        'icon': Icons.chair_outlined,
        'label': 'Sedentary',
        'desc': 'Little or no exercise, desk job',
        'color': 0xFFB0B3C1,
        'emoji': '🪑',
      },
      {
        'id': 'light',
        'icon': Icons.directions_walk_rounded,
        'label': 'Lightly Active',
        'desc': '1–3 workouts per week',
        'color': 0xFF00D9A0,
        'emoji': '🚶',
      },
      {
        'id': 'moderate',
        'icon': Icons.directions_bike_rounded,
        'label': 'Moderately Active',
        'desc': '3–5 workouts per week',
        'color': 0xFF00D9FF,
        'emoji': '🚴',
      },
      {
        'id': 'very_active',
        'icon': Icons.fitness_center_rounded,
        'label': 'Very Active',
        'desc': '6–7 intense workouts/week',
        'color': 0xFF9B5DE5,
        'emoji': '🏋️',
      },
      {
        'id': 'athlete',
        'icon': Icons.emoji_events_rounded,
        'label': 'Athlete',
        'desc': 'Professional or competitive level',
        'color': 0xFFF4A538,
        'emoji': '🏆',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.bolt_rounded,
            title: 'Activity Level',
            subtitle: 'How active are you currently?',
          ),
          const SizedBox(height: 28),
          ...levels.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ActivityCard(
                icon: l['icon'] as IconData,
                emoji: l['emoji'] as String,
                label: l['label'] as String,
                desc: l['desc'] as String,
                color: Color(l['color'] as int),
                isSelected: _selectedActivity == l['id'] as String,
                onTap: () =>
                    setState(() => _selectedActivity = l['id'] as String),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // PAGE 4 — Target & Preferences
  // ════════════════════════════════════════
  Widget _buildPage4TargetPreferences() {
    final equipmentOptions = [
      {
        'id': 'none',
        'icon': Icons.home_rounded,
        'label': 'No Equipment',
        'desc': 'Bodyweight workouts only',
        'color': 0xFF00D9A0,
      },
      {
        'id': 'minimal',
        'icon': Icons.fitness_center_outlined,
        'label': 'Minimal Equipment',
        'desc': 'Dumbbells, resistance bands',
        'color': 0xFF00D9FF,
      },
      {
        'id': 'full_gym',
        'icon': Icons.sports_gymnastics_rounded,
        'label': 'Full Gym Access',
        'desc': 'All machines & free weights',
        'color': 0xFF9B5DE5,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.tune_rounded,
            title: 'Targets & Preferences',
            subtitle: 'Fine-tune your fitness plan',
          ),

          const SizedBox(height: 28),

          // Target Weight
          _SliderField(
            label: 'Target Weight',
            value: _targetWeightKg,
            min: 30,
            max: 200,
            unit: 'kg',
            displayValue: _targetWeightKg.toStringAsFixed(1),
            divisions: 170,
            onChanged: (v) => setState(() => _targetWeightKg = v),
            accentColor: AppColors.success,
          ),

          const SizedBox(height: 24),

          // Weekly Workouts
          _SliderField(
            label: 'Weekly Workouts',
            value: _weeklyWorkouts.toDouble(),
            min: 1,
            max: 7,
            unit: 'days/wk',
            displayValue: '$_weeklyWorkouts',
            divisions: 6,
            onChanged: (v) => setState(() => _weeklyWorkouts = v.round()),
            accentColor: const Color(0xFF00D9FF),
          ),

          const SizedBox(height: 24),

          // Equipment
          const _SectionLabel(label: 'Equipment Availability'),
          const SizedBox(height: 12),
          ...equipmentOptions.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GoalCard(
                icon: e['icon'] as IconData,
                label: e['label'] as String,
                desc: e['desc'] as String,
                color: Color(e['color'] as int),
                isSelected: _selectedEquipment == e['id'] as String,
                onTap: () =>
                    setState(() => _selectedEquipment = e['id'] as String),
                compact: true,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // PAGE 5 — Health Info
  // ════════════════════════════════════════
  Widget _buildPage5HealthInfo() {
    final experienceLevels = [
      {'id': 'beginner', 'label': 'Beginner', 'desc': 'Less than 6 months'},
      {
        'id': 'intermediate',
        'label': 'Intermediate',
        'desc': '6 months – 2 years',
      },
      {'id': 'advanced', 'label': 'Advanced', 'desc': '2+ years of training'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.health_and_safety_outlined,
            title: 'Health & Experience',
            subtitle: 'This helps us keep your workouts safe',
          ),

          const SizedBox(height: 28),

          // Experience Level
          const _SectionLabel(label: 'Fitness Experience'),
          const SizedBox(height: 12),
          Row(
            children: experienceLevels.map((e) {
              final isSelected = _fitnessExperience == e['id'];
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _fitnessExperience = e['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          e['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e['desc'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Health Conditions
          const _SectionLabel(label: 'Health Conditions'),
          const SizedBox(height: 4),
          Text(
            'Select any that apply (optional)',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),

          _HealthToggle(
            label: 'Heart Condition',
            icon: Icons.favorite_border_rounded,
            color: const Color(0xFFFF5252),
            value: _hasHeartCondition,
            onChanged: (v) => setState(() => _hasHeartCondition = v),
          ),
          const SizedBox(height: 10),
          _HealthToggle(
            label: 'Diabetes',
            icon: Icons.water_drop_outlined,
            color: const Color(0xFF00D9FF),
            value: _hasDiabetes,
            onChanged: (v) => setState(() => _hasDiabetes = v),
          ),
          const SizedBox(height: 10),
          _HealthToggle(
            label: 'Joint / Back Issues',
            icon: Icons.accessibility_new_rounded,
            color: const Color(0xFFF4A538),
            value: _hasJointIssues,
            onChanged: (v) => setState(() => _hasJointIssues = v),
          ),
          const SizedBox(height: 10),
          _HealthToggle(
            label: 'High Blood Pressure',
            icon: Icons.monitor_heart_outlined,
            color: const Color(0xFF9B5DE5),
            value: _hasHypertension,
            onChanged: (v) => setState(() => _hasHypertension = v),
          ),

          const SizedBox(height: 24),

          // Privacy note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your health data is stored locally and never shared.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Shared Header ──
  Widget _buildPageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════
// SHARED WIDGETS
// ════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color iconColor;

  const _SelectionCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : iconColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final String displayValue;
  final int divisions;
  final ValueChanged<double> onChanged;
  final Color accentColor;

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.displayValue,
    required this.divisions,
    required this.onChanged,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$displayValue $unit',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              activeTrackColor: accentColor,
              inactiveTrackColor: AppColors.border,
              thumbColor: accentColor,
              overlayColor: accentColor.withOpacity(0.15),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${min.toInt()} $unit',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                '${max.toInt()} $unit',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  const _GoalCard({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.all(compact ? 14 : 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.12)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 40 : 48,
              height: compact ? 40 : 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: compact ? 20 : 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : AppColors.textPrimary,
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String label;
  final String desc;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.icon,
    required this.emoji,
    required this.label,
    required this.desc,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.12)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _HealthToggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? color.withOpacity(0.5) : AppColors.border,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _BmiCard extends StatelessWidget {
  final double heightCm;
  final double weightKg;

  const _BmiCard({required this.heightCm, required this.weightKg});

  @override
  Widget build(BuildContext context) {
    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);

    String category;
    Color color;
    IconData icon;

    if (bmi < 18.5) {
      category = 'Underweight';
      color = const Color(0xFF42A5F5);
      icon = Icons.trending_down_rounded;
    } else if (bmi < 25) {
      category = 'Healthy Weight';
      color = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
    } else if (bmi < 30) {
      category = 'Overweight';
      color = AppColors.warning;
      icon = Icons.warning_amber_rounded;
    } else {
      category = 'Obese';
      color = AppColors.error;
      icon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI: ${bmi.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  category,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Live',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
