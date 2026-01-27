import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/viewmodels/states/LoginState.dart';

import 'auth_viewmodel.dart';

final loginViewModelProvider =
StateNotifierProvider<LoginViewModel, LoginState>(
      (ref) => LoginViewModel(ref),
);

class LoginViewModel extends StateNotifier<LoginState> {
  final Ref ref;

  LoginViewModel(this.ref) : super(const LoginState());

  void onEmailChanged(String v) {
    state = state.copyWith(email: v, emailError: null);
  }

  void onPasswordChanged(String v) {
    state = state.copyWith(password: v, passwordError: null);
  }

  Future<void> submit() async {
    if (!_validate()) return;

    state = state.copyWith(isLoading: true);

    try {
      final token = await ref
          .read(authServiceProvider)
          .login(state.email, state.password);

      await ref.read(authViewModelProvider.notifier)
          .setSession(token);
    } catch (e) {
      //Itt lehet talán a backend errorokat elkapni.
      print(e);
      state = state.copyWith(
        passwordError: 'Hibás email vagy jelszó',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  bool _validate() {
    if (state.email.isEmpty) {
      state = state.copyWith(emailError: 'Email kötelező');
      return false;
    }
    if (state.password.isEmpty) {
      state = state.copyWith(passwordError: 'Jelszó kötelező');
      return false;
    }
    return true;
  }
}
