import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomTextFormField extends ConsumerWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool filled;
  final Color? fillColor;
  final int maxLines;
  final bool obscureText;
  final String obscuringCharacter;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.filled = true,
    this.fillColor = Colors.white,
    this.maxLines = 1,
    this.obscureText = false,
    this.obscuringCharacter = "*"
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputTheme = Theme.of(context);
    final baseDecoration = InputDecoration().applyDefaults(inputTheme.inputDecorationTheme);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      obscureText: obscureText,
        obscuringCharacter: obscuringCharacter,
        decoration: baseDecoration.copyWith(labelText: labelText)
    );
  }
}
