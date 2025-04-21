import 'dart:convert';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/models/login_model.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/services/api_service.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _apiService;
  final AppLogger _logger = AppLogger();

  AuthService(this._apiService) {
    _logger.i('AuthService başlatıldı');
  }

  Future<ApiResponseModel<UserModel>> login(LoginModel loginModel) async {
    try {
      _logger.d('Login işlemi başlatılıyor. Kullanıcı adı: ${loginModel.userName}');
      
      final response = await _apiService.post(AppConstants.loginEndpoint, loginModel.toJson());
      
      _logger.d('Login yanıtı alındı. Status: ${response.statusCode}');
      
      // 410 durum kodu için özel işlem
      if (response.statusCode == 410) {
        _logger.i('HTTP 410 durum kodu alındı. Bu API için normal bir yanıt.');
      }
      
      // API yanıtı zaten Map<String, dynamic> formatında olabilir, jsonDecode kullanmak hataya sebep olabilir
      final responseData = response.data is String ? jsonDecode(response.data) : response.data;
      _logger.d('Yanıt verisi: $responseData');
      
      // Yanıt içindeki yapıyı kontrol et
      if (responseData is! Map<String, dynamic>) {
        _logger.e('API yanıtı beklenen formatta değil: $responseData');
        return ApiResponseModel<UserModel>(
          error: true,
          success: false,
          errorCode: 'API yanıtı geçersiz format',
        );
      }
      
      try {
        final apiResponse = ApiResponseModel<UserModel>.fromJson(
          responseData,
          (data) => UserModel.fromLoginJson(data),
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          await _apiService.saveToken(apiResponse.data!.token);
          await _apiService.saveUserId(apiResponse.data!.userID);
          
          _logger.i('Login işlemi başarılı. UserID: ${apiResponse.data!.userID}');
          
          if (loginModel.rememberMe) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(AppConstants.userNameKey, loginModel.userName);
            _logger.d('Kullanıcı adı "Beni Hatırla" seçeneği ile kaydedildi');
          }
        } else {
          _logger.w('Login işlemi başarısız. Yanıt: ${apiResponse.errorCode ?? "Bilinmeyen hata"}');
        }
        
        return apiResponse;
      } catch (parseError) {
        _logger.e('API yanıtı işlenirken hata: $parseError', parseError);
        return ApiResponseModel<UserModel>(
          error: true,
          success: false,
          errorCode: 'API yanıtı işleme hatası: $parseError',
        );
      }
    } catch (e) {
      _logger.e('Login işleminde hata oluştu', e);
      return ApiResponseModel<UserModel>(
        error: true,
        success: false,
        errorCode: e.toString(),
      );
    }
  }

  Future<ApiResponseModel<UserModel>> getUserInfo(int userId) async {
    try {
      _logger.d('Kullanıcı bilgileri alınıyor. UserID: $userId');
      
      final token = await _apiService.getToken();
      if (token == null) {
        _logger.w('Token bulunamadı');
        return ApiResponseModel<UserModel>(
          error: true,
          success: false,
          errorCode: 'Token bulunamadı',
        );
      }
      
      final data = {
        "userToken": token,
        "platform": "ios", // Gerçek platform bilgisiyle değiştirilmeli
        "version": AppConstants.appVersion
      };
      
      _logger.d('Kullanıcı bilgileri isteği gönderiliyor: $data');
      
      // Endpoint'e userId ekleyerek tam URL oluştur
      final endpoint = '${AppConstants.userInfoEndpoint}$userId';
      final response = await _apiService.put(endpoint, data);
      
      _logger.d('Kullanıcı bilgileri yanıtı alındı. Status: ${response.statusCode}');
      
      // 410 durum kodu için özel işlem
      if (response.statusCode == 410) {
        _logger.i('HTTP 410 durum kodu alındı. Bu API için normal bir yanıt.');
      }
      
      // API yanıtı zaten Map<String, dynamic> formatında olabilir
      final responseData = response.data is String ? jsonDecode(response.data) : response.data;
      _logger.d('Yanıt verisi: $responseData');
      
      // Yanıt içindeki yapıyı kontrol et
      if (responseData is! Map<String, dynamic>) {
        _logger.e('API yanıtı beklenen formatta değil: $responseData');
        return ApiResponseModel<UserModel>(
          error: true,
          success: false,
          errorCode: 'API yanıtı geçersiz format',
        );
      }
      
      try {
        final apiResponse = ApiResponseModel<UserModel>.fromJson(
          responseData,
          (data) => UserModel.fromJson(data),
        );
        
        if (apiResponse.success && apiResponse.data != null) {
          _logger.i('Kullanıcı bilgileri başarıyla alındı');
        } else {
          _logger.w('Kullanıcı bilgileri alınamadı. Yanıt: ${apiResponse.errorCode ?? "Bilinmeyen hata"}');
        }
        
        return apiResponse;
      } catch (parseError) {
        _logger.e('API yanıtı işlenirken hata: $parseError', parseError);
        return ApiResponseModel<UserModel>(
          error: true,
          success: false,
          errorCode: 'API yanıtı işleme hatası: $parseError',
        );
      }
    } catch (e) {
      _logger.e('Kullanıcı bilgileri alınırken hata oluştu', e);
      return ApiResponseModel<UserModel>(
        error: true,
        success: false,
        errorCode: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    _logger.d('Çıkış yapılıyor');
    await _apiService.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiService.getToken();
    final isLoggedIn = token != null;
    _logger.d('Oturum kontrol ediliyor. Sonuç: ${isLoggedIn ? 'Oturum açık' : 'Oturum kapalı'}');
    return isLoggedIn;
  }

  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(AppConstants.userNameKey);
    _logger.d('Kayıtlı kullanıcı adı: ${username ?? 'Yok'}');
    return username;
  }

  Future<void> clearSavedUsername() async {
    _logger.d('Kayıtlı kullanıcı adı siliniyor');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userNameKey);
  }
} 