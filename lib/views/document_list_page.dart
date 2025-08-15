import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rentmate/models/document_model.dart';
import 'package:rentmate/models/user_role.dart';
import 'package:rentmate/routing/app_router.dart';
import 'package:rentmate/viewmodels/auth_viewmodel.dart';
import 'package:rentmate/widgets/custom_snackbar.dart';
import '../viewmodels/document_viewmodel.dart';
import '../viewmodels/theme_provider.dart';

class DocumentListPage extends ConsumerStatefulWidget {
  final String flatId;

  const DocumentListPage({super.key, required this.flatId});

  @override
  ConsumerState<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends ConsumerState<DocumentListPage> {
  static const List<String> _categories = [
    "Mind",
    "Szerződés",
    "Számla",
    "Kép",
    "Egyéb",
  ];

  String selectedCategory = "Mind";

  @override
  void initState() {
    super.initState();
    // A loadDocuments hívása a widget létrejöttekor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentViewModelProvider(widget.flatId)).loadDocuments();
    });
  }

  void _openPdf(BuildContext context, String url) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/temp.pdf');
    await file.writeAsBytes(bytes, flush: true);
    context.go('/view-pdf?filePath=${Uri.encodeComponent(file.path)}');
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _downloadFile(BuildContext context, Document document) async {
    try {
      // Engedély kérése
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          CustomSnackBar.warning(context, "A mentéshez engedély szükséges!");
          await Future.delayed(Duration(seconds: 2));
          openAppSettings();
          return;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request(); // vagy mediaLibrary
        if (!status.isGranted) {
          CustomSnackBar.warning(context, "A mentéshez engedély szükséges!");
          await Future.delayed(Duration(seconds: 2));
          openAppSettings();
          return;
        }
      }

      // Letöltés
      final response = await http.get(Uri.parse(document.url));
      if (response.statusCode != 200) {
        CustomSnackBar.error(context, "Sikertelen letöltés.");
        return;
      }

      final bytes = response.bodyBytes;
      final ext = document.filePath.split(".").last;

      // Mentés fájlválasztással
      final savedPath = await FileSaver.instance.saveFile(
        name: document.name,
        bytes: bytes,
        fileExtension: ext,
        mimeType: getMimeTypeFromExtension(ext),
      );

      CustomSnackBar.success(context, 'Fájl mentve: $savedPath');
    } catch (e) {
      print("Download error: $e");
      CustomSnackBar.error(context, 'Hiba történt: $e');
    }
  }

  MimeType getMimeTypeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return MimeType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return MimeType.jpeg;
      case 'mp3':
      case 'wav':
        return MimeType.mp3;
      case 'mp4':
      case 'mov':
      case 'avi':
        return MimeType.mp4Video;
      case 'txt':
      case 'csv':
      case 'json':
        return MimeType.text;
      case 'xml':
        return MimeType.xml;
      case 'doc':
      case 'docx':
        return MimeType.microsoftWord;
      case 'xls':
      case 'xlsx':
        return MimeType.microsoftExcel;
      default:
        return MimeType.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(documentViewModelProvider(widget.flatId));
    final authState = ref.read(authViewModelProvider);
    final payload = authState.asData?.value.payload;
    final filteredDocs =
        selectedCategory == "Mind"
            ? vm.documents
            : vm.documents
                .where((doc) => doc.category == selectedCategory)
                .toList();
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
                    'Dokumentumok',
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
      body: Column(
        children: [
          // Kategória szűrő
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _categories.map((category) {
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh:
                  () async =>
                      ref
                          .read(documentViewModelProvider(widget.flatId))
                          .loadDocuments(),
              child:
                  filteredDocs.isEmpty
                      ? const Center(
                        child: Text("Nincs dokumentum ebben a kategóriában."),
                      )
                      : ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: Icon(_iconForType(doc.type), size: 32),
                              title: Text(doc.name),
                              subtitle: Text(
                                'Kategória: ${doc.category}\n${doc.uploadedAt.toString()}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    color: Colors.green,
                                    onPressed:
                                        () => _downloadFile(context, doc),
                                  ),
                                  if (doc.type.toLowerCase() == 'pdf')
                                    const Icon(
                                      Icons.visibility,
                                      color: Colors.blue,
                                    ),
                                  if (payload?.role == UserRole.landlord)
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      onPressed: () async {
                                        await ref
                                            .read(
                                              documentViewModelProvider(
                                                widget.flatId,
                                              ),
                                            )
                                            .delete(doc);
                                      },
                                    ),
                                ],
                              ),
                              onTap:
                                  doc.type.toLowerCase() == 'pdf'
                                      ? () => _openPdf(context, doc.url)
                                      : null,
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
