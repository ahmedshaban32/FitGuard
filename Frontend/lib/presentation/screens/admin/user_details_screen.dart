import 'package:fit_guard_app/Core/constants/app_colors.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/presentation/screens/admin/data/admin_models.dart';
import 'package:fit_guard_app/presentation/screens/admin/data/admin_service.dart';
import 'package:flutter/material.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final AdminService _service = AdminService();

  AdminUser? _user;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _service.getUserById(widget.userId);
      if (!mounted) return;
      setState(() {
        _user = user;
        _selectedRole = user.role;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveRole() async {
    final user = _user;
    if (user == null || _selectedRole == user.role || _saving) return;

    setState(() => _saving = true);
    try {
      final updated = await _service.updateUserRole(user.id, _selectedRole);
      if (!mounted) return;
      setState(() => _user = updated);
      _showSnack('Role updated successfully.', AppColors.success);
    } catch (error) {
      if (!mounted) return;
      _showSnack(_errorMessage(error), AppColors.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiError) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'User Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: _errorCard(_error!),
      );
    }

    final user = _user;
    if (user == null) {
      return const Center(
        child: Text(
          'User not found.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _header(user),
        const SizedBox(height: 16),
        _accountCard(user),
        const SizedBox(height: 16),
        _roleEditor(user),
        const SizedBox(height: 16),
        _profileCard(user),
      ],
    );
  }

  Widget _header(AdminUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountCard(AdminUser user) {
    return _SectionCard(
      title: 'Account',
      children: [
        _detailRow('ID', user.id),
        _detailRow('Email', user.email),
        _detailRow('Role', user.role),
        _detailRow('Email Verified', user.emailVerifiedAt ?? 'Not verified'),
      ],
    );
  }

  Widget _roleEditor(AdminUser user) {
    return _SectionCard(
      title: 'Change Role',
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _inputDecoration('Role'),
          items: const [
            DropdownMenuItem(value: 'user', child: Text('User')),
            DropdownMenuItem(value: 'coach', child: Text('Coach')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedRole = value);
          },
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _saving || _selectedRole == user.role ? null : _saveRole,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save Role'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileCard(AdminUser user) {
    final entries = user.profile.entries.toList();
    return _SectionCard(
      title: 'Profile',
      children: entries.isEmpty
          ? const [
              Text(
                'No profile data returned.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ]
          : entries
                .map(
                  (entry) => _detailRow(
                    _title(entry.key),
                    entry.value == null || entry.value.toString().isEmpty
                        ? 'Not set'
                        : entry.value.toString(),
                  ),
                )
                .toList(),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
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
            onPressed: _loadUser,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary),
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

  String _title(String value) {
    return value
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
