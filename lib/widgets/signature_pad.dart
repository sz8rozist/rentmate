import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import 'package:signature/signature.dart';

class SignaturePad extends StatefulWidget {
  final void Function(Uint8List image) onDone;
  const SignaturePad({super.key, required this.onDone});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final controller = SignatureController(penStrokeWidth: 3, penColor: Colors.black);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Signature(
            controller: controller,
            backgroundColor: Colors.grey[200]!,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () => controller.clear(),
              child: const Text('Törlés'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = await controller.toPngBytes();
                if (data != null) {
                  widget.onDone(data);
                } else {
                  CustomSnackBar.warning(context, 'Nem készült aláírás');
                }
              },
              child: const Text('Mentés'),
            ),
          ],
        ),
      ],
    );
  }
}
