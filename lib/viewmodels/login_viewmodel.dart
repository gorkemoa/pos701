import 'package:flutter/material.dart';
import 'package:pos701/models/login_model.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/utils/app_logger.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;
  final AppLogger _logger = AppLogger();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  String? _savedUsername;
  bool _isPasswordVisible = false;
  
  LoginViewModel(this._authService) {
    _logger.i('LoginViewModel başlatıldı');
    _loadSavedUsername();
  }
  
  bool get isLoading => _isLoading;
  bool get rememberMe => _rememberMe;
  String? get errorMessage => _errorMessage;
  String? get savedUsername => _savedUsername;
  bool get isPasswordVisible => _isPasswordVisible;
  
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
      
      if (response.success) {
        _logger.i('Giriş başarılı');
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
} 