import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../GraphQLConfig.dart';
import '../models/acces_token.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<AuthState>>(
      (ref) => AuthViewModel(ref)..checkLogin(),
    );

final roleProvider = StateProvider<UserRole?>((ref) => UserRole.tenant);
final biometricVerifiedProvider = StateProvider<bool>((ref) => false);

class AuthViewModel extends StateNotifier<AsyncValue<AuthState>> {
  final Ref ref;

  AuthViewModel(this.ref) : super(const AsyncValue.loading());

  Future<void> checkLogin() async {
    try {
      final token = await ref.read(authServiceProvider).getToken();
      AccessToken? payload;
      if (token != null) {
        payload = await _decodePayload(token);
      }
      state = AsyncValue.data(AuthState(token: token, payload: payload));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final token = await ref.read(authServiceProvider).login(email, password);
      ref.read(tokenProvider.notifier).state = token;
      final payload = await _decodePayload(token);
      state = AsyncValue.data(AuthState(token: token, payload: payload));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = AsyncValue.data(AuthState(token: null, payload: null));
  }

  Future<UserModel?> register(
    String email,
    UserRole role,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(authServiceProvider)
          .register(email, password, name, role);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
    return null;
  }

  Future<AccessToken?> _decodePayload(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT');
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payloadMap = json.decode(decoded);
      print(payloadMap);
      return AccessToken.fromJson(payloadMap);
    } catch (e) {
      return null;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(graphQLClientProvider);
  // Ahol a GraphQLClient van definiálva
  final storage = FlutterSecureStorage();
  return AuthService(client: client.value, storage: storage);
});
