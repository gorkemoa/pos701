import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/models/product_model.dart';
import 'package:pos701/services/order_service.dart';
import 'dart:developer' as developer;

class BasketViewModel extends ChangeNotifier {
  Basket _basket = Basket();
  double _orderAmount = 0;
  List<int> _newlyAddedProductIds = []; // Yeni eklenen ürün ID'leri
  List<int> _newlyAddedLineIds = []; // Yeni eklenen satır ID'leri
  String? _errorMessage;
  
  List<BasketItem> get items => _basket.items;
  double get totalAmount => _basket.totalAmount;
  double get discount => _basket.discount;
  double get orderPayAmount => _basket.orderPayAmount;
  double get orderAmount => _orderAmount;
  double get remainingAmount => orderAmount - discount - orderPayAmount;
  bool get isEmpty => _basket.items.isEmpty;
  int get totalQuantity => _basket.items.fold(0, (sum, item) => sum + item.proQty);
  int get itemCount => _basket.items.length;
  List<int> get newlyAddedProductIds => _newlyAddedProductIds;
  List<int> get newlyAddedLineIds => _newlyAddedLineIds;
  String? get errorMessage => _errorMessage;
  
  void setOrderAmount(double amount) {
    _orderAmount = amount;
    notifyListeners();
  }
  
  // Yeni satır ekler ve eklenen satırın lineId'sini döndürür
  int addProduct(Product product, {int opID = 0, String? proNote, bool isGift = false}) {
    // Her zaman yeni bir satır oluşturuyoruz
    int lineId = opID > 0 ? opID : _basket.getNextLineId();
    
    // Yeni satır ekle
      _basket.items.add(BasketItem(
        product: product,
        proQty: 1,
        opID: opID,
        proNote: proNote,
        isGift: isGift,
      lineId: lineId,
      ));
    
    // Yeni eklenen ürünü ve satırı işaretle
      _newlyAddedProductIds.add(product.proID);
    _newlyAddedLineIds.add(lineId);
    
    developer.log("Sepete yeni satır eklendi. LineID: $lineId, Ürün: ${product.proName}");
    notifyListeners();
    
    return lineId; // Eklenen satırın ID'sini döndür
  }
  
  /// Ürünü sepete ekler ve API ile sunucuya direkt gönderir
  /// Başarılı olduğunda opID güncellenmiş ürünü sepete ekler
  Future<bool> addProductToOrder({
    required String userToken,
    required int compID,
    required int orderID,
    required Product product,
    int quantity = 1,
    String? proNote,
    bool isGift = false,
  }) async {
    try {
      // Önce ürünü sepete geçici olarak ekleyelim (negatif lineId ile)
      int tempLineId = addProduct(product, opID: 0, proNote: proNote, isGift: isGift);
      
      // Sunucuya ürün ekleme isteği gönder
      final orderService = OrderService();
      final response = await orderService.addProductToOrder(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        productID: product.proID,
        quantity: quantity,
        proNote: proNote,
        isGift: isGift ? 1 : 0,
      );
      
      if (response.success) {
        // Başarılı ise, geçici lineId'li satırı sepetten çıkarıp, 
        // sunucudan gelen opID ile yeni satır ekleyelim
        final tempIndex = _basket.items.indexWhere(
          (item) => item.lineId == tempLineId
        );
        
        if (tempIndex != -1) {
          // Geçici satırı sil
          _basket.items.removeAt(tempIndex);
          _newlyAddedLineIds.remove(tempLineId);
          
          // Sunucudan dönen opID ile ekle
          final int opID = response.data?.opID ?? 0;
          if (opID > 0) {
            _basket.items.add(BasketItem(
              product: product,
              proQty: quantity,
              opID: opID,
              proNote: proNote,
              isGift: isGift,
              lineId: opID, // Sunucudan gelen opID'yi lineId olarak kullan
            ));
            
            _newlyAddedLineIds.add(opID);
            notifyListeners();
            return true;
          }
        }
      }
      
      _errorMessage = response.errorCode ?? "Ürün eklenirken bir hata oluştu";
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = "Ürün eklenirken bir hata oluştu: $e";
      notifyListeners();
      return false;
    }
  }
  
  void addProductWithOpID(Product product, int quantity, int opID, {String? proNote, bool isGift = false}) {
    // Sunucudan gelen opID'yi hem opID hem de lineId olarak kullan
      _basket.items.add(BasketItem(
        product: product,
        proQty: quantity,
        opID: opID,
        proNote: proNote,
        isGift: isGift,
      lineId: opID,
      ));
    
    _newlyAddedProductIds.add(product.proID);
    _newlyAddedLineIds.add(opID);
    
    notifyListeners();
  }
  
