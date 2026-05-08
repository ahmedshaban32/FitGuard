import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrefHelper {
  static const String _tokenKey = 'auth_token';
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _imageKey = 'user_image';
  static const String _roleKey = 'user_role';
  static const String _userInfoKey = 'user_info'; // ← NEW

  // ═══════════════════════════════════════════════
  // SAVE
  // ═══════════════════════════════════════════════

  static Future<void> saveUser({
    required String name,
    required String email,
    required String token,
    String? image,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    if (role != null && role.isNotEmpty) {
      await prefs.setString(_roleKey, role);
    }
    if (image != null && image.isNotEmpty) {
      await prefs.setString(_imageKey, image);
    }
  }

  /// Guest mode — does NOT save token so AuthGate won't auto-login
  static Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, 'Guest');
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_imageKey);
    await prefs.remove(_roleKey);
  }

  /// Save full fitness profile from UserInfoScreen
  /// [payload] is the Map built by _buildPayload() in UserInfoScreen
  static Future<void> saveUserInfo(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userInfoKey, jsonEncode(payload));
  }

  // ═══════════════════════════════════════════════
  // GET
  // ═══════════════════════════════════════════════

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? 'Guest';
  }

  static Future<String?> getUserImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_imageKey);
  }

  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? '';
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey) ?? 'user';
  }

  /// Returns the full fitness profile saved from UserInfoScreen.
  /// Returns null if the user has not completed onboarding yet.
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userInfoKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Shortcut helpers for individual profile fields
  static Future<int?> getUserAge() async {
    final info = await getUserInfo();
    return info?['profile']?['age'] as int?;
  }

  static Future<String?> getUserGoal() async {
    final info = await getUserInfo();
    return info?['profile']?['goal'] as String?;
  }

  static Future<String?> getUserActivityLevel() async {
    final info = await getUserInfo();
    return info?['profile']?['activity_level'] as String?;
  }

  static Future<int?> getUserWeight() async {
    final info = await getUserInfo();
    return info?['profile']?['weight_kg'] as int?;
  }

  static Future<int?> getUserHeight() async {
    final info = await getUserInfo();
    return info?['profile']?['height_cm'] as int?;
  }

  static Future<bool> hasCompletedOnboarding() async {
    final info = await getUserInfo();
    return info != null;
  }

  // ═══════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Alias — same as clearUser
  static Future<void> clearAll() async => clearUser();
}
