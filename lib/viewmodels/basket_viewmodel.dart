import 'package:flutter/material.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/models/product_model.dart';
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
  double get remainingAmount => totalAmount - discount - orderPayAmount;
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
  int addProduct(
    Product product, {
    int opID = 0, 
    String? proNote, 
    bool isGift = false, 
    List<int> proFeature = const [],
    bool isMenu = false,
    List<int> menuIDs = const [],
    List<Map<String, dynamic>> menuProducts = const [],
  }) {
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
      proFeature: proFeature,
      isMenu: isMenu,
      menuIDs: menuIDs,
      menuProducts: menuProducts,
      ));
    
    // Yeni eklenen ürünü ve satırı işaretle
      _newlyAddedProductIds.add(product.proID);
    _newlyAddedLineIds.add(lineId);
    
    // Yeni ürün eklendi, backend'deki tutar artık geçersiz - sıfırla
    if (opID == 0) {
      _orderAmount = 0.0;
    }
    
    developer.log("Sepete yeni satır eklendi. LineID: $lineId, Ürün: ${product.proName}");
    notifyListeners();
    
    return lineId; // Eklenen satırın ID'sini döndür
  }
  
  /// Ürünü SADECE YEREL sepete ekler (opID=0)
  /// BasketView'da "Güncelle" butonuna basınca updateOrder ile sunucuya gönderilecek
  Future<bool> addProductToOrder({
    required String userToken,
    required int compID,
    required int orderID,
    required Product product,
    int quantity = 1,
    String? proNote,
    bool isGift = false,
    int orderPayType = 0, 
    List<int> proFeature = const [],
    bool isMenu = false,
    List<int> menuIDs = const [],
    List<Map<String, dynamic>> menuProducts = const [],
  }) async {
    developer.log("🔵 [ÜRÜN EKLEME] Yerel sepete ekleniyor: ${product.proName}, Sipariş: $orderID");
    
    // Sadece yerel sepete ekle (opID = 0)
    addProduct(
      product,
      opID: 0,
      proNote: proNote,
      isGift: isGift,
      proFeature: proFeature,
      isMenu: isMenu,
      menuIDs: menuIDs,
      menuProducts: menuProducts,
    );
    
    developer.log("🟢 [ÜRÜN EKLEME] Yerel sepete eklendi. Toplam ürün: ${_basket.items.length}");
    return true;
  }
  
  void addProductWithOpID(
    Product product, 
    int quantity, 
    int opID, {
    String? proNote, 
    bool isGift = false, 
    List<int> proFeature = const [],
    bool isMenu = false,
    List<int> menuIDs = const [],
    List<Map<String, dynamic>> menuProducts = const [],
  }) {
    // Sunucudan gelen opID'yi hem opID hem de lineId olarak kullan
      _basket.items.add(BasketItem(
        product: product,
        proQty: quantity,
        opID: opID,
        proNote: proNote,
        isGift: isGift,
      lineId: opID,
      proFeature: proFeature,
      isMenu: isMenu,
      menuIDs: menuIDs,
      menuProducts: menuProducts,
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
    
    // Ürün silindi, backend tutarı artık geçersiz
    _orderAmount = 0.0;
    
    notifyListeners();
  }
  
  // Ürünü siparişten çıkarılacak olarak işaretle (isRemove = 1)
  void markProductForRemoval(int productId, {required int opID}) {
    try {
      // opID ile eşleşen sepet öğesini bul
      final index = _basket.items.indexWhere(
        (item) => item.product.proID == productId && item.opID == opID
      );
      
      if (index != -1) {
        // Sepet öğesini bulduk, isRemove değerini 1 olarak ayarla
        _basket.items[index].isRemove = 1;
        developer.log("Ürün siparişten çıkarılacak olarak işaretlendi. Ürün: ${_basket.items[index].product.proName}, OpID: $opID, isRemove: ${_basket.items[index].isRemove}");
        
        // UI'da ürünün durumunu göster (örn. gri veya kırmızı renk)
        notifyListeners();
      } else {
        developer.log("markProductForRemoval: Sepette belirtilen ürün bulunamadı. Ürün ID: $productId, OpID: $opID");
      }
    } catch (e) {
      developer.log("Ürün işaretlenirken hata oluştu: $e");
    }
  }
  
  void incrementQuantity(int lineId) {
    try {
      // Önce satırı bul
      final index = _basket.items.indexWhere((item) => item.lineId == lineId);
      
      if (index != -1) {
        // Satır bulundu, miktarı artır
        _basket.items[index].proQty++;
        
        // Miktar değişti, backend tutarı artık geçersiz
        _orderAmount = 0.0;
        
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
        
        // Ürün silindi, backend tutarı artık geçersiz
        _orderAmount = 0.0;
        
        developer.log("Ürün sepetten kaldırıldı. LineID: $lineId");
      } else {
        // Miktarı azalt
        _basket.items[index].proQty--;
        
        // Miktar değişti, backend tutarı artık geçersiz
        _orderAmount = 0.0;
        
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
  
  /// Sunucudan gelen ürünleri temizle, ama yerel olarak eklenenleri koru
  void clearServerItems() {
    // Sadece opID > 0 olan (sunucudan gelen) ürünleri temizle
    _basket.items.removeWhere((item) => item.opID > 0);
    _orderAmount = 0.0;
    _basket.discount = 0.0;
    _basket.orderPayAmount = 0.0;
    
    developer.log("🧹 [BASKET_VM] Sunucu ürünleri temizlendi. Kalan yerel ürün: ${_basket.items.length}");
    
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      // Hatayı yut
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
          isMenu: item.product.isMenu,
        );
        
        final updatedItem = BasketItem(
          product: updatedProduct,
          proQty: item.proQty,
          opID: item.opID,
          proNote: item.proNote,
          isGift: item.isGift,
          lineId: item.lineId,
          proFeature: item.proFeature, // Özellikleri koru
          isMenu: item.isMenu,         // Menü durumunu koru
          menuIDs: item.menuIDs,       // Menü ID'lerini koru
          menuProducts: item.menuProducts, // Menü ürünlerini koru
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
  void updateSpecificLine(
    int lineId, 
    Product newProduct, 
    int quantity, {
    String? proNote, 
    bool? isGift, 
    List<int>? proFeature,
    bool? isMenu,
    List<int>? menuIDs,
    List<Map<String, dynamic>>? menuProducts,
  }) {
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
          proFeature: proFeature ?? oldItem.proFeature,
          isMenu: isMenu ?? oldItem.isMenu,
          menuIDs: menuIDs ?? oldItem.menuIDs,
          menuProducts: menuProducts ?? oldItem.menuProducts,
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