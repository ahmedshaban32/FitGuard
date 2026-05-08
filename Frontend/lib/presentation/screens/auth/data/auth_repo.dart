import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fit_guard_app/Core/network/api_error.dart';
import 'package:fit_guard_app/Core/network/api_exceptions.dart';
import 'package:fit_guard_app/Core/network/api_service.dart';
import 'package:fit_guard_app/Core/utils/pref_helpers.dart';
import 'package:fit_guard_app/presentation/screens/auth/data/user_model.dart';

class AuthRepo {
  final ApiService apiService = ApiService();

  bool _isGuest = false;
  UserModel? _currentUser;

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response is ApiError) throw response;
      if (response is! Map<String, dynamic>) {
        throw ApiError(message: 'Invalid response from server');
      }

      final token = (response['token'] ?? response['accessToken'])?.toString();
      final userData = response['user'] is Map<String, dynamic>
          ? response['user'] as Map<String, dynamic>
          : response;
      final tokenPayload = _decodeJwt(token ?? '');

      if (token == null || token.isEmpty) {
        throw ApiError(message: 'No token returned from server');
      }

      final user = UserModel.fromJson({
        ...userData,
        'token': token,
        if (userData['role'] == null && tokenPayload['role'] != null)
          'role': tokenPayload['role'],
        if (userData['email'] == null && tokenPayload['email'] != null)
          'email': tokenPayload['email'],
      });

      await PrefHelper.saveUser(
        name: user.name,
        email: user.email,
        token: token,
        image: user.image,
        role: user.role,
      );

      _isGuest = false;
      _currentUser = user;

      return user;
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  Future<UserModel?> signup(
    String name,
    String email,
    String password,
    Map<String, dynamic> profile,
  ) async {
    try {
      final response = await apiService.post('/auth/register', {
        'email': email,
        'password': password,
        'role': 'user',
        'profile': {...profile, 'name': name},
      });

      if (response is ApiError) throw response;

      return await login(email, password);
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  Future<UserModel?> getProfileData() async {
    try {
      final response = await apiService.get('/users/me/profile');

      if (response is ApiError) throw response;
      if (response is! Map<String, dynamic>) {
        throw ApiError(message: 'Invalid response from server');
      }

      final userData = response['user'] is Map<String, dynamic>
          ? response['user'] as Map<String, dynamic>
          : response;
      final user = UserModel.fromJson(userData);

      _currentUser = user;
      return user;
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  Future<UserModel?> autoLogin() async {
    final token = await PrefHelper.getToken();

    if (token == null || token.isEmpty) {
      _isGuest = true;
      _currentUser = null;
      return null;
    }

    try {
      final user = await getProfileData();
      _isGuest = false;
      _currentUser = user;
      return user;
    } catch (_) {
      await PrefHelper.clearAll();
      _isGuest = true;
      _currentUser = null;
      return null;
    }
  }

  Future<void> logout() async {
    await PrefHelper.clearAll();
    _isGuest = true;
    _currentUser = null;
  }

  Future<void> continueAsGuest() async {
    await PrefHelper.continueAsGuest();
    _isGuest = true;
    _currentUser = null;
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await apiService.post('/auth/forgot-password', {
        'email': email,
      });

      if (response is ApiError) throw response;
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await apiService.post('/auth/reset-password', {
        'token': token,
        'newPassword': newPassword,
      });

      if (response is ApiError) throw response;
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      final response = await apiService.get('/auth/verify-email?token=$token');

      if (response is ApiError) throw response;
    } on DioException catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      if (e is ApiError) rethrow;
      throw ApiError(message: e.toString());
    }
  }

  UserModel? get currentUser => _currentUser;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => !_isGuest && _currentUser != null;

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return const {};

    try {
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final data = jsonDecode(decoded);
      return data is Map<String, dynamic> ? data : const {};
    } catch (_) {
      return const {};
    }
  }
}
