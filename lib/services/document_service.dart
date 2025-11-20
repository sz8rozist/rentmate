import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/document_model.dart';

class DocumentService {
  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String> uploadFile(File file) async {
    final originalName = file.path.split('/').last;
    if (originalName.trim().isEmpty || !originalName.contains('.')) {
      throw Exception('Érvénytelen fájlnév: $originalName');
    }
    final ext = _getExtension(originalName);
    final uuidName = _uuid.v4();
    final storageKey = '$uuidName.$ext';

    await _client.storage.from('documents').upload(storageKey, file);

    return storageKey;
  }

  Future<String> uploadBytes(Uint8List bytes, String originalName) async {
    final ext = _getExtension(originalName);
    final uuidName = _uuid.v4();
    final storageKey = '$uuidName.$ext';

    await _client.storage.from('documents').uploadBinary(storageKey, bytes);

    return storageKey;
  }

  Future<void> saveMetadata({
    required String originalName,
    required String storageKey,
    required String category,
    required String flatId,
  }) async {
    final ext = _getExtension(originalName);
    final url = _client.storage.from('documents').getPublicUrl(storageKey);

    await _client.from('documents').insert({
      'id': _uuid.v4(),
      'name': originalName,
      'url': url,
      'type': ext,
      'category': category,
      'file_path': storageKey,
      'flat_id': flatId,
      'uploaded_at': DateTime.now().toIso8601String(),
    });
  }

  String _getExtension(String name) {
    if (!name.contains('.')) return 'unknown';
    final ext = name.split('.').last.trim().toLowerCase();
    return ext.isEmpty ? 'unknown' : ext;
  }

  Future<List<Document>> getDocuments(String flatId) async {
    final res = await _client
        .from('documents')
        .select()
        .eq("flat_id", flatId)
        .order('uploaded_at', ascending: false);
    return (res as List).map((e) => Document.fromMap(e)).toList();
  }

  Future<void> deleteDocument(Document doc) async {
    //await _client.storage.from('documents').remove([doc.filePath]);
    //await _client.from('documents').delete().eq('id', doc.id);
  }
}
