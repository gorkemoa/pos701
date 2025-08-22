import 'package:flutter/material.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:flutter/scheduler.dart';

class CompanyViewModel extends ChangeNotifier {
  final AppLogger _logger = AppLogger();
  
  bool _isOnline = false;
  bool _disposed = false;
  
  CompanyViewModel() {
    _logger.i('CompanyViewModel başlatıldı');
  }
  
  bool get isOnline => _isOnline;
  
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
      _logger.w('CompanyViewModel dispose edilmiş durumda, bildirim gönderilemiyor');
    }
  }
  
  /// Company bilgisini JSON'dan okur ve online durumunu günceller
  void setCompany(Map<String, dynamic> json) {
    try {
      _logger.d('Company bilgisi güncelleniyor: $json');
      
      // compIsOnline değerini oku
      final compIsOnline = json['compIsOnline'];
      
      if (compIsOnline is bool) {
        _isOnline = compIsOnline;
      } else if (compIsOnline is int) {
        _isOnline = compIsOnline == 1;
      } else if (compIsOnline is String) {
        _isOnline = compIsOnline.toLowerCase() == 'true' || compIsOnline == '1';
      } else {
        _isOnline = false;
        _logger.w('compIsOnline değeri beklenmedik formatta: $compIsOnline');
      }
      
      _logger.i('Company online durumu güncellendi: $_isOnline');
      _safeNotifyListeners();
    } catch (e) {
      _logger.e('Company bilgisi güncellenirken hata oluştu', e);
      _isOnline = false;
      _safeNotifyListeners();
    }
  }
  
  /// Hata/timeout durumunda offline olarak işaretle
  void setOffline() {
    _logger.w('Company offline olarak işaretlendi');
    _isOnline = false;
    _safeNotifyListeners();
  }
}
