import 'package:flutter/material.dart';
import 'package:flutter_icon_snackbar/flutter_icon_snackbar.dart';

class CustomSnackBar {
  // Sikeres művelet SnackBar-je
  static void success(
    BuildContext context,
    String message, {
    String title = 'Sikeres művelet',
  }) {
    IconSnackBar.show(
      context,
      snackBarType: SnackBarType.success,
      label: message,
      duration: const Duration(seconds: 3),
    );
  }

  // Hiba SnackBar-je
  static void error(
    BuildContext context,
    String message, {
    String title = 'Hiba történt',
  }) {
    IconSnackBar.show(
      context,
      snackBarType: SnackBarType.fail, // Fail típus hibákhoz
      label: message,
      duration: const Duration(seconds: 4),
    );
  }

  // Figyelmeztetés SnackBar-je
  static void warning(
    BuildContext context,
    String message, {
    String title = 'Figyelem',
  }) {
    IconSnackBar.show(
      context,
      snackBarType: SnackBarType.alert, // Warning típus
      label: message,
      duration: const Duration(seconds: 4),
    );
  }
}
