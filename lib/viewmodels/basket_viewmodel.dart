import 'package:flutter/material.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/models/product_model.dart';

class BasketViewModel extends ChangeNotifier {
  Basket _basket = Basket();
  double _orderAmount = 0;
  
  List<BasketItem> get items => _basket.items;
  double get totalAmount => _basket.totalAmount;
  double get discount => _basket.discount;
  double get orderPayAmount => _basket.orderPayAmount;
  double get orderAmount => _orderAmount;
  double get remainingAmount => orderAmount - discount - orderPayAmount;
  bool get isEmpty => _basket.items.isEmpty;
  int get totalQuantity => _basket.items.fold(0, (sum, item) => sum + item.proQty);
  int get itemCount => _basket.items.length;
  
  void setOrderAmount(double amount) {
    _orderAmount = amount;
    notifyListeners();
  }
  
  void addProduct(Product product, {int opID = 0, String? proNote, bool isGift = false}) {
    final existingIndex = _basket.items.indexWhere(
      (item) => item.product.proID == product.proID && item.opID == opID
    );
    
    if (existingIndex != -1) {
      _basket.items[existingIndex].proQty++;
      if (proNote != null) {
        _basket.items[existingIndex].proNote = proNote;
      }
      _basket.items[existingIndex].isGift = isGift;
    } else {
      _basket.items.add(BasketItem(
        product: product,
        proQty: 1,
        opID: opID,
        proNote: proNote,
        isGift: isGift,
      ));
    }
    
    notifyListeners();
  }
  
  void addProductWithOpID(Product product, int quantity, int opID, {String? proNote, bool isGift = false}) {
    final existingIndex = _basket.items.indexWhere((item) => 
        item.product.proID == product.proID && item.opID == opID);
    
    if (existingIndex != -1) {
      _basket.items[existingIndex].proQty = quantity;
      if (proNote != null) {
        _basket.items[existingIndex].proNote = proNote;
      }
      _basket.items[existingIndex].isGift = isGift;
    } else {
      _basket.items.add(BasketItem(
        product: product,
        proQty: quantity,
        opID: opID,
        proNote: proNote,
        isGift: isGift,
      ));
    }
    
    notifyListeners();
  }
  
  void removeProduct(int productId, {int? opID}) {
    _basket.removeProduct(productId, opID: opID);
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
  
  void clearBasket() {
    if (_basket.items.isEmpty && _orderAmount == 0.0 && _basket.discount == 0.0 && _basket.orderPayAmount == 0.0) {
      return;
    }
    
    _basket.clear();
    _orderAmount = 0.0;
    
    try {
      notifyListeners();
    } catch (e) {
      // Hatayı yut, uygulama çökmemeli
    }
  }
  
  void applyDiscount(double amount) {
    _basket.discount = amount;
    notifyListeners();
  }
  
  void updateOrderPayAmount(double amount) {
    _basket.orderPayAmount = amount;
    notifyListeners();
  }

  int getProductQuantity(Product product) {
    int totalQuantity = 0;
    for (var item in _basket.items) {
      if (item.product.proID == product.proID) {
        totalQuantity += item.proQty;
      }
    }
    return totalQuantity;
  }

  void decreaseProduct(Product product) {
    final newProductIndex = _basket.items.indexWhere(
      (item) => item.product.proID == product.proID && item.opID == 0,
    );
    
    if (newProductIndex != -1) {
      if (_basket.items[newProductIndex].proQty > 1) {
        _basket.items[newProductIndex].proQty--;
      } else {
        _basket.items.removeAt(newProductIndex);
      }
      notifyListeners();
      return;
    }
    
    final existingItemIndex = _basket.items.indexWhere(
      (item) => item.product.proID == product.proID,
    );
    
    if (existingItemIndex != -1) {
      if (_basket.items[existingItemIndex].proQty > 1) {
        _basket.items[existingItemIndex].proQty--;
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
      final int mevcutMiktar = _basket.items[existingItemIndex].proQty;
      _basket.items[existingItemIndex] = BasketItem(
        product: yeniPorsiyon,
        proQty: mevcutMiktar,
      );
    } else {
      _basket.addProduct(yeniPorsiyon);
    }
    
    notifyListeners();
  }

  void updateSpecificItem(int oldProID, Product newProduct, int quantity, {String? proNote, bool? isGift}) {
    String? oldNote;
    bool oldIsGift = false;
    final oldItemIndex = _basket.items.indexWhere((item) => item.product.proID == oldProID);
    if (oldItemIndex != -1) {
      oldNote = _basket.items[oldItemIndex].proNote;
      oldIsGift = _basket.items[oldItemIndex].isGift;
    }
    
    _basket.removeProduct(oldProID);
    
    _basket.items.add(BasketItem(
      product: newProduct,
      proQty: quantity,
      proNote: proNote ?? oldNote ?? newProduct.proNote,
      isGift: isGift ?? oldIsGift,
    ));
    
    notifyListeners();
  }

  void updateProductNote(int productId, String note) {
    try {
      final item = items.firstWhere((item) => item.product.proID == productId);
      item.proNote = note;
      notifyListeners();
    } catch (e) {
      // Hata durumunu sessizce geç
    }
  }
  
  void updateProductPrice(int productId, String newPrice) {
    try {
      final itemIndex = items.indexWhere((item) => item.product.proID == productId);
      if (itemIndex != -1) {
        final item = items[itemIndex];
        
        final updatedProduct = Product(
          postID: item.product.postID,
          proID: item.product.proID,
          proName: item.product.proName,
          proUnit: item.product.proUnit,
          proStock: item.product.proStock,
          proPrice: newPrice,
          proNote: item.product.proNote,
        );
        
        final updatedItem = BasketItem(
          product: updatedProduct,
          proQty: item.proQty,
          opID: item.opID,
          proNote: item.proNote,
          isGift: item.isGift,
        );
        
        items[itemIndex] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      // Hata durumunu sessizce geç
    }
  }

  void toggleGiftStatus(int productId, {int? opID, bool? isGift}) {
    final existingIndex = opID != null 
        ? _basket.items.indexWhere((item) => item.product.proID == productId && item.opID == opID)
        : _basket.items.indexWhere((item) => item.product.proID == productId);
    
    if (existingIndex != -1) {
      if (isGift != null) {
        _basket.items[existingIndex].isGift = isGift;
      } else {
        _basket.items[existingIndex].isGift = !_basket.items[existingIndex].isGift;
      }
      notifyListeners();
    }
  }
} 