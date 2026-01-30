import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rentmate/models/user_model.dart';
import 'package:rentmate/models/user_role.dart';
import 'package:rentmate/rest_api_config.dart';

class AuthService {
  final ApiService apiService;
  final FlutterSecureStorage storage;

  AuthService({required this.apiService, required this.storage});

  /// LOGIN
  Future<String> login(String email, String password) async {
    try {
      final data = await apiService.post(
        '/auth/login',
        {'email': email, 'password': password},
        authRequired: false, // loginhoz még nincs token
      );
      final token = data['accessToken'] as String?;
      if (token == null) throw Exception('Login failed: no token returned');
      // Token tárolása
      await storage.write(key: 'access_token', value: token);
      return token;
    } on DioException catch (e) {
      print('ERROR: ${e.response}');
      rethrow;
    }
  }

  /// REGISTER
  Future<UserModel> register(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    try {
      final data = await apiService.post(
        '/auth/register',
        {
          'email': email,
          'password': password,
          'name': name,
          'role': role.value,
        },
        authRequired: false, // regisztrációhoz nincs token
      );

      return UserModel.fromJson(data);
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  /// TOKEN LEKÉRÉSE
  Future<String?> getToken() async {
    return await storage.read(key: 'access_token');
  }

  /// LOGOUT
  Future<void> logout() async {
    await storage.delete(key: 'access_token');
  }
}
