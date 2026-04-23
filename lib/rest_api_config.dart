import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String get host => Platform.isAndroid ? '10.0.2.2' : 'localhost';
/// Ha fizikai deviceon nézzük ezt a host kell
//String get host => '192.168.0.78';

/// FlutterSecureStorage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// ApiService Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiService(baseUrl: 'http://$host:3000', storage: storage);
});


class ApiService {
  final String baseUrl;
  late final Dio _dio;
  final FlutterSecureStorage storage;
  ApiService({required this.baseUrl, required this.storage}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final authRequired = options.extra['authRequired'] ?? true;

          if (authRequired) {
            // Aszinkron módon olvassuk ki a tokent
            final token = await storage.read(key: 'access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options); // tovább a request-tel
        },
        onError: (DioException e, handler) {
          handler.next(e);
        },
      ),
    );
  }

  /// GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authRequired = true,
  }) async {
    final response = await _dio.get(
      path,
      options: Options(extra: {'authRequired': authRequired}),
    );
    return response.data;
  }

  /// POST request
  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool authRequired = true,
  }) async {
    final response = await _dio.post(
      path,
      data: body,
      options: Options(
        extra: {'authRequired': authRequired},
        headers: {'Content-Type': 'application/json'},
      ),
    );
    return response.data;
  }

  /// PUT request
  Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool authRequired = true,
  }) async {
    final response = await _dio.put(
      path,
      data: body,
      options: Options(extra: {'authRequired': authRequired}),
    );
    return response.data;
  }

  /// DELETE request
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = true,
  }) async {
    final response = await _dio.delete(
      path,
      data: body,
      options: Options(extra: {'authRequired': authRequired}),
    );
    return response.data;
  }
}
