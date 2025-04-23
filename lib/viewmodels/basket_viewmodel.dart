import 'package:flutter/material.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/models/product_model.dart';

class BasketViewModel extends ChangeNotifier {
  Basket _basket = Basket();
  
  List<BasketItem> get items => _basket.items;
  double get totalAmount => _basket.totalAmount;
  double get discount => _basket.discount;
  double get collectedAmount => _basket.collectedAmount;
  double get remainingAmount => _basket.remainingAmount;
  bool get isEmpty => _basket.items.isEmpty;
  int get totalQuantity => _basket.items.fold(0, (sum, item) => sum + item.quantity);
  
  // Ürün ekleme (tekil olarak)
  void addProduct(Product product, {int opID = 0}) {
    final existingIndex = _basket.items.indexWhere((item) => item.product.proID == product.proID);
    
    if (existingIndex != -1) {
      // Mevcut ürün miktarını artır
      _basket.items[existingIndex].quantity++;
    } else {
      // Yeni ürün ekle
      _basket.items.add(BasketItem(
        product: product,
        quantity: 1,
        opID: opID
      ));
    }
    
    notifyListeners();
  }
  
  // Sepete ürün ekleme/güncelleme (özel opID ile)
  void addProductWithOpID(Product product, int quantity, int opID) {
    final existingIndex = _basket.items.indexWhere((item) => 
        item.product.proID == product.proID && item.opID == opID);
    
    if (existingIndex != -1) {
      // Aynı ürün ve opID varsa miktarını güncelle
      _basket.items[existingIndex].quantity = quantity;
    } else {
      // Yeni ürün ekle
      _basket.items.add(BasketItem(
        product: product,
        quantity: quantity,
        opID: opID
      ));
    }
    
    notifyListeners();
  }
  
  // Ürün kaldırma
  void removeProduct(int productId) {
    _basket.removeProduct(productId);
    notifyListeners();
  }
  
  // Miktar artırma
  void incrementQuantity(int productId) {
    _basket.incrementQuantity(productId);
    notifyListeners();
  }
  
  // Miktar azaltma
  void decrementQuantity(int productId) {
    _basket.decrementQuantity(productId);
    notifyListeners();
  }
  
  // Sepeti temizleme
  void clearBasket() {
    _basket.clear();
    notifyListeners();
  }
  
  // İndirim uygulama
  void applyDiscount(double amount) {
    _basket.discount = amount;
    notifyListeners();
  }
  
  // Tahsil edilen tutarı güncelleme
  void updateCollectedAmount(double amount) {
    _basket.collectedAmount = amount;
    notifyListeners();
  }

  int get itemCount => _basket.items.length;

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