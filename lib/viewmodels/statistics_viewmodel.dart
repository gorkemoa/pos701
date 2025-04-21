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
    _logger.d('StatisticsViewModel bağımlılıkları: StatisticsService');
  }
  
  StatisticsModel? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<bool> loadStatistics(int compID) async {
    final startTime = DateTime.now();
    _logger.i('İstatistik verileri yükleniyor. CompID: $compID');
    _logger.d('ViewModel durumu: isLoading=$_isLoading, errorMessage=$_errorMessage, statistics=${_statistics != null}');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _logger.d('Yükleme durumu güncellendi ve bildirim gönderildi');
    
    try {
      _logger.d('StatisticsService.getStatistics çağrısı yapılıyor. Parametre: compID=$compID');
      final response = await _statisticsService.getStatistics(compID);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      _logger.d('API yanıtı alındı. Süre: ${duration.inMilliseconds}ms');
      _logger.d('API yanıt detayları: success=${response.success}, error=${response.error}, errorCode=${response.errorCode}');
      _logger.d('API veri mevcut mu: ${response.data != null}');
      
      if (response.data != null) {
        _logger.d('API veri içeriği: totalGuest=${response.data!.totalGuest}, totalTables=${response.data!.totalTables}, orderTables=${response.data!.orderTables}');
        _logger.d('API veri metin içeriği: totalAmountText=${response.data!.totalAmountText}, totalAmount=${response.data!.totalAmount}');
        _logger.d('Satış verisi sayısı: ${response.data!.nowDaySales.length}, Ödeme verisi sayısı: ${response.data!.nowDayPayments.length}');
      }
      
      _isLoading = false;
      
      if (response.success && response.data != null) {
        _statistics = response.data;
        _logger.i('İstatistik verileri başarıyla yüklendi. Yükleme süresi: ${duration.inMilliseconds}ms');
        _logger.d('Yüklenen veri: totalGuest=${_statistics!.totalGuest}, totalTables=${_statistics!.totalTables}');
        notifyListeners();
        _logger.d('Başarılı yükleme sonrası bildirim gönderildi');
        return true;
      } else {
        String hataSebebi = response.errorCode ?? "API'den hata detayı alınamadı";
        if (response.success && response.data == null) {
          hataSebebi = "API yanıtı başarılı fakat veri içermiyor";
        }
        
        _errorMessage = 'İstatistik verileri yüklenemedi: $hataSebebi';
        _logger.w('İstatistik verileri yükleme başarısız: $hataSebebi');
        _logger.d('Hata detayları: success=${response.success}, error=${response.error}, errorCode=${response.errorCode}');
        _logger.d('Yükleme süresi: ${duration.inMilliseconds}ms');
        notifyListeners();
        _logger.d('Hata durumu sonrası bildirim gönderildi');
        return false;
      }
    } catch (e, stackTrace) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      _isLoading = false;
      _errorMessage = 'Bir hata oluştu: ${e.toString()}';
      _logger.e('İstatistik verileri yüklenirken hata oluştu', e);
      _logger.d('Hata stack trace: $stackTrace');
      _logger.d('Hata oluşma süresi: ${duration.inMilliseconds}ms');
      _logger.d('Hata sonrası ViewModel durumu: isLoading=$_isLoading, errorMessage=$_errorMessage');
      
      notifyListeners();
      _logger.d('Hata durumu sonrası bildirim gönderildi');
      return false;
    }
  }
  
  Future<void> refreshStatistics(int compID) async {
    _logger.i('İstatistik verilerini yenileme işlemi başlatıldı. CompID: $compID');
    final sonuc = await loadStatistics(compID);
    _logger.d('İstatistik yenileme işlemi tamamlandı. Sonuç: $sonuc');
  }
} 