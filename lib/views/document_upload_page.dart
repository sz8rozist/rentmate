import 'dart:io';

import 'package:file_picker/file_picker.dart'; // Import the file_picker package
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../viewmodels/theme_provider.dart';

class DocumentUploadPage extends ConsumerStatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  ConsumerState<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends ConsumerState<DocumentUploadPage> {
  String _selectedCategory = "Szerződés"; // Renamed for consistency

  // Made categories a constant since it doesn't change
  static const List<String> _categories = ["Szerződés", "Számla", "Kép", "Egyéb"];

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
              // Overlay for theme mode
              Container(
                color: ref.watch(themeModeProvider) == ThemeMode.dark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.2),
              ),
              // Title text
              Padding(
                padding: EdgeInsets.fromLTRB(60, MediaQuery.of(context).padding.top, 16, 0),
                child: const Align( // Made const as it doesn't change
                  alignment: Alignment.center,
                  child: Text(
                    'Dokumentum feltöltés',
                    style: TextStyle(
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
              // Back button
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
              value: _selectedCategory,
              items: _categories // Use the constant list
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
              decoration: const InputDecoration(labelText: "Kategória"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Use FilePicker to pick a single file
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'], // Added 'jpeg' for completeness
                );

                if (result != null && result.files.single.path != null) {
                  final pickedFile = File(result.files.single.path!);

                  // Your file processing/uploading logic goes here
                  // For example, you can print the file path:
                  debugPrint('Selected file path: ${pickedFile.path}');

                  if (mounted) {
                    CustomSnackBar.success(context,"Dokumentum feltöltve: ${pickedFile.path.split('/').last}");
                  }
                } else {
                  // User canceled the picker
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nincs kiválasztott fájl.')),
                    );
                  }
                }
              },
              child: const Text("Fájl kiválasztása és feltöltése"),
            ),
          ],
        ),
      ),
    );
  }
}