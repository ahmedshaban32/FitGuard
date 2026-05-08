import 'package:flutter/material.dart';
import 'package:fit_guard_app/core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/features/progress/models/workout_history_entry.dart';
import 'package:fit_guard_app/features/progress/services/progress_repository.dart';
import 'package:fit_guard_app/presentation/screens/settings/settings_screen.dart';
import 'package:fit_guard_app/presentation/screens/onboarding/user_info_screen.dart';
import 'package:fit_guard_app/presentation/screens/profile/data/profile_repo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── User data ───────────────────────────────────────────────
  String userName = '';
  String userEmail = '';
  String? userImage;
  bool isLoading = true;

  // ── Fitness profile from UserInfoScreen ────────────────────
  Map<String, dynamic>? _userInfo;
  ProfileModel? _profile;
  final ProgressRepository _progressRepo = ProgressRepository();
  ProgressSummary _summary = const ProgressSummary();
  List<WorkoutHistoryEntry> _historyEntries = const [];

  late TabController _tabController;

  // ── Mock Stats ──────────────────────────────────────────────
  // ── Mock Workout History ────────────────────────────────────
  // ── Mock Goals ──────────────────────────────────────────────
  // ── Mock Devices ────────────────────────────────────────────
  final _devices = [
    {
      'name': 'Apple Watch Series 9',
      'type': 'Smartwatch',
      'icon': Icons.watch,
      'connected': true,
      'battery': '82%',
    },
    {
      'name': 'Mi Band 8',
      'type': 'Fitness Band',
      'icon': Icons.watch_later,
      'connected': false,
      'battery': '45%',
    },
    {
      'name': 'iPhone 15 Pro',
      'type': 'Phone Sensor',
      'icon': Icons.phone_iphone,
      'connected': true,
      'battery': '71%',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    ProgressRepository.revision.addListener(_refreshProgressFromCache);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await PrefHelper.getUserName();
    final email = await PrefHelper.getUserEmail();
    final image = await PrefHelper.getUserImage();
    var info = await PrefHelper.getUserInfo(); // ← local fallback
    ProfileModel? backendProfile;
    final history = await _progressRepo.getHistory(refresh: true);
    final summary = ProgressSummary.fromEntries(history);

    try {
      backendProfile = await ProfileRepo().getProfile();
      info = backendProfile.toLocalUserInfoJson();
      await PrefHelper.saveUserInfo(info);
    } catch (_) {
      // Keep rendering the cached profile if the backend is temporarily offline.
    }

    if (mounted) {
      setState(() {
        userName =
            backendProfile?.name ?? (name.isEmpty ? 'Alex Johnson' : name);
        userEmail = email.isEmpty ? 'alex@fitguard.com' : email;
        userImage = image;
        _userInfo = info;
        _profile = backendProfile ?? _profile;
        _historyEntries = history;
        _summary = summary;
        isLoading = false;
      });
    }
  }

  Future<void> _refreshProgressFromCache() async {
    final history = await _progressRepo.getHistory();
    if (!mounted) return;
    setState(() {
      _historyEntries = history;
      _summary = ProgressSummary.fromEntries(history);
    });
  }

  @override
  void dispose() {
    ProgressRepository.revision.removeListener(_refreshProgressFromCache);
    _tabController.dispose();
    super.dispose();
  }

  // ── Helpers to read saved fitness profile ───────────────────

  String get _savedGoal => (_userInfo?['profile']?['goal'] as String?) ?? '—';

  String get _savedActivity =>
      (_userInfo?['profile']?['activity_level'] as String?) ?? '—';

  int get _savedAge => (_userInfo?['profile']?['age'] as int?) ?? 0;

  int get _savedWeight => (_userInfo?['profile']?['weight_kg'] as int?) ?? 0;

  int get _savedHeight => (_userInfo?['profile']?['height_cm'] as int?) ?? 0;

  String get _savedDiet =>
      (_userInfo?['food_preferences']?['dietary_preference'] as String?) ?? '—';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(child: _buildHeader()),
                // ── Fitness profile banner (only if onboarding done) ──
                if (_userInfo != null)
                  SliverToBoxAdapter(child: _buildFitnessProfileBanner()),
                SliverToBoxAdapter(child: _buildStatsRow()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      dividerHeight: 0,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'History'),
                        Tab(text: 'Goals'),
                        Tab(text: 'Devices'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [_buildHistory(), _buildGoals(), _buildDevices()],
              ),
            ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  // Edit fitness profile shortcut
                  GestureDetector(
                    onTap: _editFitnessProfile,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: userImage != null
                    ? ClipOval(
                        child: Image.network(
                          userImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(),
                        ),
                      )
                    : _avatarFallback(),
              ),
              GestureDetector(
                onTap: _changePhoto,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() => Center(
    child: Text(
      userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // ── FITNESS PROFILE BANNER ─────────────────────────────────
  // Shows key info from UserInfoScreen below the avatar

  Widget _buildFitnessProfileBanner() {
    final chips = [
      _ProfileChip(label: 'Goal', value: _savedGoal, color: AppColors.primary),
      _ProfileChip(
        label: 'Activity',
        value: _savedActivity,
        color: AppColors.secondary,
      ),
      _ProfileChip(label: 'Diet', value: _savedDiet, color: AppColors.success),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Body metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricTile(label: 'Age', value: '$_savedAge yrs'),
              _vDivider(),
              _MetricTile(label: 'Weight', value: '$_savedWeight kg'),
              _vDivider(),
              _MetricTile(label: 'Height', value: '$_savedHeight cm'),
            ],
          ),
          const SizedBox(height: 14),
          // Goal / activity / diet chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((c) => _buildInfoChip(c)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 32,
    color: AppColors.border.withValues(alpha: 0.6),
  );

  Widget _buildInfoChip(_ProfileChip chip) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: chip.color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: chip.color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          chip.label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(width: 4),
        Text(
          chip.value,
          style: TextStyle(
            color: chip.color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  // ── STATS ROW ──────────────────────────────────────────────

  Widget _buildStatsRow() {
    final hours = _summary.activeMinutes >= 60
        ? '${(_summary.activeMinutes / 60).toStringAsFixed(1)}h'
        : '${_summary.activeMinutes}m';
    final stats = [
      {
        'label': 'Workouts',
        'value': '${_summary.totalWorkouts}',
        'icon': Icons.fitness_center,
      },
      {
        'label': 'Streak',
        'value': '${_summary.workoutStreak}d',
        'icon': Icons.local_fire_department,
      },
      {
        'label': 'Kcal',
        'value': '${_summary.caloriesBurned}',
        'icon': Icons.local_fire_department,
      },
      {'label': 'Active', 'value': hours, 'icon': Icons.timer_outlined},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: stats.map((s) {
          final isLast = s == stats.last;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: isLast
                      ? BorderSide.none
                      : BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    s['icon'] as IconData,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s['value'] as String,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['label'] as String,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── HISTORY TAB ────────────────────────────────────────────

  Widget _buildHistory() {
    if (_historyEntries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _ProfileEmptyState(
            icon: Icons.history,
            title: 'No history yet',
            message:
                'AI workouts, uploaded video analysis, and cardio entries will appear here.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _historyEntries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final entry = _historyEntries[i];
        final color = _historyColor(entry);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_historyIcon(entry), color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.exerciseName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_dateLabel(entry.sessionAt)} - ${entry.source.name.toUpperCase()}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        color: AppColors.textSecondary,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _durationLabel(entry.durationSeconds),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppColors.calories,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${entry.caloriesBurned} kcal',
                        style: const TextStyle(
                          color: AppColors.calories,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── GOALS TAB ──────────────────────────────────────────────

  Widget _buildGoals() {
    final goals = _goalProgressItems();
    final average = goals.isEmpty
        ? 0.0
        : goals.fold<double>(0, (sum, goal) => sum + goal.progress) /
              goals.length;
    final averagePct = (average * 100).round();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _savedGoal == 'â€”' ? 'This Week' : _savedGoal,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$averagePct% of goals reached',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: average,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...goals.map((g) {
          final color = g.color;
          final progress = g.progress;
          final pct = (progress * 100).round();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          g.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatGoalNumber(g.current)} / ${_formatGoalNumber(g.target)} ${g.unit}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      g.subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── DEVICES TAB ────────────────────────────────────────────

  List<_GoalProgress> _goalProgressItems() {
    final weekly = _recentEntries(const Duration(days: 7));
    final strengthCount = weekly
        .where((entry) => entry.type != WorkoutHistoryType.cardio)
        .length;
    final cardioCount = weekly
        .where((entry) => entry.type == WorkoutHistoryType.cardio)
        .length;
    final activeDays = weekly
        .map(
          (entry) => DateTime(
            entry.sessionAt.year,
            entry.sessionAt.month,
            entry.sessionAt.day,
          ),
        )
        .toSet()
        .length;
    final weeklyCalories = weekly.fold<int>(
      0,
      (sum, entry) => sum + entry.caloriesBurned,
    );
    final weeklyMinutes = weekly.fold<int>(
      0,
      (sum, entry) => sum + (entry.durationSeconds / 60).round(),
    );
    final weeklyReps = weekly.fold<int>(
      0,
      (sum, entry) => sum + entry.totalReps,
    );
    final weeklyCorrect = weekly.fold<int>(
      0,
      (sum, entry) => sum + entry.correctReps,
    );
    final weeklyAccuracy = weeklyReps == 0 ? 0.0 : weeklyCorrect / weeklyReps;
    final goal = _savedGoal.toLowerCase();

    if (goal.contains('weight')) {
      return [
        _GoalProgress(
          title: 'Weekly Workouts',
          current: strengthCount + cardioCount,
          target: 5,
          unit: 'sessions',
          color: AppColors.primary,
          subtitle: 'Goal: stay consistent',
        ),
        _GoalProgress(
          title: 'Calories Burned',
          current: weeklyCalories,
          target: 1800,
          unit: 'kcal',
          color: AppColors.calories,
          subtitle: '${(1800 - weeklyCalories).clamp(0, 1800)} kcal left',
        ),
        _GoalProgress(
          title: 'Cardio Sessions',
          current: cardioCount,
          target: 3,
          unit: 'sessions',
          color: AppColors.secondary,
          subtitle: 'Supports weight loss',
        ),
        _GoalProgress(
          title: 'Consistency',
          current: activeDays,
          target: 5,
          unit: 'days',
          color: AppColors.success,
          subtitle: 'Active days this week',
        ),
      ];
    }

    if (goal.contains('muscle') || goal.contains('strength')) {
      return [
        _GoalProgress(
          title: 'Strength Workouts',
          current: strengthCount,
          target: 4,
          unit: 'sessions',
          color: AppColors.primary,
          subtitle: 'Progressive training focus',
        ),
        _GoalProgress(
          title: 'Tracked Reps',
          current: weeklyReps,
          target: 120,
          unit: 'reps',
          color: AppColors.success,
          subtitle: '${(120 - weeklyReps).clamp(0, 120)} reps left',
        ),
        _GoalProgress(
          title: 'Form Accuracy',
          current: weeklyAccuracy * 100,
          target: 85,
          unit: '%',
          color: AppColors.secondary,
          subtitle: 'Correct reps percentage',
        ),
        _GoalProgress(
          title: 'Workout Frequency',
          current: activeDays,
          target: 4,
          unit: 'days',
          color: AppColors.warning,
          subtitle: 'Training days this week',
        ),
      ];
    }

    return [
      _GoalProgress(
        title: 'Weekly Activity',
        current: activeDays,
        target: 5,
        unit: 'days',
        color: AppColors.primary,
        subtitle: 'Maintain your rhythm',
      ),
      _GoalProgress(
        title: 'Active Minutes',
        current: weeklyMinutes,
        target: 150,
        unit: 'min',
        color: AppColors.success,
        subtitle: '${(150 - weeklyMinutes).clamp(0, 150)} min left',
      ),
      _GoalProgress(
        title: 'Cardio Balance',
        current: cardioCount,
        target: 2,
        unit: 'sessions',
        color: AppColors.calories,
        subtitle: 'Keep conditioning included',
      ),
      _GoalProgress(
        title: 'Form Accuracy',
        current: weeklyAccuracy * 100,
        target: 80,
        unit: '%',
        color: AppColors.secondary,
        subtitle: 'AI-tracked quality',
      ),
    ];
  }

  List<WorkoutHistoryEntry> _recentEntries(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return _historyEntries
        .where((entry) => entry.sessionAt.isAfter(cutoff))
        .toList();
  }

  Widget _buildDevices() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GestureDetector(
          onTap: _showAddDevice,
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Connect New Device',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        ..._devices.map((d) {
          final connected = d['connected'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: connected
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: connected
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    d['icon'] as IconData,
                    color: connected
                        ? AppColors.success
                        : AppColors.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['name'] as String,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: connected
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            connected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: connected
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.battery_std,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            d['battery'] as String,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: connected,
                  onChanged: (_) {},
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Actions ────────────────────────────────────────────────

  void _changePhoto() => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Photo upload coming soon!'),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );

  void _editFitnessProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserInfoScreen()),
    ).then((_) => _loadUser()); // reload after returning
  }

  void _editProfile() {
    final current = _profile ?? ProfileModel.fromJson(_userInfo ?? {});
    final nameCtrl = TextEditingController(text: userName);
    final ageCtrl = TextEditingController(text: '$_savedAge');
    final weightCtrl = TextEditingController(text: '$_savedWeight');
    final heightCtrl = TextEditingController(text: '$_savedHeight');
    var saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _editField('Full Name', nameCtrl, Icons.person_outline),
                const SizedBox(height: 14),
                _readOnlyField('Email', userEmail, Icons.email_outlined),
                const SizedBox(height: 14),
                _editField('Age', ageCtrl, Icons.cake_outlined),
                const SizedBox(height: 14),
                _editField(
                  'Weight (kg)',
                  weightCtrl,
                  Icons.monitor_weight_outlined,
                ),
                const SizedBox(height: 14),
                _editField('Height (cm)', heightCtrl, Icons.height),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final navigator = Navigator.of(sheetContext);
                            final messenger = ScaffoldMessenger.of(context);
                            final updated = current.copyWith(
                              name: nameCtrl.text.trim(),
                              age: int.tryParse(ageCtrl.text.trim()),
                              weightKg: double.tryParse(weightCtrl.text.trim()),
                              heightCm: double.tryParse(heightCtrl.text.trim()),
                            );

                            setSheetState(() => saving = true);
                            try {
                              final saved = await ProfileRepo().updateProfile(
                                updated,
                              );
                              await PrefHelper.saveUserInfo(
                                saved.toLocalUserInfoJson(),
                              );
                              if (!mounted) return;
                              navigator.pop();
                              setState(() {
                                _profile = saved;
                                _userInfo = saved.toLocalUserInfoJson();
                                userName = saved.name ?? userName;
                              });
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Profile updated.'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              setSheetState(() => saving = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(error.toString()),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      ageCtrl.dispose();
      weightCtrl.dispose();
      heightCtrl.dispose();
    });
  }

  Widget _editField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        style: const TextStyle(color: AppColors.textSecondary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  void _showAddDevice() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connect Device',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Searching for nearby devices...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Bluetooth & Location required',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────

class _ProfileChip {
  final String label;
  final String value;
  final Color color;
  const _ProfileChip({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _GoalProgress {
  final String title;
  final double current;
  final double target;
  final String unit;
  final Color color;
  final String subtitle;

  _GoalProgress({
    required this.title,
    required num current,
    required num target,
    required this.unit,
    required this.color,
    required this.subtitle,
  }) : current = current.toDouble(),
       target = target <= 0 ? 1 : target.toDouble();

  double get progress => (current / target).clamp(0.0, 1.0);
}

class _ProfileEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ProfileEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Tab bar delegate ──────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) {
    return SizedBox(
      height: maxExtent,
      child: Container(color: AppColors.background, child: tabBar),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

Color _historyColor(WorkoutHistoryEntry entry) {
  if (entry.type == WorkoutHistoryType.cardio) return AppColors.calories;
  if (entry.source == WorkoutHistorySource.ai) return AppColors.secondary;
  return AppColors.primary;
}

IconData _historyIcon(WorkoutHistoryEntry entry) {
  if (entry.type == WorkoutHistoryType.cardio) return Icons.directions_run;
  if (entry.source == WorkoutHistorySource.ai) return Icons.psychology_alt;
  return Icons.fitness_center;
}

String _durationLabel(int seconds) {
  if (seconds <= 0) return '0 min';
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final hours = minutes / 60;
  return '${hours.toStringAsFixed(1)} h';
}

String _dateLabel(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(value.year, value.month, value.day);
  if (date == today) return 'Today';
  if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _formatGoalNumber(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}
