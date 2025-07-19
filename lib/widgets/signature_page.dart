import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class SignaturePage extends StatefulWidget {
  final void Function(Uint8List image) onDone;
  const SignaturePage({super.key, required this.onDone});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final controller = SignatureController(penStrokeWidth: 3, penColor: Colors.black);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aláírás")),
      body: Column(
        children: [
          Signature(controller: controller, height: 300, backgroundColor: Colors.grey[300]!),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(onPressed: controller.clear, child: const Text("Törlés")),
              ElevatedButton(
                onPressed: () async {
                  final img = await controller.toPngBytes();
                  if (img != null) widget.onDone(img);
                  Navigator.of(context).pop();
                },
                child: const Text("Kész"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
