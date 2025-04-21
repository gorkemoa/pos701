import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos701/constants/app_constants.dart';

class ApiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response;
    } on DioException catch (e) {
      return Future.error(e);
    }
  }

  Future<Response> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: jsonEncode(data));
      return response;
    } on DioException catch (e) {
      return Future.error(e);
    }
  }

  Future<Response> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(path, data: jsonEncode(data));
      return response;
    } on DioException catch (e) {
      return Future.error(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response;
    } on DioException catch (e) {
      return Future.error(e);
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<void> saveUserId(int userId) async {
    await _storage.write(key: AppConstants.userIdKey, value: userId.toString());
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<int?> getUserId() async {
    final userIdStr = await _storage.read(key: AppConstants.userIdKey);
    return userIdStr != null ? int.parse(userIdStr) : null;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userIdKey);
  }
} 