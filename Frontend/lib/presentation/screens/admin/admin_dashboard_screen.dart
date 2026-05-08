import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/presentation/screens/admin/data/admin_models.dart';
import 'package:fit_guard_app/presentation/screens/admin/data/admin_service.dart';
import 'package:fit_guard_app/presentation/screens/admin/user_details_screen.dart';
import 'package:fit_guard_app/presentation/screens/auth/view/login_screen.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _service = AdminService();
  final TextEditingController _searchController = TextEditingController();

  bool _loadingDashboard = true;
  bool _loadingUsers = true;
  String? _dashboardError;
  String? _usersError;
  Map<String, dynamic> _metrics = {};
  List<AdminUser> _users = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  String _roleFilter = '';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final metrics = await _service.getDashboard();
      if (!mounted) return;
      setState(() => _metrics = metrics);
    } catch (error) {
      if (!mounted) return;
      setState(() => _dashboardError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _usersError = null;
    });

    try {
      final result = await _service.getUsers(
        page: _page,
        role: _roleFilter,
        search: _search,
      );
      if (!mounted) return;
      setState(() {
        _users = result.users;
        _page = result.page;
        _totalPages = result.totalPages;
        _total = result.total;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _usersError = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiError) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _logout() async {
    await PrefHelper.clearAll();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreenDark()),
      (_) => false,
    );
  }

  void _applySearch() {
    setState(() {
      _page = 1;
      _search = _searchController.text.trim();
    });
    _loadUsers();
  }

  Future<void> _openUser(AdminUser user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserDetailsScreen(userId: user.id)),
    );
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text(
            'Admin Console',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.secondary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
              Tab(icon: Icon(Icons.people_outline), text: 'Users'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _loadDashboard,
              child: _buildDashboardTab(),
            ),
            RefreshIndicator(onRefresh: _loadUsers, child: _buildUsersTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_loadingDashboard) return _loadingView('Loading dashboard...');
    if (_dashboardError != null) {
      return _errorView(_dashboardError!, _loadDashboard);
    }

    final cards = _metricCards();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Platform Overview',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Live metrics from the production FitGuard API.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (_, index) => _MetricTile(
            label: cards[index].key,
            value: cards[index].value,
            color: _metricColor(index),
          ),
        ),
        const SizedBox(height: 24),
        _buildMetricBars(cards),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'Raw Metrics',
          child: Text(
            _metrics.entries
                .map((entry) => '${entry.key}: ${entry.value}')
                .join('\n'),
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Users Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 16),
        if (_usersError != null)
          _InlineError(message: _usersError!, onRetry: _loadUsers)
        else if (_loadingUsers)
          _loadingView('Loading users...', compact: true)
        else if (_users.isEmpty)
          const _EmptyCard(message: 'No users found.')
        else ...[
          Text(
            '$_total users • page $_page of $_totalPages',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ..._users.map(
            (user) => _UserCard(user: user, onTap: () => _openUser(user)),
          ),
          const SizedBox(height: 12),
          _buildPagination(),
        ],
      ],
    );
  }

  Widget _buildFilters() {
    return _SectionCard(
      title: 'Filters',
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _applySearch(),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration(
              'Search by email or name',
              Icons.search,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _roleFilter,
            dropdownColor: AppColors.cardBackground,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Role', Icons.admin_panel_settings),
            items: const [
              DropdownMenuItem(value: '', child: Text('All roles')),
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'coach', child: Text('Coach')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (value) {
              setState(() {
                _roleFilter = value ?? '';
                _page = 1;
              });
              _loadUsers();
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _applySearch,
              icon: const Icon(Icons.search),
              label: const Text('Apply Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _page <= 1
                ? null
                : () {
                    setState(() => _page--);
                    _loadUsers();
                  },
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$_page / $_totalPages',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _page >= _totalPages
                ? null
                : () {
                    setState(() => _page++);
                    _loadUsers();
                  },
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBars(List<MapEntry<String, String>> cards) {
    final numeric = cards
        .map((entry) => MapEntry(entry.key, double.tryParse(entry.value)))
        .where((entry) => entry.value != null)
        .toList();
    if (numeric.isEmpty) return const SizedBox.shrink();

    final maxValue = numeric
        .map((entry) => entry.value!)
        .fold<double>(1, (max, value) => value > max ? value : max);

    return _SectionCard(
      title: 'Metrics Chart',
      child: Column(
        children: numeric.map((entry) {
          final value = entry.value!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      value.toStringAsFixed(
                        value.truncateToDouble() == value ? 0 : 1,
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (value / maxValue).clamp(0.04, 1),
                    minHeight: 8,
                    color: AppColors.secondary,
                    backgroundColor: AppColors.surface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<MapEntry<String, String>> _metricCards() {
    final entries = <MapEntry<String, String>>[];
    const preferred = {
      'totalUsers': 'Total Users',
      'users': 'Total Users',
      'totalCoaches': 'Total Coaches',
      'coaches': 'Total Coaches',
      'activeSubscriptions': 'Active Subscriptions',
      'subscriptions': 'Subscriptions',
    };

    for (final item in preferred.entries) {
      final value = _metrics[item.key];
      if (value is num || value is String) {
        entries.add(MapEntry(item.value, value.toString()));
      }
    }

    for (final item in _metrics.entries) {
      if (preferred.containsKey(item.key)) continue;
      if (item.value is num || item.value is String) {
        entries.add(MapEntry(_title(item.key), item.value.toString()));
      }
    }

    return entries.isEmpty
        ? [MapEntry('Metrics Returned', _metrics.length.toString())]
        : entries;
  }

  Color _metricColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.secondary,
      AppColors.error,
    ];
    return colors[index % colors.length];
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.secondary),
      ),
    );
  }

  Widget _loadingView(String label, {bool compact = false}) {
    return SizedBox(
      height: compact ? 120 : 500,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _errorView(String message, Future<void> Function() retry) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [_InlineError(message: message, onRetry: retry)],
    );
  }

  String _title(String value) {
    return value
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.insights, color: color),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _roleColor(user.role).withValues(alpha: 0.18),
          child: Icon(Icons.person, color: _roleColor(user.role)),
        ),
        title: Text(
          user.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${user.name} • ${user.id}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: _RoleBadge(role: user.role),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.primary;
      case 'coach':
        return AppColors.success;
      default:
        return AppColors.secondary;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
