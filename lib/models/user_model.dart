import 'package:rentmate/models/user_role.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole? role;
  final String? flatId;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role,
    this.flatId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRoleExtension.fromValue(json['role'] as String),
      flatId: json['flat_id'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'role': role?.value};
  }

  UserModel copyWith({String? flatId}) {
    return UserModel(
      id: id,
      role: role,
      email: email,
      name: name,
      flatId: flatId ?? this.flatId,
    );
  }
}
