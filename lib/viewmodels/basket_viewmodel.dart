import 'package:flutter/material.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/models/product_model.dart';

class BasketViewModel extends ChangeNotifier {
  Basket _basket = Basket();
  double _orderAmount = 0; // API'den gelen sipariş tutarını saklamak için özel değişken
  
  List<BasketItem> get items => _basket.items;
  double get totalAmount => _basket.totalAmount;
  double get discount => _basket.discount;
  double get orderPayAmount => _basket.orderPayAmount;
  double get orderAmount => _orderAmount; // API'den gelen değeri döndür
  double get remainingAmount => orderAmount - discount - orderPayAmount;
  bool get isEmpty => _basket.items.isEmpty;
  int get totalQuantity => _basket.items.fold(0, (sum, item) => sum + item.proQty);
  
  // API'den gelen sipariş tutarını ayarlamak için metod
  void setOrderAmount(double amount) {
    _orderAmount = amount;
    debugPrint('💲 [BASKET_VM] API sipariş tutarı ayarlandı: $_orderAmount');
    notifyListeners();
  }
  
  // Ürün ekleme (tekil olarak)
  void addProduct(Product product, {int opID = 0, String? proNote, bool isGift = false}) {
    final existingIndex = _basket.items.indexWhere(
      (item) => item.product.proID == product.proID && item.opID == opID
    );
    
    if (existingIndex != -1) {
      // Mevcut ürün miktarını artır
      _basket.items[existingIndex].proQty++;
      // Not varsa güncelle
      if (proNote != null) {
        _basket.items[existingIndex].proNote = proNote;
      }
      // İkram durumunu güncelle
      _basket.items[existingIndex].isGift = isGift;
    } else {
      // Yeni ürün ekle
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
  
  // Sepete ürün ekleme/güncelleme (özel opID ile)
  void addProductWithOpID(Product product, int quantity, int opID, {String? proNote, bool isGift = false}) {
    // Önce debug log ekleyerek ne eklediğimizi görelim
    debugPrint('📥 [BASKET_VM] Sepete ürün ekleniyor: ${product.proName}, ProID: ${product.proID}, Miktar: $quantity, OpID: $opID, Not: ${proNote ?? product.proNote}, İkram: $isGift');
    
    // Mevcut sepetteki ürünleri logla
    for (var item in _basket.items) {
      debugPrint('🔍 [BASKET_VM] Mevcut sepet ürünü: ${item.product.proName}, ProID: ${item.product.proID}, Miktar: ${item.proQty}, OpID: ${item.opID}, Not: ${item.proNote}, İkram: ${item.isGift}');
    }

    // Aynı ürün ve opID varsa miktarını güncelle, yoksa ekle
    final existingIndex = _basket.items.indexWhere((item) => 
        item.product.proID == product.proID && item.opID == opID);
    
    if (existingIndex != -1) {
      // Aynı ürün ve opID varsa miktarını güncelle
      final oldQuantity = _basket.items[existingIndex].proQty;
      _basket.items[existingIndex].proQty = quantity;
      // Not varsa güncelle
      if (proNote != null) {
        _basket.items[existingIndex].proNote = proNote;
      }
      // İkram durumunu güncelle
      _basket.items[existingIndex].isGift = isGift;
      
      debugPrint('🔄 [BASKET_VM] Ürün güncellendi: ${product.proName}, ProID: ${product.proID}, Eski miktar: $oldQuantity, Yeni miktar: $quantity, OpID: $opID, Not: ${_basket.items[existingIndex].proNote}, İkram: ${_basket.items[existingIndex].isGift}');
    } else {
      // Yeni ürün ekle
      _basket.items.add(BasketItem(
        product: product,
        proQty: quantity,
        opID: opID,
        proNote: proNote,
        isGift: isGift,
      ));
      debugPrint('➕ [BASKET_VM] Yeni ürün eklendi: ${product.proName}, ProID: ${product.proID}, Miktar: $quantity, OpID: $opID, Not: ${proNote ?? product.proNote}, İkram: $isGift');
    }
    
    // Güncellenmiş sepet bilgisini göster
    debugPrint('📦 [BASKET_VM] Sepet durumu: ${_basket.items.length} çeşit ürün, Toplam: ${_basket.items.fold(0, (sum, item) => sum + item.proQty)} adet');
    
    notifyListeners();
  }
  
  // Ürün kaldırma
  void removeProduct(int productId, {int? opID}) {
    _basket.removeProduct(productId, opID: opID);
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
    debugPrint('🧹 [BASKET_VM] Sepet temizleme başlatıldı. Ürün sayısı: ${_basket.items.length}');
    
    // Basket modeli içindeki clear metodunu çağır
    _basket.clear();
    
    // API'den gelen sipariş tutarını da sıfırla
    _orderAmount = 0.0;
    
    debugPrint('🧹 [BASKET_VM] Sepet temizlendi. Tüm tutarlar sıfırlandı.');
    
    notifyListeners();
  }
  
  // İndirim uygulama
  void applyDiscount(double amount) {
    _basket.discount = amount;
    notifyListeners();
  }
  
  // Tahsil edilen tutarı güncelleme
  void updateOrderPayAmount(double amount) {
    _basket.orderPayAmount = amount;
    notifyListeners();
  }

  int get itemCount => _basket.items.length;

  int getProductQuantity(Product product) {
    int totalQuantity = 0;
    
    // Ürün sepetteki tüm öğeleri kontrol et
    for (var item in _basket.items) {
      // Sadece proID kontrolü değil, opID=0 olan veya aynı opID'ye sahip ürünleri say
      if (item.product.proID == product.proID) {
        totalQuantity += item.proQty;
      }
    }
    
    return totalQuantity;
  }

  void decreaseProduct(Product product) {
    // Önce opID=0 olan ürünleri azalt (yeni eklenmiş ürünler)
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
    
    // Yeni eklenen ürün yoksa, var olan ürünlerden herhangi birini azalt
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
      // Eğer ürün sepette varsa, porsiyonu güncelle
      final int mevcutMiktar = _basket.items[existingItemIndex].proQty;
      _basket.items[existingItemIndex] = BasketItem(
        product: yeniPorsiyon,
        proQty: mevcutMiktar,
      );
    } else {
      // Eğer ürün sepette yoksa, yeni ürün olarak ekle
      _basket.addProduct(yeniPorsiyon);
    }
    
    notifyListeners();
  }

  void updateSpecificItem(int oldProID, Product newProduct, int quantity, {String? proNote, bool? isGift}) {
    // Eski ürünün bilgilerini al (eğer varsa)
    String? oldNote;
    bool oldIsGift = false;
    final oldItemIndex = _basket.items.indexWhere((item) => item.product.proID == oldProID);
    if (oldItemIndex != -1) {
      oldNote = _basket.items[oldItemIndex].proNote;
      oldIsGift = _basket.items[oldItemIndex].isGift;
    }
    
    // Eski ürünü sepetten kaldır
    _basket.removeProduct(oldProID);
    
    // Yeni ürünü ekle (not ve ikram bilgisi de transfer edilecek)
    _basket.items.add(BasketItem(
      product: newProduct,
      proQty: quantity,
      proNote: proNote ?? oldNote ?? newProduct.proNote,
      isGift: isGift ?? oldIsGift,
    ));
    
    notifyListeners();
  }

  // Ürün notunu güncelle
  void updateProductNote(int productId, String note, {int? opID}) {
    final existingIndex = opID != null 
        ? _basket.items.indexWhere((item) => item.product.proID == productId && item.opID == opID)
        : _basket.items.indexWhere((item) => item.product.proID == productId);
    
    if (existingIndex != -1) {
      _basket.items[existingIndex].proNote = note;
      debugPrint('📝 [BASKET_VM] Ürün notu güncellendi: ${_basket.items[existingIndex].product.proName}, Not: $note');
      notifyListeners();
    }
  }

  // Ürünün ikram durumunu değiştir
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
      
      debugPrint('🎁 [BASKET_VM] Ürün ikram durumu değiştirildi: ${_basket.items[existingIndex].product.proName}, İkram: ${_basket.items[existingIndex].isGift}');
      notifyListeners();
    }
  }
} 