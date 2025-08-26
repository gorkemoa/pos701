import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:pos701/main.dart';
import 'package:pos701/views/login_view.dart';
import 'package:pos701/viewmodels/company_viewmodel.dart';

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
    
    // API'nin 410, 401 ve 403 durum kodlarını başarılı yanıt olarak değerlendirmek için
    _dio.options.validateStatus = (status) {
      return (status != null && (status >= 200 && status < 300)) || status == 410 || status == 401 || status == 403;
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
          
          // CompanyViewModel'i online yap - API yanıtı başarılı
          CompanyViewModel.instance.setOnline();
          
          // 410 durum kodu için özel mesaj
          if (response.statusCode == 410) {
            _logger.i('HTTP 410 alındı: Bu API için normal bir yanıt, başarılı kabul ediliyor');
          }
          
          // 401 durum kodu için özel mesaj
          if (response.statusCode == 401) {
            _logger.w('HTTP 401 alındı: Yetkisiz erişim hatası. Yeniden kimlik doğrulama gerekebilir.');
          }
          
          // 403 durum kodu için özel işlem - token hatası
          if (response.statusCode == 403) {
            _logger.w('HTTP 403 alındı: Geçersiz token hatası. Kullanıcı login sayfasına yönlendiriliyor.');
            _handle403Error();
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
          
          // CompanyViewModel'i offline yap - API hatası
          CompanyViewModel.instance.setOffline();
          
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

  Future<void> saveCompanyName(String companyName) async {
    await _initPrefs();
    await _prefs?.setString(AppConstants.companyNameKey, companyName);
    _logger.i('Şirket adı kaydedildi: $companyName');
  }

  Future<String?> getToken() async {
    await _initPrefs();
    final token = _prefs?.getString(AppConstants.tokenKey);
    
    if (token == null || token.isEmpty) {
      _logger.w('Token bulunamadı veya boş');
      return null;
    }
    
    _logger.d('Token alındı: ${token.substring(0, 10)}...');
    return token;
  }

  Future<int?> getUserId() async {
    await _initPrefs();
    return _prefs?.getInt(AppConstants.userIdKey);
  }
  
  Future<int?> getCompanyId() async {
    await _initPrefs();
    return _prefs?.getInt(AppConstants.companyIdKey);
  }

  Future<String?> getCompanyName() async {
    await _initPrefs();
    return _prefs?.getString(AppConstants.companyNameKey);
  }

  Future<void> clearToken() async {
    await _initPrefs();
    await _prefs?.remove(AppConstants.tokenKey);
    await _prefs?.remove(AppConstants.userIdKey);
    await _prefs?.remove(AppConstants.companyIdKey);
    _logger.i('Token ve kullanıcı bilgileri temizlendi');
  }
  
  /// 403 hatası durumunda token temizleme ve login sayfasına yönlendirme
  void _handle403Error() async {
    try {
      _logger.w('403 hatası yakalandı. Token temizleniyor ve login sayfasına yönlendiriliyor.');
      
      // Token'ı temizle
      await clearToken();
      
      // Login sayfasına yönlendir
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        // Mevcut tüm route'ları temizle ve login sayfasına yönlendir
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
        
        // Kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _logger.e('403 hatası işlenirken hata oluştu: $e');
    }
  }
} 