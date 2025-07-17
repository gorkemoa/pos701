import 'package:flutter/material.dart';
import 'package:pos701/models/product_category_model.dart';
import 'package:pos701/services/product_service.dart';
import 'package:pos701/utils/app_logger.dart';

class CategoryViewModel extends ChangeNotifier {
  final ProductService _productService;
  final AppLogger _logger = AppLogger();
  
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  
  CategoryViewModel(this._productService) {
    _logger.i('CategoryViewModel başlatıldı');
  }
  
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCategories => _categories.isNotEmpty;
  
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
      _logger.w('CategoryViewModel dispose edilmiş durumda, bildirim gönderilemiyor');
    }
  }
  
  Future<bool> loadCategories(String userToken, int compID) async {
    _logger.i('Kategoriler yükleniyor. CompID: $compID');
    
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();
    
    try {
      final response = await _productService.getCategories(
        userToken: userToken,
        compID: compID,
      );
      
      _isLoading = false;
      
      if (response.success && response.data != null) {
        _categories = response.data!.categories;
        // Kategorileri debugPrint ile yazdır
        for (final category in _categories) {
          debugPrint('Kategori: ID=${category.catID}, Ad=${category.catName}, Renk=${category.catColor}');
        }
        _logger.i('Kategoriler başarıyla yüklendi. Kategori sayısı: ${_categories.length}');
        _safeNotifyListeners();
        return true;
      } else {
        _errorMessage = 'Kategoriler yüklenemedi';
        _logger.w('Kategori yükleme başarısız: ${response.error}');
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Bir hata oluştu: ${e.toString()}';
      _logger.e('Kategoriler yüklenirken hata oluştu', e);
      _safeNotifyListeners();
      return false;
    }
  }
  
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((category) => category.catID == id);
    } catch (e) {
      _logger.w('ID: $id olan kategori bulunamadı');
      return null;
    }
  }
} 