import 'package:flutter/material.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:flutter/scheduler.dart';
import 'package:pos701/services/firebase_messaging_service.dart';

class UserViewModel extends ChangeNotifier {
  final AuthService _authService;
  final AppLogger _logger = AppLogger();
  
  UserModel? _userInfo;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  
  UserViewModel(this._authService) {
    _logger.i('UserViewModel başlatıldı');
  }
  
  UserModel? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
  
  // Güvenli bildirim gönderme metodu
  void _safeNotifyListeners() {
    if (!_disposed) {
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        notifyListeners();
      } else {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) {
            notifyListeners();
          }
        });
      }
    } else {
      _logger.w('UserViewModel dispose edilmiş durumda, bildirim gönderilemiyor');
    }
  }
  
  /// Kullanıcının kendi ID'sine karşılık gelen FCM topic'ine abone ol
  Future<void> subscribeToUserTopic(FirebaseMessagingService messagingService) async {
    if (_userInfo == null || _userInfo!.userID <= 0) {
      _logger.w('Kullanıcı ID bulunamadı, FCM topic aboneliği yapılamıyor');
      return;
    }
    
    try {
      final String userIdStr = _userInfo!.userID.toString();
      _logger.d('Kullanıcı ID\'si $userIdStr için FCM topic aboneliği yapılıyor');
      await messagingService.subscribeToUserTopic(userIdStr);
      _logger.i('Kullanıcı ID\'si $userIdStr için FCM topic aboneliği başarılı');
    } catch (e) {
      _logger.e('FCM topic aboneliği sırasında hata: $e');
    }
  }
  
  /// Kullanıcının kendi ID'sine karşılık gelen FCM topic aboneliğinden çık
  Future<void> unsubscribeFromUserTopic(FirebaseMessagingService messagingService) async {
    if (_userInfo == null || _userInfo!.userID <= 0) {
      _logger.w('Kullanıcı ID bulunamadı, FCM topic aboneliğinden çıkılamıyor');
      return;
    }
    
    try {
      final String userIdStr = _userInfo!.userID.toString();
      _logger.d('Kullanıcı ID\'si $userIdStr için FCM topic aboneliğinden çıkılıyor');
      await messagingService.unsubscribeFromUserTopic(userIdStr);
      _logger.i('Kullanıcı ID\'si $userIdStr için FCM topic aboneliğinden çıkma başarılı');
    } catch (e) {
      _logger.e('FCM topic aboneliğinden çıkma sırasında hata: $e');
    }
  }
  
  Future<bool> loadUserInfo() async {
    _logger.i('Kullanıcı bilgileri yükleniyor');
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        _isLoading = false;
        _errorMessage = 'Oturum açılmamış';
        _logger.w('Kullanıcı bilgileri yüklenemedi: Oturum açılmamış');
        _safeNotifyListeners();
        return false;
      }
      
      final userId = await _getStoredUserId();
      if (userId == null) {
        _isLoading = false;
        _errorMessage = 'Kullanıcı ID bulunamadı';
        _logger.w('Kullanıcı bilgileri yüklenemedi: Kullanıcı ID bulunamadı');
        _safeNotifyListeners();
        return false;
      }
      
      _logger.d('Kullanıcı ID: $userId için bilgi alınıyor');
      final response = await _authService.getUserInfo(userId);
      _isLoading = false;
      
      if (response.success && response.data != null) {
        _userInfo = response.data;
        _logger.i('Kullanıcı bilgileri başarıyla yüklendi. Kullanıcı: ${_userInfo?.userFullname}');
        _safeNotifyListeners();
        return true;
      } else {
        _errorMessage = 'Kullanıcı bilgileri yüklenemedi';
        _logger.w('Kullanıcı bilgileri başarısız: ${response.errorCode}');
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Bir hata oluştu: ${e.toString()}';
      _logger.e('Kullanıcı bilgileri yüklenirken hata oluştu', e);
      _safeNotifyListeners();
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
    _safeNotifyListeners();
  }
} 