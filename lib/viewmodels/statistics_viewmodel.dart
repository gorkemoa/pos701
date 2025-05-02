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
  bool _disposed = false;
  
  StatisticsViewModel(this._statisticsService) {
    _logger.i('StatisticsViewModel başlatıldı');
    _logger.d('StatisticsViewModel bağımlılıkları: StatisticsService');
  }
  
  StatisticsModel? get statistics => _statistics;
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
      notifyListeners();
    } else {
      _logger.w('StatisticsViewModel dispose edilmiş durumda, bildirim gönderilemiyor');
    }
  }
  
  Future<bool> loadStatistics(int compID) async {
    final startTime = DateTime.now();
    _logger.i('İstatistik verileri yükleniyor. CompID: $compID');
    _logger.d('ViewModel durumu: isLoading=$_isLoading, errorMessage=$_errorMessage, statistics=${_statistics != null}');
    
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();
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
        
        // Masa doluluk verisi için özel log
        _logger.i('Masa doluluk verileri: Toplam=${response.data!.totalTables}, Dolu=${response.data!.orderTables}, Boş=${response.data!.totalTables - response.data!.orderTables}');
        
        // Masa doluluk verilerini kontrol et
        if (response.data!.totalTables <= 0) {
          _logger.w('Masa sayısı geçersiz: totalTables=${response.data!.totalTables}');
        }
        
        if (response.data!.orderTables < 0 || response.data!.orderTables > response.data!.totalTables) {
          _logger.w('Dolu masa sayısı geçersiz: orderTables=${response.data!.orderTables}, totalTables=${response.data!.totalTables}');
        }
      }
      
      _isLoading = false;
      
      if (response.success && response.data != null) {
        _statistics = response.data;
        _logger.i('İstatistik verileri başarıyla yüklendi. Yükleme süresi: ${duration.inMilliseconds}ms');
        _logger.d('Yüklenen veri: totalGuest=${_statistics!.totalGuest}, totalTables=${_statistics!.totalTables}');
        _safeNotifyListeners();
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
        _safeNotifyListeners();
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
      
      _safeNotifyListeners();
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