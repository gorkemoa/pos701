import 'package:flutter/material.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/utils/app_logger.dart';

class UserViewModel extends ChangeNotifier {
  final AuthService _authService;
  final AppLogger _logger = AppLogger();
  
  UserModel? _userInfo;
  bool _isLoading = false;
  String? _errorMessage;
  
  UserViewModel(this._authService) {
    _logger.i('UserViewModel başlatıldı');
  }
  
  UserModel? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<bool> loadUserInfo() async {
    _logger.i('Kullanıcı bilgileri yükleniyor');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        _isLoading = false;
        _errorMessage = 'Oturum açılmamış';
        _logger.w('Kullanıcı bilgileri yüklenemedi: Oturum açılmamış');
        notifyListeners();
        return false;
      }
      
      final userId = await _getStoredUserId();
      if (userId == null) {
        _isLoading = false;
        _errorMessage = 'Kullanıcı ID bulunamadı';
        _logger.w('Kullanıcı bilgileri yüklenemedi: Kullanıcı ID bulunamadı');
        notifyListeners();
        return false;
      }
      
      _logger.d('Kullanıcı ID: $userId için bilgi alınıyor');
      final response = await _authService.getUserInfo(userId);
      _isLoading = false;
      
      if (response.success && response.data != null) {
        _userInfo = response.data;
        _logger.i('Kullanıcı bilgileri başarıyla yüklendi. Kullanıcı: ${_userInfo?.userFullname}');
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Kullanıcı bilgileri yüklenemedi';
        _logger.w('Kullanıcı bilgileri başarısız: ${response.errorCode}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Bir hata oluştu: ${e.toString()}';
      _logger.e('Kullanıcı bilgileri yüklenirken hata oluştu', e);
      notifyListeners();
      return false;
    }
  }
  
  Future<int?> _getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // Öncelikle int değeri kontrol edelim (yeni depolama formatı)
    final userId = prefs.getInt(AppConstants.userIdKey);
    if (userId != null) {
      _logger.d('Kayıtlı kullanıcı ID (int): $userId');
      return userId;
    }
    
    // Eğer int değer yoksa, eski depolama formatı olan String'i kontrol edelim
    final userIdStr = prefs.getString(AppConstants.userIdKey);
    if (userIdStr != null) {
      try {
        final parsedUserId = int.parse(userIdStr);
        _logger.d('Kayıtlı kullanıcı ID (string->int): $parsedUserId');
        // Eski formatı yeni formata dönüştürelim
        await prefs.setInt(AppConstants.userIdKey, parsedUserId);
        await prefs.remove(AppConstants.userIdKey + '_str');
        return parsedUserId;
      } catch (e) {
        _logger.e('Kullanıcı ID string değeri int\'e dönüştürülemedi', e);
        return null;
      }
    }
    
    _logger.d('Kayıtlı kullanıcı ID bulunamadı');
    return null;
  }
  
  Future<void> clearUserInfo() async {
    _logger.i('Kullanıcı bilgileri temizleniyor');
    _userInfo = null;
    notifyListeners();
  }
} 