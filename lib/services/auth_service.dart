import 'package:rentmate/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    final result = await _client.auth.signUp(email: email, password: password);
    final userId = result.user?.id;

    if (userId == null) {
      throw Exception('Nem sikerült regisztrálni a felhasználót.');
    }

    final user = UserModel(id: userId, email: email, name: name);
    await _client.from('users').insert(user.toJson());
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final userId = result.user?.id;
    if (userId == null) {
      throw Exception('Hibás e-mail vagy jelszó.');
    }

    // Felhasználó lekérése a saját users táblából
    final response =
        await _client.from('users').select().eq('id', userId).single();

    return UserModel.fromJson(response);
  }

  User? get currentUser => _client.auth.currentUser;
}
