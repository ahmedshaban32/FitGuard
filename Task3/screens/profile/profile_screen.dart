import 'package:flutter/material.dart';
import 'package:fit_guard_app/core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/presentation/screens/settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String userName = '';
  String userEmail = '';
  String? userImage;
  bool isLoading = true;

  late TabController _tabController;

  // ── Mock Stats ──────────────────────────────────────────────────
  final _stats = [
    {'label': 'Workouts', 'value': '48', 'icon': Icons.fitness_center},
    {'label': 'Streak', 'value': '12d', 'icon': Icons.local_fire_department},
    {'label': 'Kg Lost', 'value': '5.3', 'icon': Icons.trending_down},
    {'label': 'Hours', 'value': '36h', 'icon': Icons.timer_outlined},
  ];

  // ── Mock Workout History ────────────────────────────────────────
  final _history = [
    {
      'name': 'HIIT Cardio Blast',
      'date': 'Today',
      'duration': '45 min',
      'kcal': '320',
      'icon': Icons.directions_run,
      'color': 0xFFE53935,
    },
    {
      'name': 'Upper Body Strength',
      'date': 'Yesterday',
      'duration': '50 min',
      'kcal': '280',
      'icon': Icons.fitness_center,
      'color': 0xFF9B5DE5,
    },
    {
      'name': 'Morning Yoga',
      'date': 'Mon, Feb 15',
      'duration': '30 min',
      'kcal': '120',
      'icon': Icons.self_improvement,
      'color': 0xFF00BCD4,
    },
    {
      'name': 'Leg Day Power',
      'date': 'Sun, Feb 14',
      'duration': '55 min',
      'kcal': '410',
      'icon': Icons.sports_gymnastics,
      'color': 0xFFF4A538,
    },
    {
      'name': 'Lunch Break Cardio',
      'date': 'Sat, Feb 13',
      'duration': '20 min',
      'kcal': '180',
      'icon': Icons.directions_bike,
      'color': 0xFF43A047,
    },
    {
      'name': 'Full Body HIIT',
      'date': 'Fri, Feb 12',
      'duration': '40 min',
      'kcal': '350',
      'icon': Icons.sports_mma,
      'color': 0xFFE91E63,
    },
  ];

  // ── Mock Goals ──────────────────────────────────────────────────
  final _goals = [
    {
      'title': 'Weekly Workouts',
      'current': 4,
      'target': 5,
      'unit': 'sessions',
      'color': 0xFF9B5DE5,
    },
    {
      'title': 'Daily Steps',
      'current': 6432,
      'target': 10000,
      'unit': 'steps',
      'color': 0xFF00BCD4,
    },
    {
      'title': 'Weight Goal',
      'current': 77,
      'target': 72,
      'unit': 'kg',
      'color': 0xFFF4A538,
    },
    {
      'title': 'Water Intake',
      'current': 6,
      'target': 8,
      'unit': 'glasses',
      'color': 0xFF43A047,
    },
    {
      'title': 'Calories Burned',
      'current': 450,
      'target': 600,
      'unit': 'kcal',
      'color': 0xFFE53935,
    },
  ];

  // ── Mock Devices ────────────────────────────────────────────────
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
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await PrefHelper.getUserName();
    final email = await PrefHelper.getUserEmail();
    final image = await PrefHelper.getUserImage();
    if (mounted) {
      setState(() {
        userName = name.isEmpty ? 'Alex Johnson' : name;
        userEmail = email ?? 'alex@fitguard.com';
        userImage = image;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                SliverToBoxAdapter(child: _buildStatsRow()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
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

  // ── HEADER ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Top bar
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

          const SizedBox(height: 24),

          // Avatar + name
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

          // Edit profile button
          OutlinedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
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

  Widget _avatarFallback() {
    return Center(
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── STATS ROW ──────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: _stats.map((s) {
          final isLast = s == _stats.last;
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

  // ── HISTORY TAB ────────────────────────────────────────────────
  Widget _buildHistory() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final w = _history[i];
        final color = Color(w['color'] as int);
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
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(w['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w['name'] as String,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      w['date'] as String,
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
                        w['duration'] as String,
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
                        '${w['kcal']} kcal',
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

  // ── GOALS TAB ─────────────────────────────────────────────────
  Widget _buildGoals() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Weekly summary card
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
                    const Text(
                      'This Week',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Text(
                      '80% of goals reached!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.8,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.2),
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

        ..._goals.map((g) {
          final color = Color(g['color'] as int);
          final current = (g['current'] as num).toDouble();
          final target = (g['target'] as num).toDouble();
          // For weight goal, progress is inverted
          final isWeight = g['title'] == 'Weight Goal';
          final progress = isWeight
              ? ((82.5 - current) / (82.5 - target)).clamp(0.0, 1.0)
              : (current / target).clamp(0.0, 1.0);
          final pct = (progress * 100).toInt();

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
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
                          g['title'] as String,
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
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isWeight
                          ? 'Current: ${current.toInt()} ${g['unit']}'
                          : '${current.toInt()} / ${target.toInt()} ${g['unit']}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      isWeight
                          ? 'Target: ${target.toInt()} ${g['unit']}'
                          : '${(target - current).toInt()} ${g['unit']} left',
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

  // ── DEVICES TAB ───────────────────────────────────────────────
  Widget _buildDevices() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Add device button
        GestureDetector(
          onTap: () => _showAddDevice(),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
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
                    ? AppColors.success.withOpacity(0.3)
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
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.border.withOpacity(0.3),
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
                          Icon(
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
                  onChanged: (v) {},
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _changePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Photo upload coming soon!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
            _editField('Full Name', userName, Icons.person_outline),
            const SizedBox(height: 14),
            _editField('Email', userEmail, Icons.email_outlined),
            const SizedBox(height: 14),
            _editField('Age', '28', Icons.cake_outlined),
            const SizedBox(height: 14),
            _editField('Weight (kg)', '77.2', Icons.monitor_weight_outlined),
            const SizedBox(height: 14),
            _editField('Height (cm)', '178', Icons.height),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
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
    );
  }

  Widget _editField(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        initialValue: value,
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
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Bluetooth & Location required',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TAB BAR DELEGATE ──────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.background, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
