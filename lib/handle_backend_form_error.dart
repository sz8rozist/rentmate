import 'package:dio/dio.dart';

import 'form_error_model.dart';

FormErrors parseBusinessError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;

    if (data is Map<String, dynamic> &&
        data['type'] == 'BUSINESS_ERROR' &&
        data['errors'] is Map) {

      final rawErrors = data['errors'] as Map;

      final Map<String, String> parsed = {};

      rawErrors.forEach((key, value) {
        if (key is String) {
          parsed[key] = value.toString();
        }
      });

      return FormErrors(parsed);
    }
  }

  return FormErrors.empty();
}
