import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentmate/rest_api_config.dart';
import 'package:rentmate/services/file_upload_service.dart';

final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FileUploadService(apiService);
});