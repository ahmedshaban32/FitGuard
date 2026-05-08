class AdminUser {
  final String id;
  final String email;
  final String role;
  final Map<String, dynamic> profile;
  final String? emailVerifiedAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    required this.profile,
    this.emailVerifiedAt,
  });

  String get name => (profile['name'] ?? 'No name').toString();

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : <String, dynamic>{};

    return AdminUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      profile: profile,
      emailVerifiedAt: json['emailVerifiedAt']?.toString(),
    );
  }
}

class AdminUsersPage {
  final List<AdminUser> users;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const AdminUsersPage({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });
}