  void removeProduct(int productId, {int? opID, int? lineId}) {
    if (lineId != null) {
      // Belirli bir lineId'ye sahip satırı kaldır (tercih edilen yöntem)
      _basket.removeProduct(productId, lineId: lineId);
      _newlyAddedLineIds.remove(lineId);
    } else if (opID != null) {
      // Belirli bir opID'ye sahip ürünü kaldır (geriye dönük uyumluluk)
    _basket.removeProduct(productId, opID: opID);
    } else {
      // Tüm ürünleri kaldır (proID'ye göre)
      _basket.removeProduct(productId);
    _newlyAddedProductIds.remove(productId);
    }
    notifyListeners();
  }
  
  void incrementQuantity(int lineId) {
    try {
      // Önce satırı bul
      final index = _basket.items.indexWhere((item) => item.lineId == lineId);
      
      if (index != -1) {
        // Satır bulundu, miktarı artır
        _basket.items[index].proQty++;
        developer.log("Miktar artırıldı. LineID: $lineId, Yeni miktar: ${_basket.items[index].proQty}");
        notifyListeners();
      } else {
        // Satır bulunamadı
        developer.log("Satır bulunamadı, miktar artırılamadı. LineID: $lineId");
      }
    } catch (e) {
      developer.log("Miktar artırılırken hata: $e");
    }
  }
  
  void decrementQuantity(int lineId) {
    try {
      // Önce satırı bul
      final index = _basket.items.indexWhere((item) => item.lineId == lineId);
      
      if (index == -1) {
        // Satır bulunamadı
        developer.log("Satır bulunamadı, miktar azaltılamadı. LineID: $lineId");
        return;
      }
      
      var item = _basket.items[index];
      
      // Satır bulunduysa ve bu son ürünse, yeni eklenen listelerinden kaldır
      if (item.proQty == 1) {
        _newlyAddedLineIds.remove(lineId);
        
        // Eğer bu ürün ID'sine sahip başka bir satır yoksa, ürün ID'sini de kaldır
        bool hasMoreOfThisProduct = _basket.items.any(
          (otherItem) => otherItem.product.proID == item.product.proID && otherItem.lineId != lineId
        );
        
        if (!hasMoreOfThisProduct) {
          _newlyAddedProductIds.remove(item.product.proID);
        }
        
        // Miktarı 1 olan ürünü sepetten kaldır
        _basket.items.removeAt(index);
        developer.log("Ürün sepetten kaldırıldı. LineID: $lineId");
      } else {
        // Miktarı azalt
        _basket.items[index].proQty--;
        developer.log("Miktar azaltıldı. LineID: $lineId, Yeni miktar: ${_basket.items[index].proQty}");
      }
      
      notifyListeners();
    } catch (e) {
      developer.log("Miktar azaltılırken hata: $e");
    }
  }
  
  void clearBasket() {
    if (_basket.items.isEmpty && _orderAmount == 0.0 && _basket.discount == 0.0 && _basket.orderPayAmount == 0.0) {
      return;
    }
    
    _basket.clear();
    _orderAmount = 0.0;
    _newlyAddedProductIds.clear();
    _newlyAddedLineIds.clear();
    _errorMessage = null;
    
    // Build sırasında bildirimleri güvenli şekilde yönet
    try {
      // SchedulerBinding kullanarak sonraki frame'e bildirimi ertele
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      // Hatayı yut, uygulama çökmemeli
    }
  }
  
