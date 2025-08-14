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
  List<BossStatisticsProductModel> _productStatistics = [];
  List<BossStatisticsExpenseModel> _expenseStatistics = [];
  List<BossStatisticsCashierModel> _cashierStatistics = [];
  List<BossStatisticsWaiterModel> _waiterStatistics = [];
  List<BossStatisticsCategoryModel> _categoryStatistics = [];
  bool _isDetailLoading = false;
  String? _detailErrorMessage;
  BossStatisticsDetailData? _detailData;
  BossStatisticsOrderData? _orderData;
  BossStatisticsCashOrderData? _cashOrderData;
  BossStatisticsProductData? _productData;
  BossStatisticsExpenseData? _expenseData;
  BossStatisticsCashierData? _cashierData;
  BossStatisticsWaiterData? _waiterData;
  BossStatisticsCategoryData? _categoryData;
  bool _isOrderDetail = false;
  bool _isCashOrderDetail = false;
  bool _isProductDetail = false;
  bool _isExpenseDetail = false;
  bool _isCashierDetail = false;
  bool _isWaiterDetail = false;
  bool _isCategoryDetail = false;
  bool _isRefundDetail = false;

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
  List<BossStatisticsProductModel> get productStatistics => _productStatistics;
  List<BossStatisticsExpenseModel> get expenseStatistics => _expenseStatistics;
  List<BossStatisticsCashierModel> get cashierStatistics => _cashierStatistics;
  List<BossStatisticsWaiterModel> get waiterStatistics => _waiterStatistics;
  List<BossStatisticsCategoryModel> get categoryStatistics => _categoryStatistics;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailErrorMessage => _detailErrorMessage;
  BossStatisticsDetailData? get detailData => _detailData;
  BossStatisticsOrderData? get orderData => _orderData;
  BossStatisticsCashOrderData? get cashOrderData => _cashOrderData;
  BossStatisticsProductData? get productData => _productData;
  BossStatisticsExpenseData? get expenseData => _expenseData;
  BossStatisticsCashierData? get cashierData => _cashierData;
  BossStatisticsWaiterData? get waiterData => _waiterData;
  BossStatisticsCategoryData? get categoryData => _categoryData;
  bool get isOrderDetail => _isOrderDetail;
  bool get isCashOrderDetail => _isCashOrderDetail;
  bool get isProductDetail => _isProductDetail;
  bool get isExpenseDetail => _isExpenseDetail;
  bool get isCashierDetail => _isCashierDetail;
  bool get isWaiterDetail => _isWaiterDetail;
  bool get isCategoryDetail => _isCategoryDetail;
  bool get isRefundDetail => _isRefundDetail;

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
    _isProductDetail = filterKey == 'productAmount' || filterKey == 'giftProductAmount';
    _isExpenseDetail = filterKey == 'expenseAmount' || filterKey == 'incomeAmount' || filterKey == 'wasteAmount';
    _isCashierDetail = detailEndpoint == 'cashierDetail' || filterKey == 'cashierAmount';
    _isWaiterDetail = detailEndpoint == 'waiterDetail' || filterKey == 'waiterPerformance';
    _isCategoryDetail = detailEndpoint == 'categoryDetail' || filterKey == 'categoryAmount';
    _isRefundDetail = filterKey == 'refundAmount';
    notifyListeners();

    try {
      if (_isCategoryDetail) {
        final response = await _service.getBossStatisticsCategoryDetail(
          userToken: userToken,
          compID: compID,
          startDate: startDate,
          endDate: endDate,
          order: order,
          filterKey: filterKey,
          detailEndpoint: detailEndpoint,
        );

        if (response.success && !response.error) {
          _categoryStatistics = response.data.statistics;
          _categoryData = response.data;
          _waiterStatistics = [];
          _waiterData = null;
          _cashierStatistics = [];
          _cashierData = null;
          _detailStatistics = [];
          _detailData = null;
          _orderStatistics = [];
          _orderData = null;
          _cashOrderStatistics = [];
          _cashOrderData = null;
          _productStatistics = [];
          _productData = null;
          _expenseStatistics = [];
          _expenseData = null;
          _logger.i('✅ Boss Statistics Category Detail ViewModel: Kategori detay verisi başarıyla alındı. ${_categoryStatistics.length} kategori');
        } else {
          _logger.e('❌ Boss Statistics Category Detail ViewModel: API başarısız response');
          _detailErrorMessage = 'Kategori detay veri alınamadı';
        }
      } else if (_isWaiterDetail) {
        final response = await _service.getBossStatisticsWaiterDetail(
          userToken: userToken,
          compID: compID,
          startDate: startDate,
          endDate: endDate,
          order: order,
          filterKey: filterKey,
          detailEndpoint: detailEndpoint,
        );

        if (response.success && !response.error) {
          _waiterStatistics = response.data.statistics;
          _waiterData = response.data;
          _cashierStatistics = [];
          _cashierData = null;
          _detailStatistics = [];
          _detailData = null;
          _orderStatistics = [];
          _orderData = null;
          _cashOrderStatistics = [];
          _cashOrderData = null;
          _productStatistics = [];
          _productData = null;
          _expenseStatistics = [];
          _expenseData = null;
          _logger.i('✅ Boss Statistics Waiter Detail ViewModel: Garson detay verisi başarıyla alındı. ${_waiterStatistics.length} kayıt');
        } else {
          _logger.e('❌ Boss Statistics Waiter Detail ViewModel: API başarısız response');
          _detailErrorMessage = 'Garson detay veri alınamadı';
        }
      } else if (_isCashierDetail) {
        final response = await _service.getBossStatisticsCashierDetail(
          userToken: userToken,
          compID: compID,
          startDate: startDate,
          endDate: endDate,
          order: order,
          filterKey: filterKey,
          detailEndpoint: detailEndpoint,
        );

        if (response.success && !response.error) {
          _cashierStatistics = response.data.statistics;
          _cashierData = response.data;
          _detailStatistics = [];
          _detailData = null;
          _orderStatistics = [];
          _orderData = null;
          _cashOrderStatistics = [];
          _cashOrderData = null;
          _productStatistics = [];
          _productData = null;
          _expenseStatistics = [];
          _expenseData = null;
          _logger.i('✅ Boss Statistics Cashier Detail ViewModel: Kasiyer detay veri başarıyla alındı. ${_cashierStatistics.length} adet ödeme tipi');
        } else {
          _logger.e('❌ Boss Statistics Cashier Detail ViewModel: API başarısız response');
          _detailErrorMessage = 'Kasiyer detay veri alınamadı';
        }
      } else if (_isExpenseDetail) {
        // Personel giderleri için
        final response = await _service.getBossStatisticsExpenseDetail(
          userToken: userToken,
          compID: compID,
          startDate: startDate,
          endDate: endDate,
          order: order,
          filterKey: filterKey,
          detailEndpoint: detailEndpoint,
        );

        if (response.success && !response.error) {
          _expenseStatistics = response.data.statistics;
          _expenseData = response.data;
          _detailStatistics = [];
          _detailData = null;
          _orderStatistics = [];
          _orderData = null;
          _cashOrderStatistics = [];
          _cashOrderData = null;
          _productStatistics = [];
          _productData = null;
          _logger.i('✅ Boss Statistics Expense Detail ViewModel: Personel gideri detay veri başarıyla alındı. ${_expenseStatistics.length} adet gider');
        } else {
          _logger.e('❌ Boss Statistics Expense Detail ViewModel: API başarısız response');
          _detailErrorMessage = 'Personel gideri detay veri alınamadı';
        }
      } else if (_isProductDetail) {
        // Ürün detayları için
        final response = await _service.getBossStatisticsProductDetail(
          userToken: userToken,
          compID: compID,
          startDate: startDate,
          endDate: endDate,
          order: order,
          filterKey: filterKey,
          detailEndpoint: detailEndpoint,
        );

        if (response.success && !response.error) {
          _productStatistics = response.data.statistics;
          _productData = response.data;
          _detailStatistics = [];
          _detailData = null;
          _orderStatistics = [];
          _orderData = null;
          _cashOrderStatistics = [];
          _cashOrderData = null;
          _expenseStatistics = [];
          _expenseData = null;
          _logger.i('✅ Boss Statistics Product Detail ViewModel: Ürün detay veri başarıyla alındı. ${_productStatistics.length} adet ürün');
        } else {
          _logger.e('❌ Boss Statistics Product Detail ViewModel: API başarısız response');
          _detailErrorMessage = 'Ürün detay veri alınamadı';
        }
      } else if (_isCashOrderDetail) {
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
          _productStatistics = [];
          _productData = null;
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
          _productStatistics = [];
          _productData = null;
          _expenseStatistics = [];
          _expenseData = null;
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
          _productStatistics = [];
          _productData = null;
          _expenseStatistics = [];
          _expenseData = null;
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
    _productStatistics = [];
    _expenseStatistics = [];
    _cashierStatistics = [];
    _waiterStatistics = [];
    _categoryStatistics = [];
    _isDetailLoading = false;
    _detailErrorMessage = null;
    _detailData = null;
    _orderData = null;
    _cashOrderData = null;
    _productData = null;
    _expenseData = null;
    _cashierData = null;
    _waiterData = null;
    _categoryData = null;
    _isOrderDetail = false;
    _isCashOrderDetail = false;
    _isProductDetail = false;
    _isExpenseDetail = false;
    _isCashierDetail = false;
    _isWaiterDetail = false;
    _isCategoryDetail = false;
    notifyListeners();
  }
} 