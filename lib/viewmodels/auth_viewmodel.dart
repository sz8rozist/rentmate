import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../rest_api_config.dart';
import '../models/acces_token.dart';
import '../models/auth_state.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

final authViewModelProvider =
StateNotifierProvider<AuthViewModel, AsyncValue<AuthState>>(
      (ref) => AuthViewModel(ref)..initialize(),
);

final roleProvider = StateProvider<UserRole?>((ref) => UserRole.tenant);
final biometricVerifiedProvider = StateProvider<bool>((ref) => false);

final currentUserPayloadProvider = Provider<AccessToken?>((ref) {
  final authState = ref.watch(authViewModelProvider);
  return authState.asData?.value.payload;
});

final currentUserIdProvider = Provider<int?>((ref) {
  final payload = ref.watch(currentUserPayloadProvider);
  return payload?.userId;
});

class AuthViewModel extends StateNotifier<AsyncValue<AuthState>> {
  final Ref ref;
  AuthViewModel(this.ref) : super(const AsyncValue.loading());

  /// Inicializálás: token betöltése és ellenőrzése
  Future<void> initialize() async {
    try {
      final token = await ref.read(authServiceProvider).getToken();
      if (token != null && !_isTokenExpired(token)) {
        final payload = _decodePayload(token);
        state = AsyncValue.data(AuthState(token: token, payload: payload));
      } else {
        // token nincs vagy lejárt
        await logout();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final token = await ref.read(authServiceProvider).login(email, password);
      final payload = _decodePayload(token);
      state = AsyncValue.data(AuthState(token: token, payload: payload));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = AsyncValue.data(AuthState.empty());
  }

  AccessToken? _decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT');
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payloadMap = json.decode(decoded);
      return AccessToken.fromJson(payloadMap);
    } catch (e) {
      return null;
    }
  }

  bool _isTokenExpired(String token) {
    final payload = _decodePayload(token);
    if (payload == null) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(payload.exp! * 1000);
    return DateTime.now().isAfter(expiry);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    apiService: ref.watch(apiServiceProvider),
    storage: FlutterSecureStorage(),
  );
});
