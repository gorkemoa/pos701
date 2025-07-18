import 'package:flutter/material.dart';
import 'package:pos701/models/product_model.dart';
import 'package:pos701/services/product_service.dart';
import 'package:pos701/utils/app_logger.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _productService;
  final AppLogger _logger = AppLogger();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  int? _categoryId;
  String? _categoryName;
  String _searchQuery = '';
  
  ProductViewModel(this._productService) {
    _logger.i('ProductViewModel başlatıldı');
  }
  
  List<Product> get products => _searchQuery.isEmpty ? _products : _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProducts => _products.isNotEmpty;
  int? get categoryId => _categoryId;
  String? get categoryName => _categoryName;
  
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
      _logger.w('ProductViewModel dispose edilmiş durumda, bildirim gönderilemiyor');
    }
  }
  
  void setCategoryInfo(int id, String name) {
    _categoryId = id;
    _categoryName = name;
  }
  
  Future<bool> loadProductsOfCategory(String userToken, int compID, int catID) async {
    _logger.i('$catID ID\'li kategoriye ait ürünler yükleniyor. CompID: $compID');
    
    _isLoading = true;
    _errorMessage = null;
    _categoryId = catID;
    _searchQuery = '';
    _safeNotifyListeners();
    
    try {
      final response = await _productService.getProductsOfCategory(
        userToken: userToken,
        compID: compID,
        catID: catID,
      );
      
      _isLoading = false;
      
      if (response.success && response.data != null) {
        _products = response.data!.products;
        _filteredProducts = [..._products];
        _logger.i('Ürünler başarıyla yüklendi. Ürün sayısı: ${_products.length}');
        _safeNotifyListeners();
        return true;
      } else {
        // API'den gelen özel mesajları kontrol et
        if (response.error == false && response.success == false) {
          // Bu durumda kategoride ürün yok, ancak bu bir hata değil
          _products = [];
          _filteredProducts = [];
          _logger.i('Bu kategoride ürün bulunmuyor.');
          _safeNotifyListeners();
          return true;
        } else {
          _errorMessage = 'Ürünler yüklenemedi';
          _logger.w('Ürün yükleme başarısız: ${response.error}');
          _safeNotifyListeners();
          return false;
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Bir hata oluştu: ${e.toString()}';
      _logger.e('Ürünler yüklenirken hata oluştu', e);
      _safeNotifyListeners();
      return false;
    }
  }
  
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.proID == id);
    } catch (e) {
      _logger.w('ID: $id olan ürün bulunamadı');
      return null;
    }
  }
  
  void filterProductsByName(String query) {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredProducts = [..._products];
    } else {
      _filteredProducts = _products.where((product) => 
        product.proName.toLowerCase().contains(query.toLowerCase())).toList();
      
      _logger.i('Ürünler "$query" aramasına göre filtrelendi. Sonuç: ${_filteredProducts.length} ürün');
    }
    
    _safeNotifyListeners();
  }
}