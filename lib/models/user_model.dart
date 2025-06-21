import 'package:rentmate/models/user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole? role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRoleExtension.fromValue(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role?.value
    };
  }
}
