import 'package:riverpod/riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';

// Provider beállítás
final authServiceProvider = Provider((ref) => AuthService());
final authRepositoryProvider = Provider((ref) => AuthRepository(ref.read(authServiceProvider)));

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AsyncValue<UserModel?>>(
      (ref) => AuthViewModel(ref),
);

class AuthViewModel extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref ref;

  AuthViewModel(this.ref) : super(const AsyncValue.data(null));

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user =
      await ref.read(authRepositoryProvider).signUp(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user =
      await ref.read(authRepositoryProvider).login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}