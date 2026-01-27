import '../../models/user_role.dart';

class RegisterState {
  final String email;
  final String name;
  final String password;
  final UserRole role;

  final String? emailError;
  final String? nameError;
  final String? passwordError;
  final String? roleError;

  final bool isLoading;
  final String? generalError;

  const RegisterState({
    this.email = '',
    this.name = '',
    this.password = '',
    this.role = UserRole.tenant,
    this.emailError,
    this.nameError,
    this.passwordError,
    this.roleError,
    this.isLoading = false,
    this.generalError,
  });

  RegisterState copyWith({
    String? email,
    String? name,
    String? password,
    UserRole? role,
    String? emailError,
    String? nameError,
    String? passwordError,
    String? roleError,
    bool? isLoading,
    String? generalError,
  }) {
    return RegisterState(
        email: email ?? this.email,
        name: name ?? this.name,
        password: password ?? this.password,
        role: role ?? this.role,
        emailError: emailError,
        nameError: nameError,
        passwordError: passwordError
    );
  }
}
