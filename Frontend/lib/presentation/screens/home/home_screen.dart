import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/features/ai_coach/screens/ai_coach_chat_screen.dart';
import 'package:fit_guard_app/features/coach_chat/screens/coaches_screen.dart';
import 'package:fit_guard_app/features/food_scanner/screens/food_scanner_screen.dart';
import 'package:fit_guard_app/features/nearby_gyms/screens/nearby_gyms_screen.dart';
import 'package:fit_guard_app/features/progress/models/workout_history_entry.dart';
import 'package:fit_guard_app/features/progress/screens/history_screen.dart';
import 'package:fit_guard_app/features/progress/services/progress_repository.dart';
import 'package:fit_guard_app/presentation/screens/profile/data/profile_repo.dart';
import 'package:flutter/material.dart';

class HomeScreenDark extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeScreenDark({super.key, required this.onTabChange});

  @override
  State<HomeScreenDark> createState() => _HomeScreenDarkState();
}

class _HomeScreenDarkState extends State<HomeScreenDark> {
  String userName = '';
  String userRole = 'user';
  String userGoal = 'Maintain Fitness';
  ProgressSummary _summary = const ProgressSummary();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await PrefHelper.getUserName();
    final role = await PrefHelper.getUserRole();
    ProfileModel? profile;
    try {
      profile = await ProfileRepo().getProfile();
      await PrefHelper.saveUserInfo(profile.toLocalUserInfoJson());
    } catch (_) {}
    final summary = await ProgressRepository().getSummary(refresh: true);
    if (!mounted) return;
    setState(() {
      userName = profile?.name ?? (name.isEmpty ? 'Athlete' : name);
      userRole = role;
      userGoal = profile?.goal ?? userGoal;
      _summary = summary;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          color: AppColors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildProgressStrip(),
              const SizedBox(height: 22),
              _buildAiCoachHero(),
              const SizedBox(height: 22),
              _buildFeatureGrid(),
              const SizedBox(height: 24),
              _buildRolePanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final date = '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 5),
              Text(
                isLoading ? 'Hello' : 'Hello, $userName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                userGoal,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user,
                color: AppColors.success,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                userRole.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiCoachHero() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF00D9FF), Color(0xFF00D9A0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.psychology_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'LIVE AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Ask AI Coach',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get instant fitness advice for workouts, nutrition, calories, recovery, and motivation.',
              style: TextStyle(color: Colors.white, height: 1.45, fontSize: 14),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _push(const AiCoachChatScreen()),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Ask AI Coach'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () => _push(const FoodScannerScreen()),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: const Icon(Icons.document_scanner_outlined),
                  tooltip: 'Scan food',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final actions = [
      _HomeAction(
        title: 'Scan Food',
        subtitle: 'Calories and macros',
        icon: Icons.document_scanner_outlined,
        color: AppColors.success,
        onTap: () => _push(const FoodScannerScreen()),
      ),
      _HomeAction(
        title: 'Workout',
        subtitle: 'AI form tracking',
        icon: Icons.fitness_center,
        color: AppColors.primary,
        onTap: () => widget.onTabChange(1),
      ),
      _HomeAction(
        title: 'Nutrition',
        subtitle: 'Meal plan',
        icon: Icons.restaurant_menu,
        color: AppColors.fats,
        onTap: () => widget.onTabChange(2),
      ),
      _HomeAction(
        title: 'Recovery',
        subtitle: 'Ask for tips',
        icon: Icons.self_improvement,
        color: AppColors.secondary,
        onTap: () => _push(const AiCoachChatScreen()),
      ),
      _HomeAction(
        title: 'Nearby Gyms',
        subtitle: 'Map and ratings',
        icon: Icons.location_on_outlined,
        color: AppColors.info,
        onTap: () => _push(const NearbyGymsScreen()),
      ),
      _HomeAction(
        title: 'Coaches',
        subtitle: userRole == 'coach' ? 'Reply to users' : 'Real guidance',
        icon: Icons.groups_2_outlined,
        color: AppColors.calories,
        onTap: () => _push(const CoachesScreen()),
      ),
      _HomeAction(
        title: 'History',
        subtitle: 'Sessions and progress',
        icon: Icons.history,
        color: AppColors.warning,
        onTap: () => _push(const HistoryScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions
                  .map(
                    (action) => SizedBox(
                      width: width,
                      child: _ActionCard(action: action),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRolePanel() {
    final isCoach = userRole == 'coach';
    final isAdmin = userRole == 'admin';
    final title = isAdmin
        ? 'Admin workspace'
        : isCoach
        ? 'Coach workspace'
        : 'Your coaching team';
    final message = isAdmin
        ? 'Manage users and platform metrics from the admin dashboard.'
        : isCoach
        ? 'Reply to subscribed users and keep their plans moving.'
        : 'Browse public coaches and message your subscribed coach.';
    final icon = isAdmin
        ? Icons.admin_panel_settings
        : isCoach
        ? Icons.support_agent
        : Icons.workspace_premium;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isAdmin
                ? () => Navigator.pushNamed(context, '/admin')
                : () => _push(const CoachesScreen()),
            icon: const Icon(Icons.arrow_forward, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStrip() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniMetric(
              icon: Icons.local_fire_department,
              value: '${_summary.caloriesBurned}',
              label: 'KCAL',
              color: AppColors.calories,
            ),
          ),
          Expanded(
            child: _MiniMetric(
              icon: Icons.fitness_center,
              value: '${_summary.totalWorkouts}',
              label: 'WORKOUTS',
              color: AppColors.success,
            ),
          ),
          Expanded(
            child: _MiniMetric(
              icon: Icons.bolt,
              value: '${_summary.activeMinutes}m',
              label: 'ACTIVE',
              color: AppColors.secondary,
            ),
          ),
          Expanded(
            child: _MiniMetric(
              icon: Icons.check_circle_outline,
              value: '${(_summary.accuracy * 100).round()}%',
              label: 'ACCURACY',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  String _weekday(int day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(day - 1).clamp(0, names.length - 1)];
  }

  String _month(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[(month - 1).clamp(0, names.length - 1)];
  }
}

class _HomeAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ActionCard extends StatelessWidget {
  final _HomeAction action;

  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              action.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
