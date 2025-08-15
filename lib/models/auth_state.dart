import 'acces_token.dart';

class AuthState {
  final String? token;
  final AccessToken? payload;

  AuthState({this.token, this.payload});

  AuthState copyWith({String? token, AccessToken? payload}) {
    return AuthState(
      token: token ?? this.token,
      payload: payload ?? this.payload,
    );
  }
}