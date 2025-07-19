import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rentmate/routing/app_router.dart';
import '../viewmodels/document_viewmodel.dart';
import '../viewmodels/theme_provider.dart';

class DocumentListPage extends ConsumerWidget {
  final String flatId;
  const DocumentListPage({super.key, required this.flatId});

  void _openPdf(BuildContext context, String url) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/temp.pdf');
    await file.writeAsBytes(bytes, flush: true);
    context.go('/view-pdf?filePath=${Uri.encodeComponent(file.path)}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(documentViewModelProvider(flatId));

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80 + MediaQuery.of(context).padding.top),
        child: SizedBox(
          height: 80 + MediaQuery.of(context).padding.top,
          width: double.infinity,
          // A háttér lefedi a státusz sávot is
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/header-image.png', fit: BoxFit.cover),
              Container(color: ref.watch(themeModeProvider) == ThemeMode.dark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.2),
              ),
              // A tartalmat beljebb húzzuk, hogy ne lógjon be a status bar területére
              Padding(
                padding: EdgeInsets.fromLTRB(60, MediaQuery.of(context).padding.top, 16, 0),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Dokumentumok',
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
      body: RefreshIndicator(
        onRefresh: () async => ref.read(documentViewModelProvider(flatId)).loadDocuments(),
        child:
            vm.documents.isEmpty
                ? const Center(child: Text("Nincs dokumentum"))
                : ListView.builder(
                  itemCount: vm.documents.length,
                  itemBuilder: (context, index) {
                    final doc = vm.documents[index];
                    return ListTile(
                      title: Text(doc.name),
                      subtitle: Text(doc.uploadedAt.toString()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await ref.read(documentViewModelProvider(flatId)).delete(doc);
                        },
                      ),
                      onTap: () => _openPdf(context, doc.url),
                    );
                  },
                ),
      ),
    );
  }
}
