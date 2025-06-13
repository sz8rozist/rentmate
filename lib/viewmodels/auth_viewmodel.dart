import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

// Provider beállítás
final authServiceProvider = Provider((ref) => AuthService());

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<UserModel?>>(
      (ref) => AuthViewModel(ref),
    );

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.read(authServiceProvider);

  return Supabase.instance.client.auth.onAuthStateChange.asyncMap((event) async {
    final user = event.session?.user;
    if (user == null) return null;

    return await authService.fetchUserModel(user.id);
  });
});

final roleProvider = StateProvider<UserRole?>((ref) => UserRole.tenant);

class AuthViewModel extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref ref;

  AuthViewModel(this.ref) : super(const AsyncValue.data(null));

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);

      await authService.registerUser(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      state = const AsyncData(null); // Vagy beállíthatod az aktuális usert is
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signIn(email: email, password: password);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
  }
}
