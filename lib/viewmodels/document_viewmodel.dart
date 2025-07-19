import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/document_model.dart';
import '../services/document_service.dart';

final documentViewModelProvider = ChangeNotifierProvider.family<DocumentViewModel, String>(
      (ref, flatId) => DocumentViewModel(flatId),
);

class DocumentViewModel extends ChangeNotifier {
  final DocumentService _service = DocumentService();
  final String flatId;

  DocumentViewModel(this.flatId);

  List<Document> _documents = [];
  List<Document> get documents => _documents;

  Future<void> loadDocuments() async {
    _documents = await _service.getDocuments(flatId);
    notifyListeners();
  }

  Future<void> uploadFile(File file, String category) async {
    final url = await _service.uploadFile(file);
    await _service.saveMetadata(
      file.path.split('/').last,
      url,
      category,
      flatId,
    );
    await loadDocuments();
  }

  Future<void> uploadBytes(Uint8List bytes, String name, String category) async {
    final url = await _service.uploadBytes(bytes, name);
    await _service.saveMetadata(name, url, category, flatId);
    await loadDocuments();
  }

  Future<void> delete(Document doc) async {
    await _service.deleteDocument(doc);
    await loadDocuments();
  }
}
