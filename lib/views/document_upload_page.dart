import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../viewmodels/theme_provider.dart';

class DocumentUploadPage extends ConsumerStatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  ConsumerState<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends ConsumerState<DocumentUploadPage> {
  String selectedCategory = "Szerződés";
  final categories = ["Szerződés", "Számla", "Kép", "Egyéb"];
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    return true;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80 + MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 80 + MediaQuery.of(context).padding.top,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/header-image.png', fit: BoxFit.cover),
              Container(
                color: ref.watch(themeModeProvider) == ThemeMode.dark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.2),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(60, MediaQuery.of(context).padding.top, 16, 0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Dokumentum feltöltés',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: MediaQuery.of(context).padding.top,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.goNamed(AppRoute.home.name),
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value!),
              decoration: const InputDecoration(labelText: "Kategória"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final hasPermission = await requestStoragePermission();
                if (!hasPermission) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Engedély szükséges a fájl kiválasztáshoz.')),
                  );
                  return;
                }
                // file_selector használata:
                final typeGroup = XTypeGroup(
                  label: 'documents',
                  extensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
                );
                final file = await openFile(acceptedTypeGroups: [typeGroup]);

                if (file != null) {
                  final pickedFile = File(file.path);

                  // Itt a fájl feldolgozása, feltöltése stb.
                  ScaffoldMessenger.of(context).showSnackBar(
                    CustomSnackBar.success("Dokumentum feltöltve."),
                  );
                }
              },
              child: const Text("Fájl kiválasztása és feltöltése"),
            ),
          ],
        )
      ),
    );
  }
}
