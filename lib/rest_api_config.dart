import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String get host => Platform.isAndroid ? '10.0.2.2' : 'localhost';

/// Token tárolása
final tokenProvider = StateProvider<String?>((ref) => null);

/// ApiService Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final token = ref.watch(tokenProvider);
  return ApiService(token: token, baseUrl: 'http://$host:3000');
});

class ApiService {
  final String? token;
  final String baseUrl;
  late final Dio _dio;

  ApiService({this.token, required this.baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Interceptor: Token automatikusan hozzáadása, kivételekkel
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final authRequired = options.extra['authRequired'] ?? true;
        if (authRequired && token != null && token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioError e, handler) {
        return handler.next(e); // tovább dobhatjuk az error-t
      },
    ));
  }

  /// GET request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, bool authRequired = true}) async {
    final response = await _dio.get(path, options: Options(extra: {'authRequired': authRequired}));
    return response.data;
  }

  /// POST request
  Future<dynamic> post(String path, Map<String, dynamic> body, {bool authRequired = true}) async {
    final response = await _dio.post(path,
        data: body, options: Options(extra: {'authRequired': authRequired}));
    return response.data;
  }

  /// PUT request
  Future<dynamic> put(String path, Map<String, dynamic> body, {bool authRequired = true}) async {
    final response = await _dio.put(path,
        data: body, options: Options(extra: {'authRequired': authRequired}));
    return response.data;
  }

  /// DELETE request
  Future<dynamic> delete(String path, {Map<String, dynamic>? body, bool authRequired = true}) async {
    final response = await _dio.delete(path,
        data: body, options: Options(extra: {'authRequired': authRequired}));
    return response.data;
  }
}
