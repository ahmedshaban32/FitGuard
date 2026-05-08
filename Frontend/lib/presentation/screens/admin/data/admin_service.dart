import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/network/api_service.dart';
import 'package:fit_guard_app/presentation/screens/admin/data/admin_models.dart';

class AdminService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _api.get('/admin/dashboard');
    if (response is ApiError) throw response;
    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return <String, dynamic>{};
  }

  Future<AdminUsersPage> getUsers({
    required int page,
    int limit = 20,
    String? role,
    String? search,
  }) async {
    final response = await _api.get(
      '/admin/users',
      query: {
        'page': page,
        'limit': limit,
        if (role != null && role.isNotEmpty) 'role': role,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    if (response is ApiError) throw response;
    return _parseUsersPage(response, page, limit);
  }

  Future<AdminUser> getUserById(String id) async {
    final response = await _api.get('/admin/users/$id');
    if (response is ApiError) throw response;
    return _parseUserResponse(response);
  }

  Future<AdminUser> updateUserRole(String id, String role) async {
    final response = await _api.patch('/admin/users/$id/role', {'role': role});
    if (response is ApiError) throw response;
    return _parseUserResponse(response);
  }

  AdminUsersPage _parseUsersPage(
    dynamic response,
    int fallbackPage,
    int limit,
  ) {
    if (response is List) {
      final users = response
          .whereType<Map>()
          .map((item) => AdminUser.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return AdminUsersPage(
        users: users,
        page: fallbackPage,
        limit: limit,
        total: users.length,
        totalPages: 1,
      );
    }

    final map = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final rawUsers = _firstList(map, const ['users', 'data', 'items']);
    final users = rawUsers
        .whereType<Map>()
        .map((item) => AdminUser.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    final pagination = map['pagination'] is Map
        ? Map<String, dynamic>.from(map['pagination'] as Map)
        : <String, dynamic>{};
    final total = _readInt(pagination['total'] ?? map['total'], users.length);
    final parsedLimit = _readInt(
      pagination['limit'] ?? map['limit'],
      limit,
    ).clamp(1, 100);
    final totalPages = _readInt(
      pagination['totalPages'] ?? map['totalPages'],
      (total / parsedLimit).ceil().clamp(1, 999999),
    );

    return AdminUsersPage(
      users: users,
      page: _readInt(pagination['page'] ?? map['page'], fallbackPage),
      limit: parsedLimit,
      total: total,
      totalPages: totalPages <= 0 ? 1 : totalPages,
    );
  }

  AdminUser _parseUserResponse(dynamic response) {
    final map = response is Map
        ? Map<String, dynamic>.from(response)
        : <String, dynamic>{};
    final user = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'] as Map)
        : map;
    return AdminUser.fromJson(user);
  }

  List<dynamic> _firstList(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value;
    }
    return const [];
  }

  int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
