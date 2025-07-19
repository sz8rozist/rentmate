import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';

class DocumentService {
  final _client = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String> uploadFile(File file) async {
    final fileName = "${_uuid.v4()}-${file.path.split('/').last}";
    await _client.storage.from('documents').upload(fileName, file);
    return _client.storage.from('documents').getPublicUrl(fileName);
  }

  Future<String> uploadBytes(Uint8List bytes, String name) async {
    final fileName = "${_uuid.v4()}-$name";
    await _client.storage.from('documents').uploadBinary(fileName, bytes);
    return _client.storage.from('documents').getPublicUrl(fileName);
  }

  Future<void> saveMetadata(String name, String url, String category, String flatId) async {
    await _client.from('documents').insert({
      'id': _uuid.v4(),
      'name': name,
      'url': url,
      'category': category,
      'flat_id': flatId,
      'uploaded_at': DateTime.now().toIso8601String(),
    });
  }


  Future<List<Document>> getDocuments(String flatId) async {
    final res = await _client.from('documents').select().eq("flat_id", flatId).order('uploaded_at', ascending: false);
    return (res as List).map((e) => Document.fromMap(e)).toList();
  }

  Future<void> deleteDocument(Document doc) async {
    final fileName = Uri.parse(doc.url).pathSegments.last;
    await _client.storage.from('documents').remove([fileName]);
    await _client.from('documents').delete().eq('id', doc.id);
  }
}
