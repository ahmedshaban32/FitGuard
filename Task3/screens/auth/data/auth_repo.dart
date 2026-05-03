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

  // =========================
  // LOGIN
  // =========================
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await apiService.post('/login', {
        'email': email,
        'password': password,
      });

      if (response is ApiError) throw response;

      final code = response['code'];
      final data = response['data'];
      final msg = response['message'];

      if (code != 200 && code != 201) {
        throw ApiError(message: msg ?? 'Login failed');
      }

      final user = UserModel.fromJson(data);

      if (user.token == null || user.token!.isEmpty) {
        throw ApiError(message: 'No token returned from server');
      }

      await PrefHelper.saveUser(
        name: user.name,
        email: user.email,
        token: user.token!,
        image: user.image,
      );

      _isGuest = false;
      _currentUser = user;

      return user;
    } on DioError catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // =========================
  // SIGNUP
  // =========================
  Future<UserModel?> signup(String name, String email, String password) async {
    try {
      final response = await apiService.post('/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response is ApiError) throw response;

      final code = response['code'];
      final data = response['data'];
      final msg = response['message'];

      if (code != 200 && code != 201) {
        throw ApiError(message: msg ?? 'Signup failed');
      }

      final user = UserModel.fromJson(data);

      if (user.token == null || user.token!.isEmpty) {
        throw ApiError(message: 'No token returned from server');
      }

      await PrefHelper.saveUser(
        name: user.name,
        email: user.email,
        token: user.token!,
        image: user.image,
      );

      _isGuest = false;
      _currentUser = user;

      return user;
    } on DioError catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // =========================
  // AUTO LOGIN
  // =========================
  Future<UserModel?> autoLogin() async {
    final token = await PrefHelper.getToken();

    if (token == null || token == 'guest') {
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

  // =========================
  // GET PROFILE
  // =========================
  Future<UserModel?> getProfileData() async {
    try {
      final response = await apiService.get('/profile');

      if (response is ApiError) throw response;

      final user = UserModel.fromJson(response['data']);
      _currentUser = user;
      return user;
    } on DioError catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // =========================
  // UPDATE PROFILE
  // =========================
  Future<UserModel?> updateProfileData({
    required String name,
    required String email,
    required String address,
    String? visa,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'address': address,
        if (visa != null && visa.isNotEmpty) 'visa': visa,
        if (imagePath != null && imagePath.isNotEmpty)
          'image': await MultipartFile.fromFile(imagePath),
      });

      final response = await apiService.post('/update-profile', formData);

      if (response is ApiError) throw response;

      final code = response['code'];
      final data = response['data'];
      final msg = response['message'];

      if (code != 200 && code != 201) {
        throw ApiError(message: msg ?? 'Update failed');
      }

      final user = UserModel.fromJson(data);
      _currentUser = user;
      return user;
    } on DioError catch (e) {
      throw ApiExceptions.handleError(e);
    } catch (e) {
      throw ApiError(message: e.toString());
    }
  }

  // =========================
  // CONTINUE AS GUEST
  // =========================
  Future<void> continueAsGuest() async {
    await PrefHelper.continueAsGuest();
    _isGuest = true;
    _currentUser = null;
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    try {
      await apiService.post('/logout', {});
    } catch (_) {}

    await PrefHelper.clearAll();
    _isGuest = true;
    _currentUser = null;
  }

  // =========================
  // GETTERS
  // =========================
  UserModel? get currentUser => _currentUser;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => !_isGuest && _currentUser != null;
}
