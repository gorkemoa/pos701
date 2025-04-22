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
} 