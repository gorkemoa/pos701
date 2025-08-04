import 'package:flutter/material.dart';
import 'package:pos701/models/boss_statistics_model.dart';
import 'package:pos701/services/boss_statistics_service.dart';
import 'package:pos701/utils/app_logger.dart';

class BossStatisticsViewModel extends ChangeNotifier {
  final BossStatisticsService _service = BossStatisticsService();
  final _logger = AppLogger();
  
  List<BossStatisticsModel> _statistics = [];
  List<BossStatisticsGraphicModel> _graphics = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _startDate = '';
  String _endDate = '';

  // Detay verileri için yeni state'ler
  List<BossStatisticsDetailModel> _detailStatistics = [];
  bool _isDetailLoading = false;
  String? _detailErrorMessage;
  BossStatisticsDetailData? _detailData;

  List<BossStatisticsModel> get statistics => _statistics;
  List<BossStatisticsGraphicModel> get graphics => _graphics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get startDate => _startDate;
  String get endDate => _endDate;

  // Detay getter'ları
  List<BossStatisticsDetailModel> get detailStatistics => _detailStatistics;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;
  BossStatisticsDetailData? get detailData => _detailData;

  // Grafik verileri için yardımcı metodlar
  double get totalGraphicAmount {
    return _graphics.fold(0.0, (sum, graphic) => sum + graphic.numericAmount);
  }

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
    String order = '',
  }) async {
    _logger.i('🔄 Boss Statistics ViewModel: Veri çekme başlatılıyor...');
    _logger.d('📋 Parametreler: userToken: $userToken, compID: $compID, startDate: $startDate, endDate: $endDate, order: $order');
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getBossStatistics(
        userToken: userToken,
        compID: compID,
        startDate: startDate,
        endDate: endDate,
        order: order,
      );

      if (response.success && !response.error) {
        _statistics = response.data.statistics;
        _graphics = response.data.graphics;
        _startDate = startDate;
        _endDate = endDate;
        _logger.i('✅ Boss Statistics ViewModel: Veri başarıyla alındı. ${_statistics.length} adet istatistik, ${_graphics.length} adet grafik verisi');
        _logger.d('📊 İstatistikler: ${_statistics.map((s) => '${s.statisticsTitle}: ${s.statisticsAmount}').join(', ')}');
        _logger.d('📈 Grafik Verileri: ${_graphics.map((g) => '${g.date}: ${g.amount}').join(', ')}');
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

  Future<void> fetchBossStatisticsDetail({
    required String userToken,
    required int compID,
    required String startDate,
    required String endDate,
    required String order,
    required String filterKey,
  }) async {
    _logger.i('🔄 Boss Statistics Detail ViewModel: Detay veri çekme başlatılıyor...');
    _logger.d('📋 Parametreler: userToken: $userToken, compID: $compID, startDate: $startDate, endDate: $endDate, order: $order, filterKey: $filterKey');
    
    _isDetailLoading = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getBossStatisticsDetail(
        userToken: userToken,
        compID: compID,
        startDate: startDate,
        endDate: endDate,
        order: order,
        filterKey: filterKey,
      );

      if (response.success && !response.error) {
        _detailStatistics = response.data.statistics;
        _detailData = response.data;
        _logger.i('✅ Boss Statistics Detail ViewModel: Detay veri başarıyla alındı. ${_detailStatistics.length} adet detay');
        _logger.d('📊 Detay İstatistikler: ${_detailStatistics.map((s) => '${s.title}: ${s.count} adet, ${s.amount}').join(', ')}');
      } else {
        _logger.e('❌ Boss Statistics Detail ViewModel: API başarısız response');
        _detailErrorMessage = 'Detay veri alınamadı';
      }
    } catch (e) {
      _logger.e('❌ Boss Statistics Detail ViewModel: Hata oluştu: $e');
      _detailErrorMessage = e.toString();
    } finally {
      _isDetailLoading = false;
      _logger.d('🏁 Boss Statistics Detail ViewModel: Detay veri çekme tamamlandı. Loading: $_isDetailLoading, Error: $_detailErrorMessage');
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearDetailError() {
    _detailErrorMessage = null;
    notifyListeners();
  }

  void reset() {
    _statistics = [];
    _graphics = [];
    _isLoading = false;
    _errorMessage = null;
    _startDate = '';
    _endDate = '';
    notifyListeners();
  }

  void resetDetail() {
    _detailStatistics = [];
    _isDetailLoading = false;
    _detailErrorMessage = null;
    _detailData = null;
    notifyListeners();
  }
} 