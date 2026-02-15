import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

/// Singleton API client with JWT interceptor support.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add JWT interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.jwtTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired — clear stored token
            await _storage.delete(key: AppConstants.jwtTokenKey);
          }
          return handler.next(error);
        },
      ),
    );

    // Add logging in debug mode
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // ─── Auth Endpoints ────────────────────────────────────────

  Future<Response> register(String email, String password) async {
    return await dio.post('/auth/register', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> login(String email, String password) async {
    return await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> googleSignIn(String idToken) async {
    return await dio.post('/auth/google', data: {
      'id_token': idToken,
    });
  }

  // ─── Pantry Items ──────────────────────────────────────────

  Future<Response> getItems() async {
    return await dio.get('/items');
  }

  Future<Response> createItem(Map<String, dynamic> item) async {
    return await dio.post('/items', data: item);
  }

  Future<Response> updateItem(int id, Map<String, dynamic> item) async {
    return await dio.put('/items/$id', data: item);
  }

  Future<Response> deleteItem(int id) async {
    return await dio.delete('/items/$id');
  }

  // ─── Product Lookup ─────────────────────────────────────────

  Future<Response> getProductByBarcode(String barcode) async {
    return await dio.get('/products/$barcode');
  }

  // ─── Sync ───────────────────────────────────────────────────

  Future<Response> syncItems(List<Map<String, dynamic>> items) async {
    return await dio.post('/sync', data: {
      'items': items,
    });
  }
}
