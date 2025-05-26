import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository(this._authService);

  Future<UserModel?> signUp(String email, String password) async {
    final user = await _authService.signUp(email, password);
    if (user == null) return null;
    return UserModel(id: user.id, email: user.email ?? '');
  }

  Future<UserModel?> login(String email, String password) async {
    final user = await _authService.signIn(email, password);
    if (user == null) return null;
    return UserModel(id: user.id, email: user.email ?? '');
  }

  void logout() => _authService.signOut();

  UserModel? getCurrentUser() {
    final user = _authService.currentUser;
    if (user == null) return null;
    return UserModel(id: user.id, email: user.email ?? '');
  }
}