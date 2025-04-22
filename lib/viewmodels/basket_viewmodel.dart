import 'package:flutter/material.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/models/product_model.dart';

class BasketViewModel extends ChangeNotifier {
  final Basket _basket = Basket();
  
  List<BasketItem> get items => _basket.items;
  double get totalAmount => _basket.totalAmount;
  double get discount => _basket.discount;
  double get collectedAmount => _basket.collectedAmount;
  double get remainingAmount => _basket.remainingAmount;
  
  void addProduct(Product product) {
    _basket.addProduct(product);
    notifyListeners();
  }
  
  void removeProduct(int productId) {
    _basket.removeProduct(productId);
    notifyListeners();
  }
  
  void incrementQuantity(int productId) {
    _basket.incrementQuantity(productId);
    notifyListeners();
  }
  
  void decrementQuantity(int productId) {
    _basket.decrementQuantity(productId);
    notifyListeners();
  }
  
  void setDiscount(double value) {
    _basket.discount = value;
    notifyListeners();
  }
  
  void setCollectedAmount(double value) {
    _basket.collectedAmount = value;
    notifyListeners();
  }
  
  void clearBasket() {
    _basket.clear();
    notifyListeners();
  }
  
  bool get isEmpty => _basket.items.isEmpty;
  int get itemCount => _basket.items.length;
  int get totalQuantity {
    int total = 0;
    for (var item in _basket.items) {
      total += item.quantity;
    }
    return total;
  }

  int getProductQuantity(Product product) {
    final existingItem = _basket.items.firstWhere(
      (item) => item.product.proID == product.proID,
      orElse: () => BasketItem(product: product, quantity: 0),
    );
    return existingItem.quantity;
  }

  void decreaseProduct(Product product) {
    final existingItemIndex = _basket.items.indexWhere(
      (item) => item.product.proID == product.proID,
    );
    
    if (existingItemIndex != -1) {
      if (_basket.items[existingItemIndex].quantity > 1) {
        _basket.items[existingItemIndex].quantity--;
      } else {
        _basket.items.removeAt(existingItemIndex);
      }
      notifyListeners();
    }
  }
  
  void updatePorsiyon(int postID, Product yeniPorsiyon) {
    final existingItemIndex = _basket.items.indexWhere(
      (item) => item.product.postID == postID && item.product.proID == yeniPorsiyon.proID,
    );
    
    if (existingItemIndex != -1) {
      // Eğer ürün sepette varsa, porsiyonu güncelle
      final int mevcutMiktar = _basket.items[existingItemIndex].quantity;
      _basket.items[existingItemIndex] = BasketItem(
        product: yeniPorsiyon,
        quantity: mevcutMiktar,
      );
    } else {
      // Eğer ürün sepette yoksa, yeni ürün olarak ekle
      _basket.addProduct(yeniPorsiyon);
    }
    
    notifyListeners();
  }

  void updateSpecificItem(int oldProID, Product newProduct, int quantity) {
    // Eski ürünü sepetten kaldır
    _basket.removeProduct(oldProID);
    
    // Yeni ürünü ekle
    _basket.addProduct(newProduct);
    
    // Eğer miktar 1'den fazlaysa, miktarı ayarla
    for (int i = 1; i < quantity; i++) {
      _basket.incrementQuantity(newProduct.proID);
    }
    
    notifyListeners();
  }
} 