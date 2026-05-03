import 'package:flutter/material.dart';
import 'package:fit_guard_app/core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/presentation/screens/auth/view/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Notifications ───────────────────────────────────────────────
  bool _workoutReminders = true;
  bool _goalAlerts = true;
  bool _weeklyReport = false;
  bool _coachTips = true;
  bool _hydrationReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);

  // ── Units ───────────────────────────────────────────────────────
  bool _useKg = true; // false = lbs
  bool _useKm = true; // false = miles
  bool _use24h = true; // false = 12h
  int _selectedCalorieGoal = 2100;

  // ── Privacy ─────────────────────────────────────────────────────
  bool _shareActivity = false;
  bool _analyticsEnabled = true;
  bool _biometricLock = false;

  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await PrefHelper.getUserName();
    final email = await PrefHelper.getUserEmail();
    if (mounted)
      setState(() {
        userName = name.isEmpty ? 'Alex Johnson' : name;
        userEmail = email ?? 'alex@fitguard.com';
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── ACCOUNT CARD ──
          _buildAccountCard(),

          const SizedBox(height: 8),

          // ── NOTIFICATIONS ──
          _sectionTitle('Notifications', Icons.notifications_outlined),
          _settingsCard([
            _switchTile(
              'Workout Reminders',
              'Get reminded before your scheduled workout',
              Icons.fitness_center_outlined,
              AppColors.primary,
              _workoutReminders,
              (v) => setState(() => _workoutReminders = v),
            ),
            _divider(),
            _tappableTile(
              'Reminder Time',
              _reminderTime.format(context),
              Icons.access_time_outlined,
              const Color(0xFF00BCD4),
              _pickTime,
            ),
            _divider(),
            _switchTile(
              'Goal Alerts',
              'Notify when you reach daily goals',
              Icons.flag_outlined,
              AppColors.success,
              _goalAlerts,
              (v) => setState(() => _goalAlerts = v),
            ),
            _divider(),
            _switchTile(
              'Hydration Reminders',
              'Remind to drink water every 2 hours',
              Icons.water_drop_outlined,
              const Color(0xFF00BCD4),
              _hydrationReminder,
              (v) => setState(() => _hydrationReminder = v),
            ),
            _divider(),
            _switchTile(
              'AI Coach Tips',
              'Receive personalized tips from your AI coach',
              Icons.psychology_outlined,
              AppColors.primary,
              _coachTips,
              (v) => setState(() => _coachTips = v),
            ),
            _divider(),
            _switchTile(
              'Weekly Report',
              'Get a summary of your weekly progress',
              Icons.bar_chart_outlined,
              const Color(0xFFF4A538),
              _weeklyReport,
              (v) => setState(() => _weeklyReport = v),
            ),
          ]),

          const SizedBox(height: 8),

          // ── UNITS ──
          _sectionTitle('Units & Preferences', Icons.straighten_outlined),
          _settingsCard([
            _segmentTile(
              'Weight',
              Icons.monitor_weight_outlined,
              AppColors.calories,
              ['kg', 'lbs'],
              _useKg ? 0 : 1,
              (i) => setState(() => _useKg = i == 0),
            ),
            _divider(),
            _segmentTile(
              'Distance',
              Icons.directions_run_outlined,
              AppColors.active,
              ['km', 'miles'],
              _useKm ? 0 : 1,
              (i) => setState(() => _useKm = i == 0),
            ),
            _divider(),
            _segmentTile(
              'Time Format',
              Icons.schedule_outlined,
              const Color(0xFF00BCD4),
              ['24h', '12h'],
              _use24h ? 0 : 1,
              (i) => setState(() => _use24h = i == 0),
            ),
            _divider(),
            _tappableTile(
              'Daily Calorie Goal',
              '$_selectedCalorieGoal kcal',
              Icons.local_fire_department_outlined,
              AppColors.calories,
              _pickCalorieGoal,
            ),
          ]),

          const SizedBox(height: 8),

          // ── PRIVACY & SECURITY ──
          _sectionTitle('Privacy & Security', Icons.security_outlined),
          _settingsCard([
            _switchTile(
              'Biometric Lock',
              'Use fingerprint or Face ID to unlock app',
              Icons.fingerprint,
              AppColors.success,
              _biometricLock,
              (v) => setState(() => _biometricLock = v),
            ),
            _divider(),
            _switchTile(
              'Share Activity',
              'Allow friends to see your workouts',
              Icons.people_outline,
              AppColors.primary,
              _shareActivity,
              (v) => setState(() => _shareActivity = v),
            ),
            _divider(),
            _switchTile(
              'Analytics',
              'Help improve FitGuard by sharing usage data',
              Icons.analytics_outlined,
              const Color(0xFF00BCD4),
              _analyticsEnabled,
              (v) => setState(() => _analyticsEnabled = v),
            ),
            _divider(),
            _tappableTile(
              'Privacy Policy',
              'View our privacy policy',
              Icons.policy_outlined,
              AppColors.textSecondary,
              () => _openUrl('Privacy Policy'),
            ),
            _divider(),
            _tappableTile(
              'Data & Storage',
              'Manage your data and downloads',
              Icons.storage_outlined,
              AppColors.textSecondary,
              _manageData,
            ),
            _divider(),
            _tappableTile(
              'Change Password',
              'Update your account password',
              Icons.lock_outline,
              AppColors.textSecondary,
              _changePassword,
            ),
          ]),

          const SizedBox(height: 8),

          // ── ABOUT ──
          _sectionTitle('About', Icons.info_outline),
          _settingsCard([
            _tappableTile(
              'Version',
              '1.0.0 (Build 1)',
              Icons.new_releases_outlined,
              AppColors.primary,
              null,
            ),
            _divider(),
            _tappableTile(
              'Terms of Service',
              'Read our terms and conditions',
              Icons.description_outlined,
              AppColors.textSecondary,
              () => _openUrl('Terms of Service'),
            ),
            _divider(),
            _tappableTile(
              'Rate FitGuard',
              'Love the app? Leave us a review!',
              Icons.star_outline,
              const Color(0xFFF4A538),
              _rateApp,
            ),
            _divider(),
            _tappableTile(
              'Contact Support',
              'Get help or report an issue',
              Icons.headset_mic_outlined,
              const Color(0xFF00BCD4),
              _contactSupport,
            ),
          ]),

          const SizedBox(height: 24),

          // ── LOGOUT BUTTON ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── DELETE ACCOUNT ──
          Center(
            child: TextButton(
              onPressed: _confirmDeleteAccount,
              child: const Text(
                'Delete Account',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ACCOUNT CARD ────────────────────────────────────────────────
  Widget _buildAccountCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILDERS ────────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(children: children),
    );
  }

  Widget _switchTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _tappableTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _segmentTile(
    String title,
    IconData icon,
    Color color,
    List<String> options,
    int selected,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: List.generate(options.length, (i) {
                final sel = selected == i;
                return GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      options[i],
                      style: TextStyle(
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(color: AppColors.border, height: 1, thickness: 0.5, indent: 68);

  // ── ACTIONS ─────────────────────────────────────────────────────
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  void _pickCalorieGoal() {
    final goals = [1500, 1800, 2000, 2100, 2300, 2500, 2800];
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
              'Daily Calorie Goal',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...goals.map(
              (g) => ListTile(
                title: Text(
                  '$g kcal',
                  style: TextStyle(
                    color: g == _selectedCalorieGoal
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: g == _selectedCalorieGoal
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: g == _selectedCalorieGoal
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedCalorieGoal = g);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              'Change Password',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _passwordField('Current Password'),
            const SizedBox(height: 12),
            _passwordField('New Password'),
            const SizedBox(height: 12),
            _passwordField('Confirm New Password'),
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
                  'Update Password',
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

  Widget _passwordField(String label) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        obscureText: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  void _manageData() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Data & Storage',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dataRow('Workout Data', '2.4 MB'),
            _dataRow('Nutrition Logs', '1.1 MB'),
            _dataRow('AI Model', '5.2 MB'),
            _dataRow('Cache', '0.8 MB'),
            const Divider(color: AppColors.border),
            _dataRow('Total', '9.5 MB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Clear Cache',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          Text(
            size,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openUrl(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $title...'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening App Store...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening support chat...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await PrefHelper.clearUser();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreenDark()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete your account and all data. This cannot be undone.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All workouts, progress, and goals will be lost.',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await PrefHelper.clearUser();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreenDark()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete Forever',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
