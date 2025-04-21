import 'package:flutter/material.dart';
import 'package:pos701/models/statistics_model.dart';
import 'package:pos701/services/statistics_service.dart';
import 'package:pos701/utils/app_logger.dart';

class StatisticsViewModel extends ChangeNotifier {
  final StatisticsService _statisticsService;
  final AppLogger _logger = AppLogger();
  
  StatisticsModel? _statistics;
  bool _isLoading = false;
  String? _errorMessage;
  
  StatisticsViewModel(this._statisticsService) {
    _logger.i('StatisticsViewModel başlatıldı');
  }
  
  StatisticsModel? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<bool> loadStatistics(int compID) async {
    _logger.i('İstatistik verileri yükleniyor');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _statisticsService.getStatistics(compID);
      _isLoading = false;
      
      if (response.success && response.data != null) {
        _statistics = response.data;
        _logger.i('İstatistik verileri başarıyla yüklendi');
        notifyListeners();
        return true;
      } else {
        String hataSebebi = response.errorCode ?? "API'den hata detayı alınamadı";
        if (response.success && response.data == null) {
          hataSebebi = "API yanıtı başarılı fakat veri içermiyor";
        }
        
        _errorMessage = 'İstatistik verileri yüklenemedi: $hataSebebi';
        _logger.w('İstatistik verileri yükleme başarısız: $hataSebebi');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Bir hata oluştu: ${e.toString()}';
      _logger.e('İstatistik verileri yüklenirken hata oluştu', e);
      notifyListeners();
      return false;
    }
  }
  
  Future<void> refreshStatistics(int compID) async {
    await loadStatistics(compID);
  }
} 