  void clearNewlyAddedMarkers() {
    _newlyAddedProductIds.clear();
    _newlyAddedLineIds.clear();
    notifyListeners();
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

  // Geriye dönük uyumluluk için eski metod
  void decreaseProduct(Product product) {
    // Belirli bir ProductID'ye sahip en son eklenen satırı bul
    final itemsWithProduct = _basket.items
        .where((item) => item.product.proID == product.proID)
        .toList();
    
    if (itemsWithProduct.isEmpty) {
      return;
    }
    
    // Satırları lineId'ye göre sırala, en son eklenen satırı bul (en büyük negatif veya en büyük pozitif ID)
    itemsWithProduct.sort((a, b) => a.lineId.compareTo(b.lineId));
    final lastItem = itemsWithProduct.last;
    
    // Satırı azalt
    decrementQuantity(lastItem.lineId);
  }
  
  // Bu metod değişmeli - lineId üzerinden çalışmalı
  void updateProductNote(int lineId, String note) {
    try {
      final item = items.firstWhere((item) => item.lineId == lineId);
      item.proNote = note;
      notifyListeners();
    } catch (e) {
      developer.log("Satır bulunamadı, not güncellenemedi. LineID: $lineId", error: e);
    }
  }
  
  // Not güncellemesi için geriye dönük uyumluluk
  void updateProductNoteByProductId(int productId, String note) {
    try {
      // İlk bulunan satırın notunu güncelle
      final item = items.firstWhere((item) => item.product.proID == productId);
      item.proNote = note;
      notifyListeners();
    } catch (e) {
      developer.log("Ürün bulunamadı, not güncellenemedi. ProductID: $productId", error: e);
    }
  }
  
  // Bu metod değişmeli - lineId üzerinden çalışmalı
  void updateProductPrice(int lineId, String newPrice) {
    try {
      final itemIndex = items.indexWhere((item) => item.lineId == lineId);
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
          lineId: item.lineId,
        );
        
        items[itemIndex] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      developer.log("Satır bulunamadı, fiyat güncellenemedi. LineID: $lineId", error: e);
    }
  }

  // Fiyat güncellemesi için geriye dönük uyumluluk
  void updateProductPriceByProductId(int productId, String newPrice) {
    try {
      final itemIndex = items.indexWhere((item) => item.product.proID == productId);
      if (itemIndex != -1) {
        updateProductPrice(items[itemIndex].lineId, newPrice);
      }
    } catch (e) {
      developer.log("Ürün bulunamadı, fiyat güncellenemedi. ProductID: $productId", error: e);
    }
  }

  void toggleGiftStatus(int lineId, {bool? isGift}) {
    try {
      final item = items.firstWhere((item) => item.lineId == lineId);
      if (isGift != null) {
        item.isGift = isGift;
      } else {
        item.isGift = !item.isGift;
      }
      notifyListeners();
    } catch (e) {
      developer.log("Satır bulunamadı, ikram durumu değiştirilemedi. LineID: $lineId", error: e);
    }
  }
  
  // İkram durumu güncellemesi için geriye dönük uyumluluk
  void toggleGiftStatusByProductId(int productId, {int? opID, bool? isGift}) {
    try {
      final itemIndex = opID != null 
          ? items.indexWhere((item) => item.product.proID == productId && item.opID == opID)
          : items.indexWhere((item) => item.product.proID == productId);
      
      if (itemIndex != -1) {
        toggleGiftStatus(items[itemIndex].lineId, isGift: isGift);
      }
    } catch (e) {
      developer.log("Ürün bulunamadı, ikram durumu değiştirilemedi. ProductID: $productId", error: e);
    }
  }
  
  // Tek bir satırı belirli bir ürünle değiştir
  void updateSpecificLine(int lineId, Product newProduct, int quantity, {String? proNote, bool? isGift}) {
    try {
      final oldItemIndex = _basket.items.indexWhere((item) => item.lineId == lineId);
      if (oldItemIndex != -1) {
        final oldItem = _basket.items[oldItemIndex];
        
        // Eski satırı kaldır
        _basket.items.removeAt(oldItemIndex);
        
        // Yeni satır ekle, aynı lineId'yi kullan
        _basket.items.add(BasketItem(
          product: newProduct,
          proQty: quantity,
          opID: oldItem.opID,
          proNote: proNote ?? oldItem.proNote,
          isGift: isGift ?? oldItem.isGift,
          lineId: lineId,
        ));
        
        notifyListeners();
      }
    } catch (e) {
      developer.log("Satır güncellenirken hata: $e", error: e);
    }
  }
  
  // Geriye dönük uyumluluk için eski updateSpecificItem metodu
  void updateSpecificItem(int oldProID, Product newProduct, int quantity, {String? proNote, bool? isGift}) {
    try {
      // Ürün ID'sine göre ilk satırı bul
      final oldItemIndex = _basket.items.indexWhere((item) => item.product.proID == oldProID);
      if (oldItemIndex != -1) {
        final oldItem = _basket.items[oldItemIndex];
        updateSpecificLine(oldItem.lineId, newProduct, quantity, proNote: proNote, isGift: isGift);
      }
    } catch (e) {
      developer.log("Ürün güncellenirken hata: $e", error: e);
    }
  }
} 