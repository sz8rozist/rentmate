import 'package:flutter/material.dart';

enum InvoiceStatus { kiallitva, fizetve, lejart }

extension InvoiceStatusExtension on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.kiallitva:
        return 'Kiállítva';
      case InvoiceStatus.fizetve:
        return 'Fizetve';
      case InvoiceStatus.lejart:
        return 'Lejárt';
    }
  }

  String get value {
    switch (this) {
      case InvoiceStatus.kiallitva:
        return 'kiallitva';
      case InvoiceStatus.fizetve:
        return 'fizetve';
      case InvoiceStatus.lejart:
        return 'lejart';
    }
  }

  IconData get icon {
    switch (this) {
      case InvoiceStatus.kiallitva:
        return Icons.house;
      case InvoiceStatus.fizetve:
        return Icons.person;
      case InvoiceStatus.lejart:
        return Icons.add;
    }
  }

  static InvoiceStatus? fromValue(String value) {
    return InvoiceStatus.values.firstWhere(
          (e) => e.value == value,
      orElse: () => InvoiceStatus.kiallitva,
    );
  }

  static String getLabel(String status) {
    switch (status) {
      case 'kiallitva':
        return 'Kiadva';
      case 'fizetve':
        return 'Fizetve';
      case 'lejart':
        return 'Lejárt';
      default:
        return 'Ismeretlen';
    }
  }

  static Color getColor(String status) {
    switch (status) {
      case 'kiallitva':
        return Colors.orange;
      case 'fizetve':
        return Colors.green;
      case 'lejart':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
