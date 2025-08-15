import 'package:rentmate/models/user_role.dart';

class AccessToken {
  final UserRole? role;
  final int userId;
  final String email;
  final int iat; // timestampként tároljuk
  final int exp; // timestampként tároljuk

  AccessToken({
    required this.role,
    required this.userId,
    required this.email,
    required this.iat,
    required this.exp,
  });

  factory AccessToken.fromJson(Map<String, dynamic> json) {
    return AccessToken(
      role: UserRoleExtension.fromValue(json['role'] as String),
      userId: json['sub'] is String ? int.parse(json['sub']) : json['sub'] as int,
      email: json['email'] as String,
      iat: json['iat'] is String ? int.parse(json['iat']) : json['iat'] as int,
      exp: json['exp'] is String ? int.parse(json['exp']) : json['exp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role?.value,
      'userId': userId,
      'email': email,
      'iat': iat,
      'exp': exp,
    };
  }
}
