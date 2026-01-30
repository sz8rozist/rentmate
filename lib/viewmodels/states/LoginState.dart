import '../../form_error_model.dart';

class LoginState {
  final String email;
  final String password;
  final bool isLoading;
  final FormErrors errors;

  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.errors = const FormErrors({}),
  });

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    FormErrors? errors,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errors: errors ?? this.errors,
    );
  }
}
