import 'package:flutter/material.dart';

enum UserRole { landlord, tenant }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.landlord:
        return 'Főbérlő';
      case UserRole.tenant:
        return 'Albérlő';
    }
  }

  String get value {
    switch (this) {
      case UserRole.landlord:
        return 'landlord';
      case UserRole.tenant:
        return 'tenant';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.landlord:
        return Icons.house;
      case UserRole.tenant:
        return Icons.person;
    }
  }

  static UserRole? fromValue(String value) {
    return UserRole.values.firstWhere(
          (e) => e.value == value,
      orElse: () => UserRole.tenant,
    );
  }
}
