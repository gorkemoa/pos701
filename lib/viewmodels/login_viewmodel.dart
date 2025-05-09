import 'package:flutter/material.dart';
import 'package:pos701/models/login_model.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/services/api_service.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos701/services/firebase_messaging_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;
  final AppLogger _logger = AppLogger();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  String? _savedUsername;
  bool _isPasswordVisible = false;
  int? _lastLoggedInUserId;
  
  LoginViewModel(this._authService, this._apiService) {
    _logger.i('LoginViewModel başlatıldı');
    _loadSavedUsername();
  }
  
  bool get isLoading => _isLoading;
  bool get rememberMe => _rememberMe;
  String? get errorMessage => _errorMessage;
  String? get savedUsername => _savedUsername;
  bool get isPasswordVisible => _isPasswordVisible;
  int? get lastLoggedInUserId => _lastLoggedInUserId;
  
  Future<void> _loadSavedUsername() async {
    _logger.d('Kayıtlı kullanıcı adı yükleniyor');
    _savedUsername = await _authService.getSavedUsername();
    if (_savedUsername != null) {
      _logger.d('Kayıtlı kullanıcı adı bulundu: $_savedUsername');
      _rememberMe = true;
    }
    notifyListeners();
  }
  
  void setRememberMe(bool value) {
    _logger.d('Beni hatırla durumu değiştirildi: $value');
    _rememberMe = value;
    notifyListeners();
  }
  
  void togglePasswordVisibility() {
    _logger.d('Şifre görünürlüğü değiştirildi: ${!_isPasswordVisible}');
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }
  
  void clearError() {
    _logger.d('Hata mesajı temizlendi');
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<bool> login(String username, String password) async {
    _logger.i('Giriş işlemi başlatılıyor. Kullanıcı adı: $username');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final loginModel = LoginModel(
        userName: username,
        userPassword: password,
        rememberMe: _rememberMe,
      );
      
      _logger.d('Login isteği gönderiliyor');
      final ApiResponseModel<UserModel> response = await _authService.login(loginModel);
      
      _isLoading = false;
      
      if (response.success && response.data != null) {
        _logger.i('Giriş başarılı');
        
        _lastLoggedInUserId = response.data!.userID;
        
        if (response.data!.compID != null) {
          await _apiService.saveCompanyId(response.data!.compID!);
          _logger.i('Şirket ID kaydedildi: ${response.data!.compID}');
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(AppConstants.companyIdKey, response.data!.compID!);
        } else {
          _logger.w('Kullanıcı bilgilerinde Şirket ID (compID) bulunamadı');
        }
        
        return true;
      } else {
        _errorMessage = 'Kullanıcı adı veya şifre hatalı';
        _logger.w('Giriş başarısız: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Bir hata oluştu: ${e.toString()}';
      _logger.e('Giriş işleminde hata oluştu', e);
      notifyListeners();
      return false;
    }
  }
  
  Future<void> subscribeToUserTopic(FirebaseMessagingService messagingService) async {
    if (_lastLoggedInUserId == null || _lastLoggedInUserId! <= 0) {
      _logger.w('Geçerli bir kullanıcı ID\'si bulunamadığı için FCM topic aboneliği yapılamadı');
      return;
    }
    
    try {
      final String userIdStr = _lastLoggedInUserId.toString();
      _logger.d('Kullanıcı ID\'si $userIdStr için FCM topic aboneliği yapılıyor');
      
      await messagingService.subscribeToUserTopic(userIdStr);
      
      _logger.i('Kullanıcı ID\'si $userIdStr için FCM topic aboneliği başarılı');
    } catch (e) {
      _logger.e('FCM topic aboneliği sırasında hata: $e');
    }
  }
  
  /// Kayıtlı kullanıcı adını temizler
  Future<void> clearSavedUsername() async {
    _logger.d('Kayıtlı kullanıcı adı temizleniyor');
    await _authService.clearSavedUsername();
    _savedUsername = null;
    notifyListeners();
  }
} 