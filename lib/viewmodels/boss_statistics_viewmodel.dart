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
  List<BossStatisticsOrderModel> _orderStatistics = [];
  List<BossStatisticsCashOrderModel> _cashOrderStatistics = [];
  bool _isDetailLoading = false;
  String? _detailErrorMessage;
  BossStatisticsDetailData? _detailData;
  BossStatisticsOrderData? _orderData;
  BossStatisticsCashOrderData? _cashOrderData;
  bool _isOrderDetail = false;
  bool _isCashOrderDetail = false;

  List<BossStatisticsModel> get statistics => _statistics;
  List<BossStatisticsGraphicModel> get graphics => _graphics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get startDate => _startDate;
  String get endDate => _endDate;

  // Detay getter'ları
  List<BossStatisticsDetailModel> get detailStatistics => _detailStatistics;
  List<BossStatisticsOrderModel> get orderStatistics => _orderStatistics;
  List<BossStatisticsCashOrderModel> get cashOrderStatistics => _cashOrderStatistics;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;
  BossStatisticsDetailData? get detailData => _detailData;
  BossStatisticsOrderData? get orderData => _orderData;
  BossStatisticsCashOrderData? get cashOrderData => _cashOrderData;
  bool get isOrderDetail => _isOrderDetail;
  bool get isCashOrderDetail => _isCashOrderDetail;

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
    required String detailEndpoint,
  }) async {
    _logger.i('🔄 Boss Statistics Detail ViewModel: Detay veri çekme başlatılıyor...');
    _logger.d('📋 Parametreler: userToken: $userToken, compID: $compID, startDate: $startDate, endDate: $endDate, order: $order, filterKey: $filterKey, detailEndpoint: $detailEndpoint');
    
    _isDetailLoading = true;
    _detailErrorMessage = null;
    _isOrderDetail = detailEndpoint == 'orderListDetail';
    _isCashOrderDetail = filterKey == 'cashAmount';
    notifyListeners();

    try {
      if (_isCashOrderDetail) {
        // Nakit ödemeler için
        final response = await _service.getBossStatisticsCashOrderDetail(
          userToken: userToken,
          compID: compID,
          startDate: startDate,
          endDate: endDate,
          order: order,
          filterKey: filterKey,
          detailEndpoint: detailEndpoint,
        );

        if (response.success && !response.error) {
          _cashOrderStatistics = response.data.statistics;
          _cashOrderData = response.data;
          _orderStatistics = [];
          _orderData = null;
          _detailStatistics = [];
          _detailData = null;
          _logger.i('✅ Boss Statistics Cash Order Detail ViewModel: Nakit ödeme detay veri başarıyla alındı. ${_cashOrderStatistics.length} adet sipariş');
        } else {
          _logger.e('❌ Boss Statistics Cash Order Detail ViewModel: API başarısız response');
          _detailErrorMessage = 'Nakit ödeme detay veri alınamadı';
        }
      } else if (_isOrderDetail) {
        // Sipariş detayları için
        final response = await _service.getBossStatisticsOrderDetail(
          userToken: userToken,
          compID: compID,
          startDate: startDate,
          endDate: endDate,
          order: order,
          filterKey: filterKey,
          detailEndpoint: detailEndpoint,
        );

        if (response.success && !response.error) {
          _orderStatistics = response.data.statistics;
          _orderData = response.data;
          _detailStatistics = [];
          _detailData = null;
          _cashOrderStatistics = [];
          _cashOrderData = null;
          _logger.i('✅ Boss Statistics Order Detail ViewModel: Sipariş detay veri başarıyla alındı. ${_orderStatistics.length} adet sipariş');
        } else {
          _logger.e('❌ Boss Statistics Order Detail ViewModel: API başarısız response');
          _detailErrorMessage = 'Sipariş detay veri alınamadı';
        }
      } else {
        // Normal detaylar için
        final response = await _service.getBossStatisticsDetail(
          userToken: userToken,
          compID: compID,
          startDate: startDate,
          endDate: endDate,
          order: order,
          filterKey: filterKey,
          detailEndpoint: detailEndpoint,
        );

        if (response.success && !response.error) {
          _detailStatistics = response.data.statistics;
          _detailData = response.data;
          _orderStatistics = [];
          _orderData = null;
          _cashOrderStatistics = [];
          _cashOrderData = null;
          _logger.i('✅ Boss Statistics Detail ViewModel: Detay veri başarıyla alındı. ${_detailStatistics.length} adet detay');
          _logger.d('📊 Detay İstatistikler: ${_detailStatistics.map((s) => '${s.title}: ${s.count} adet, ${s.amount}').join(', ')}');
        } else {
          _logger.e('❌ Boss Statistics Detail ViewModel: API başarısız response');
          _detailErrorMessage = 'Detay veri alınamadı';
        }
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
    _orderStatistics = [];
    _cashOrderStatistics = [];
    _isDetailLoading = false;
    _detailErrorMessage = null;
    _detailData = null;
    _orderData = null;
    _cashOrderData = null;
    _isOrderDetail = false;
    _isCashOrderDetail = false;
    notifyListeners();
  }
} 