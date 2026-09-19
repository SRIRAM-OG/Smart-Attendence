import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<User> login({required String email, required String password}) async {
    try {
      final response = await _api.dio.post(
        ApiConfig.login,
        data: {'email': email.trim(), 'password': password},
      );

      final data = response.data['data'];
      final user = User.fromJson(data['user']);
      final accessToken = data['tokens']['accessToken'];
      final refreshToken = data['tokens']['refreshToken'];

      await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _storage.saveUser(user);

      return user;
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String enrollmentNumber,
    required String departmentId,
    int semester = 1,
    String section = 'A',
  }) async {
    try {
      final response = await _api.dio.post(
        ApiConfig.register,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'enrollmentNumber': enrollmentNumber.trim(),
          'departmentId': departmentId,
          'semester': semester,
          'section': section.trim(),
        },
      );

      final data = response.data['data'];
      final user = User.fromJson(data['user']);
      final accessToken = data['tokens']['accessToken'];
      final refreshToken = data['tokens']['refreshToken'];

      await _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _storage.saveUser(user);

      return user;
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<User?> getMe() async {
    try {
      final response = await _api.dio.get(ApiConfig.me);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']);
        await _storage.saveUser(user);
        return user;
      }
      return null;
    } catch (_) {
      return await _storage.getUser();
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post(ApiConfig.logout);
    } catch (_) {
      // Best effort logout
    } finally {
      await _storage.clearAll();
    }
  }
}
