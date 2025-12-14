import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/GraphQLConfig.dart';

// Globális file upload service provider
final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  return FileUploadService(ref);
});

class FileUploadService {
  final String _graphqlEndpoint = 'http://$host:3000/graphql';
  final Ref _ref;

  FileUploadService(this._ref);

  /// Single file upload
  Future<bool> uploadSingleFile({
    required String mutation,
    required Map<String, dynamic> variables,
    required String filePath,
    String fileVariableName = 'file',
  }) async {
    return await uploadMultipleFiles(
      mutation: mutation,
      variables: variables,
      filePaths: [filePath],
      fileVariableNames: [fileVariableName],
    );
  }

  Map<String, String> get _headers {
    final token = _ref.read(tokenProvider);
    return {'Authorization': 'Bearer ${token ?? ''}'};
  }

  /// Multiple file upload
  Future<bool> uploadMultipleFiles({
    required String mutation,
    required Map<String, dynamic> variables,
    required List<String> filePaths,
    List<String>?
    fileVariableNames, // opcionális, ha több fájl, különböző változónevek
  }) async {
    if (filePaths.isEmpty) return false;

    // Alapértelmezett file variable nevek
    final variableNames =
        fileVariableNames ?? List.generate(filePaths.length, (i) => 'file$i');

    // Ellenőrzés: minden fájl létezik?
    for (final path in filePaths) {
      if (!await File(path).exists()) {
        print("Fájl nem található: $path");
        return false;
      }
    }

    // Multipart request létrehozása
    final request = http.MultipartRequest('POST', Uri.parse(_graphqlEndpoint));
    request.headers.addAll(_headers);

    // GraphQL operations mező (file-ok null-ként)
    final fileVariables = <String, dynamic>{};
    for (final name in variableNames) {
      fileVariables[name] = null;
    }
    final operations = {
      "query": mutation,
      "variables": {...variables, ...fileVariables},
    };
    request.fields['operations'] = jsonEncode(operations);

    // Map mező (file indexek a GraphQL változókhoz)
    final map = <String, List<String>>{};
    for (var i = 0; i < filePaths.length; i++) {
      map['$i'] = ['variables.${variableNames[i]}'];
    }
    request.fields['map'] = jsonEncode(map);

    // Fájlok hozzáadása
    for (var i = 0; i < filePaths.length; i++) {
      final filePath = filePaths[i];
      final fileName = filePath.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath('$i', filePath, filename: fileName),
      );
    }

    // Küldés
    final response = await request.send();
    final respBody = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      print("File upload hiba: ${response.statusCode}");
      print(respBody);
      return false;
    }

    // GraphQL visszaadás dekódolása
    final decoded = jsonDecode(respBody);
    if (decoded['errors'] != null) {
      print("GraphQL hiba: ${decoded['errors']}");
      return false;
    }

    return true;
  }

  Future<bool> deleteFile({
    required String mutation,
    required Map<String, dynamic> variables,
  }) async {
    final response = await http.post(
      Uri.parse(_graphqlEndpoint),
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': mutation,
        'variables': variables,
      }),
    );

    if (response.statusCode != 200) {
      print("Delete file hiba: ${response.statusCode}");
      print(response.body);
      return false;
    }

    final decoded = jsonDecode(response.body);
    if (decoded['errors'] != null) {
      print("GraphQL hiba: ${decoded['errors']}");
      return false;
    }

    return true;
  }
}
