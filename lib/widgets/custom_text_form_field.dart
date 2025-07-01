import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomTextFormField extends ConsumerWidget {
  final TextEditingController? controller;
  final String labelText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool filled;
  final Color? fillColor;
  final int maxLines;
  final bool obscureText;
  final String obscuringCharacter;
  final String? initialValue;
  final ValueChanged<String>? onChanged;

  const CustomTextFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.filled = true,
    this.fillColor = Colors.white,
    this.maxLines = 1,
    this.obscureText = false,
    this.obscuringCharacter = "*",
    this.initialValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputTheme = Theme.of(context);
    final baseDecoration = InputDecoration().applyDefaults(
      inputTheme.inputDecorationTheme,
    );

    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      onChanged: onChanged,
      obscureText: obscureText,
      obscuringCharacter: obscuringCharacter,
      decoration: baseDecoration.copyWith(labelText: labelText),
    );
  }
}
