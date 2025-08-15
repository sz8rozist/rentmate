import 'package:rentmate/models/flat_model.dart';
import 'package:rentmate/models/user_role.dart';

class UserModel {
  final int? id;
  final String email;
  final String? password;
  final String name;
  final UserRole? role;
  final Flat? tenantFlat;

  UserModel({
    required this.id,
    required this.email,
    this.password,
    required this.name,
    this.role,
    this.tenantFlat,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    return UserModel(
      id: parsedId,
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: json['role'] != null
          ? UserRoleExtension.fromValue(json['role'].toString())
          : null,
      tenantFlat: (json['tenantFlat'] is Map<String, dynamic>)
          ? Flat.fromJson(json['tenantFlat'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'role': role?.value, 'tenantFlat': tenantFlat?.toJson()};
  }

  UserModel copyWith({Flat? tenantFlat}) {
    return UserModel(
      id: id,
      role: role,
      email: email,
      name: name,
      tenantFlat: tenantFlat ?? this.tenantFlat,
    );
  }
}
