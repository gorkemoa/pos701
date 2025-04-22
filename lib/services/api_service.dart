import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/utils/app_logger.dart';

class ApiService {
  final Dio _dio = Dio();
  SharedPreferences? _prefs;
  final AppLogger _logger = AppLogger();

  ApiService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': _getBasicAuthHeader(),
    };
    
    // API'nin 410 durum kodunu ve 401 durum kodunu başarılı bir yanıt olarak değerlendirmek için
    _dio.options.validateStatus = (status) {
      return (status != null && (status >= 200 && status < 300)) || status == 410 || status == 401;
    };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _initPrefs();
          final token = _prefs?.getString(AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers['Authorization'] = _getBasicAuthHeader();
          }
          
          // Request Log
          _logger.apiRequest(
            options.method, 
            options.uri.toString(), 
            body: options.data, 
            headers: options.headers.map((key, value) => MapEntry(key, value.toString())),
          );
          
          // Zaman ölçümü
          options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['startTime'] as int?;
          final endTime = DateTime.now().millisecondsSinceEpoch;
          final executionTime = startTime != null ? endTime - startTime : null;
          
          // 410 durum kodu için özel mesaj
          if (response.statusCode == 410) {
            _logger.i('HTTP 410 alındı: Bu API için normal bir yanıt, başarılı kabul ediliyor');
          }
          
          // 401 durum kodu için özel mesaj
          if (response.statusCode == 401) {
            _logger.w('HTTP 401 alındı: Yetkisiz erişim hatası. Yeniden kimlik doğrulama gerekebilir.');
          }
          
          // Response Log
          _logger.apiResponse(
            response.requestOptions.method,
            response.requestOptions.uri.toString(),
            response.statusCode ?? 0,
            response.data,
            executionTime: executionTime,
          );
          
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final startTime = e.requestOptions.extra['startTime'] as int?;
          final endTime = DateTime.now().millisecondsSinceEpoch;
          final executionTime = startTime != null ? endTime - startTime : null;
          
          // Error Log
          _logger.apiError(
            e.requestOptions.method,
            e.requestOptions.uri.toString(),
            e.message,
            response: e.response?.data,
            executionTime: executionTime,
          );
          
          return handler.next(e);
        },
      ),
    );
    
    _logger.i('ApiService başlatıldı. Base URL: ${AppConstants.baseUrl}');
    // Başlatma işlemi asenkron, ilk çağrıda _initPrefs() kullanılacak
  }
  
  Future<void> _initPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  String _getBasicAuthHeader() {
    final credentials = '${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}';
    final encodedCredentials = base64Encode(utf8.encode(credentials));
    return 'Basic $encodedCredentials';
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
    await _initPrefs();
    await _prefs?.setString(AppConstants.tokenKey, token);
    _logger.i('Token kaydedildi: $token');
  }

  Future<void> saveUserId(int userId) async {
    await _initPrefs();
    await _prefs?.setInt(AppConstants.userIdKey, userId);
    _logger.i('KullanıcıID kaydedildi: $userId');
  }
  
  Future<void> saveCompanyId(int companyId) async {
    await _initPrefs();
    await _prefs?.setInt(AppConstants.companyIdKey, companyId);
    _logger.i('ŞirketID kaydedildi: $companyId');
  }

  Future<String?> getToken() async {
    await _initPrefs();
    return _prefs?.getString(AppConstants.tokenKey);
  }

  Future<int?> getUserId() async {
    await _initPrefs();
    return _prefs?.getInt(AppConstants.userIdKey);
  }
  
  Future<int?> getCompanyId() async {
    await _initPrefs();
    return _prefs?.getInt(AppConstants.companyIdKey);
  }

  Future<void> clearToken() async {
    await _initPrefs();
    await _prefs?.remove(AppConstants.tokenKey);
    await _prefs?.remove(AppConstants.userIdKey);
    await _prefs?.remove(AppConstants.companyIdKey);
    _logger.i('Token ve kullanıcı bilgileri temizlendi');
  }
} 