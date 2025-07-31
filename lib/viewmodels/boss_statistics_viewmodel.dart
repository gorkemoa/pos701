import 'package:flutter/material.dart';
import 'package:pos701/models/boss_statistics_model.dart';
import 'package:pos701/services/boss_statistics_service.dart';
import 'package:pos701/utils/app_logger.dart';

class BossStatisticsViewModel extends ChangeNotifier {
  final BossStatisticsService _service = BossStatisticsService();
  final _logger = AppLogger();
  
  List<BossStatisticsModel> _statistics = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _startDate = '';
  String _endDate = '';

  List<BossStatisticsModel> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get startDate => _startDate;
  String get endDate => _endDate;

  void setDateRange(String startDate, String endDate) {
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  Future<void> fetchBossStatistics({
    required String userToken,
    required int compID,
    required String startDate,
    required String endDate,
  }) async {
    _logger.i('🔄 Boss Statistics ViewModel: Veri çekme başlatılıyor...');
    _logger.d('📋 Parametreler: userToken: $userToken, compID: $compID, startDate: $startDate, endDate: $endDate');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getBossStatistics(
        userToken: userToken,
        compID: compID,
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success && !response.error) {
        _statistics = response.data;
        _startDate = startDate;
        _endDate = endDate;
        _logger.i('✅ Boss Statistics ViewModel: Veri başarıyla alındı. ${_statistics.length} adet istatistik');
        _logger.d('📊 İstatistikler: ${_statistics.map((s) => '${s.title}: ${s.amount}').join(', ')}');
      } else {
        _logger.e('❌ Boss Statistics ViewModel: API başarısız response');
        _errorMessage = 'Veri alınamadı';
      }
    } catch (e) {
      _logger.e('❌ Boss Statistics ViewModel: Hata oluştu: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _logger.d('🏁 Boss Statistics ViewModel: Veri çekme tamamlandı. Loading: $_isLoading, Error: $_errorMessage');
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _statistics = [];
    _isLoading = false;
    _errorMessage = null;
    _startDate = '';
    _endDate = '';
    notifyListeners();
  }
} 