import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/flat_selector_viewmodel.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../viewmodels/document_viewmodel.dart';
import '../viewmodels/theme_provider.dart';

class DocumentUploadPage extends ConsumerStatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  ConsumerState<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends ConsumerState<DocumentUploadPage> {
  String _selectedCategory = "Szerződés";
  static const List<String> _categories = [
    "Szerződés",
    "Számla",
    "Kép",
    "Egyéb",
  ];
  final List<File> _selectedFiles = [];
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      final files =
          result.paths
              .map((p) => p != null ? File(p) : null)
              .whereType<File>()
              .toList();
      setState(() {
        _selectedFiles.addAll(files);
      });
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nincs kiválasztott fájl.')));
    }
  }

  Future<void> _submit(String flatId) async {
    if (_selectedFiles.isEmpty) {
      CustomSnackBar.error(context, 'Nincs kiválasztott fájl.');
      return;
    }
    print(flatId);
    setState(() => _isUploading = true);
    final vm = ref.read(documentViewModelProvider(flatId).notifier);
    try {
      for (var file in List<File>.from(_selectedFiles)) {
        await vm.uploadFile(file, _selectedCategory);
      }
      setState(() => _selectedFiles.clear());
      CustomSnackBar.success(context, 'Fájl(ok) sikeresen feltöltve.');
    } catch (e) {
      print(e);
      CustomSnackBar.error(context, 'Hiba történt: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFlat = ref.watch(selectedFlatProvider);
    if (selectedFlat == null) {
      return const Scaffold(
        body: Center(child: Text("Nincs kiválasztott lakás")),
      );
    }
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
                color:
                    ref.watch(themeModeProvider) == ThemeMode.dark
                        ? Colors.black.withOpacity(0.5)
                        : Colors.black.withOpacity(0.2),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  60,
                  MediaQuery.of(context).padding.top,
                  16,
                  0,
                ),
                child: const Align(
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
              items:
                  _categories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
              decoration: const InputDecoration(labelText: "Kategória"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text("Fájl(ok) kiválasztása"),
              onPressed: _isUploading ? null : _pickFiles,
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _selectedFiles.isEmpty
                      ? const Center(child: Text('Nincs kiválasztott fájl.'))
                      : ListView.builder(
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, i) {
                          final f = _selectedFiles[i];
                          final name = f.path.split('/').last;
                          final ext = name.split('.').last.toLowerCase();
                          final isImage = ['jpg', 'jpeg', 'png'].contains(ext);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading:
                                  isImage
                                      ? Image.file(
                                        f,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                      : const Icon(Icons.insert_drive_file),
                              title: Text(name),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    _isUploading
                                        ? null
                                        : () => setState(
                                          () => _selectedFiles.removeAt(i),
                                        ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () => _submit(selectedFlat.id as String),
              child: const Text('Feltöltés'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
