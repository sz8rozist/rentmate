import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/viewmodels/states/RegisterState.dart';

import '../services/auth_service.dart';
import '../models/user_role.dart';
import 'auth_viewmodel.dart';

final registerViewModelProvider =
StateNotifierProvider<RegisterViewModel, RegisterState>(
      (ref) => RegisterViewModel(ref),
);

class RegisterViewModel extends StateNotifier<RegisterState> {
  final Ref ref;

  RegisterViewModel(this.ref) : super(const RegisterState());

  // ───── FIELD UPDATERS ─────

  void onEmailChanged(String v) {
    state = state.copyWith(email: v, emailError: null);
  }

  void onNameChanged(String v) {
    state = state.copyWith(name: v, nameError: null);
  }

  void onPasswordChanged(String v) {
    state = state.copyWith(password: v, passwordError: null);
  }

  void onRoleChanged(UserRole? role) {
    if (role == null) return;
    state = state.copyWith(role: role, roleError: null);
  }

  // ───── SUBMIT ─────

  Future<void> submit() async {
    if (!_validate()) return;

    state = state.copyWith(isLoading: true, generalError: null);

    try {
      final token = await ref.read(authServiceProvider).register(
        state.email,
        state.password,
        state.name,
        state.role,
      );

      // automatikus beléptetés
      await ref.read(authViewModelProvider.notifier).setSession(token as String);
    } catch (e) {
      _handleError(e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ───── VALIDATION ─────

  bool _validate() {
    bool valid = true;

    if (state.email.isEmpty) {
      state = state.copyWith(emailError: 'Email kötelező');
      valid = false;
    } else if (!state.email.contains('@')) {
      state = state.copyWith(emailError: 'Érvénytelen email');
      valid = false;
    }

    if (state.name.isEmpty) {
      state = state.copyWith(nameError: 'Név kötelező');
      valid = false;
    }

    if (state.password.length < 6) {
      state = state.copyWith(
        passwordError: 'Minimum 6 karakter',
      );
      valid = false;
    }

    return valid;
  }

  // ───── BACKEND ERROR MAPPING ─────

  void _handleError(Object e) {
   /* if (e is Ex) {
      state = state.copyWith(
        emailError: e.errors['email'],
        nameError: e.errors['name'],
        passwordError: e.errors['password'],
        roleError: e.errors['role'],
      );
    } else {
      state = state.copyWith(
        generalError: 'Regisztráció sikertelen',
      );
    }*/
  }
}
