import 'package:dio/dio.dart';

import '../rest_api_config.dart';

class FileUploadService {
  final ApiService apiService;

  FileUploadService(this.apiService);

  Future<bool> uploadFile(String endpoint, String filePath, {required String fileFieldName}) async {
    final file = await MultipartFile.fromFile(filePath, filename: filePath.split('/').last);
    final formData = FormData.fromMap({fileFieldName: file});
    final data = await apiService.post(endpoint, formData as Map<String, dynamic>);
    return data['success'] ?? true;
  }
}