import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/viewmodels/states/LoginState.dart';

import '../form_error_model.dart';
import '../handle_backend_form_error.dart';
import 'auth_viewmodel.dart';

final loginViewModelProvider =
StateNotifierProvider<LoginViewModel, LoginState>(
      (ref) => LoginViewModel(ref),
);

class LoginViewModel extends StateNotifier<LoginState> {
  final Ref ref;

  LoginViewModel(this.ref) : super(const LoginState());

  void onEmailChanged(String v) {
    state = state.copyWith(
      email: v,
      errors: state.errors.remove('email'),
    );
  }

  void onPasswordChanged(String v) {
    state = state.copyWith(
      password: v,
      errors: state.errors.remove('password'),
    );
  }

  Future<void> submit() async {
    state = state.copyWith(
      isLoading: true,
      errors: FormErrors.empty(),
    );

    try {
      await ref
          .read(authViewModelProvider.notifier)
          .login(state.email, state.password);
    } catch (e) {
      final formErrors = parseBusinessError(e);

      if (formErrors.hasErrors) {
        state = state.copyWith(errors: formErrors);
      } else {
        rethrow;
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
