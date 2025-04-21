import 'package:flutter/material.dart';
import 'package:pos701/models/login_model.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;
  
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  String? _savedUsername;
  bool _isPasswordVisible = false;
  
  LoginViewModel(this._authService) {
    _loadSavedUsername();
  }
  
  bool get isLoading => _isLoading;
  bool get rememberMe => _rememberMe;
  String? get errorMessage => _errorMessage;
  String? get savedUsername => _savedUsername;
  bool get isPasswordVisible => _isPasswordVisible;
  
  Future<void> _loadSavedUsername() async {
    _savedUsername = await _authService.getSavedUsername();
    notifyListeners();
  }
  
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }
  
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final loginModel = LoginModel(
        userName: username,
        userPassword: password,
        rememberMe: _rememberMe,
      );
      
      final ApiResponseModel<UserModel> response = await _authService.login(loginModel);
      
      _isLoading = false;
      
      if (response.success) {
        return true;
      } else {
        _errorMessage = 'Kullanıcı adı veya şifre hatalı';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Bir hata oluştu: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
} 