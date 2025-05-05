import 'package:pos701/models/product_model.dart';
import 'dart:developer' as developer;

class BasketItem {
  final Product product;
  int proQty;
  final int opID;
  String proNote;
  bool isGift;
  final int lineId; // Benzersiz satır kimliği
  int isRemove; // Ürün siparişten çıkarılacaksa 1 olacak
  
  // Birim fiyat hesaplama metodu - proPrice'ı temizleyip işler
  double get birimFiyat {
    try {
      // Fiyat formatını temizle - TL, ₺, boşluk ve noktalama işaretlerini düzgün işle
      String priceStr = product.proPrice
          .replaceAll("TL", "")
          .replaceAll("₺", "")
          .replaceAll(" ", "")
          .trim();
      
      // Türkçe ondalık ayırıcısı (virgül) varsa noktaya çevir
      if (priceStr.contains(",")) {
        priceStr = priceStr.replaceAll(",", ".");
      }
      
      // Debug için - sadece başlangıçta gösteriyoruz, her hesaplamada değil
      // developer.log("Birim fiyat hesaplanıyor: '${product.proName}' - '${product.proPrice}' -> '$priceStr'");
      
      double price = double.tryParse(priceStr) ?? 0.0;
      if (price <= 0) {
        developer.log("Birim fiyat 0 veya negatif: $price, orijinal değer: ${product.proPrice}");
      }
      return price;
    } catch (e) {
      developer.log("Birim fiyat hesaplama hatası: ${e.toString()}", error: e);
      return 0.0;
    }
  }
  
  // Cache için
  double? _cachedPrice;
  int? _cachedQuantity;
  
  double get totalPrice {
    // İkram ürün ise 0 TL
    if (isGift) return 0.0;
    
    // Eğer miktar değişmemişse ve fiyat hesaplanmışsa, önbelleği kullan
    if (_cachedQuantity == proQty && _cachedPrice != null) {
      return _cachedPrice!;
    }
    
    // Birim fiyatı miktar ile çarp
    final double total = birimFiyat * proQty;
    
    // Önbelleğe al
    _cachedPrice = total;
    _cachedQuantity = proQty;
    
    // Loglaması kaldırıldı, gereksiz tekrarlara neden oluyordu
    // developer.log("Toplam fiyat hesaplandı: '${product.proName}' - $total (birim fiyat: $birimFiyat x miktar: $quantity)");
    
    return total;
  }

  BasketItem({
    required this.product,
    required this.proQty,
    this.opID = 0,
    String? proNote,
    this.isGift = false,
    this.lineId = 0, // Varsayılan değer 0, ama kullanılırken benzersiz değer atanmalı
    this.isRemove = 0, // Varsayılan olarak ürün siparişten çıkarılmayacak
  }) : proNote = proNote ?? product.proNote {
    // Oluşturulduğunda fiyatı kontrol et
    developer.log("Yeni sepet öğesi: ${product.proName}, Miktar: $proQty, OpID: $opID, Not: $proNote, İkram: $isGift, Satır ID: $lineId, Çıkarılacak: $isRemove");
  }
  
  @override
  String toString() {
    return 'BasketItem{product: ${product.proName}, quantity: $proQty, opID: $opID, proNote: $proNote, isGift: $isGift, lineId: $lineId, isRemove: $isRemove}';
  }
}

class Basket {
  List<BasketItem> items = [];
  double discount = 0.0;
  double orderPayAmount = 0.0;
  int _nextLineId = -1; // Negatif ID'lerle başlayarak geçici satırlar oluştur (-1, -2, ...)
  
  // Cache için
  double? _cachedTotalAmount;
  List<int>? _cachedItemIds;
  List<int>? _cachedQuantities;
  
  // Benzersiz bir lineId üret
  int getNextLineId() {
    // opID > 0 olan satırlar sunucudan geliyor, lineId olarak opID kullanılabilir
    // opID olmayan (geçici) satırlar için negatif benzersiz ID üret
    return _nextLineId--;
  }
  
  // Toplam sepet tutarını hesapla (önbellekle)
  double get totalAmount {
    // Sepet içeriğinin değişip değişmediğini kontrol et
    final currentItemIds = items.map((e) => e.product.proID).toList();
    final currentQuantities = items.map((e) => e.proQty).toList();
    
    // Eğer sepet içeriği değişmemişse ve önbellek değeri varsa, önbelleği kullan
    if (_cachedTotalAmount != null && 
        _cachedItemIds != null && 
        _cachedQuantities != null &&
        _listEquals(currentItemIds, _cachedItemIds!) &&
        _listEquals(currentQuantities, _cachedQuantities!)) {
      return _cachedTotalAmount!;
    }
    
    // Sepet boşsa hemen 0 dön
    if (items.isEmpty) {
      _cachedTotalAmount = 0;
      _cachedItemIds = [];
      _cachedQuantities = [];
      return 0;
    }
    
    double total = 0.0;
    
    // Sadece değer hesapla, gereksiz log oluşturma
    for (var item in items) {
      total += item.birimFiyat * item.proQty;
    }
    
    // Önbelleğe al
    _cachedTotalAmount = total;
    _cachedItemIds = currentItemIds;
    _cachedQuantities = currentQuantities;
    
    // Sadece bir kez debugging için logla
    developer.log("Sepet: ${items.length} çeşit, ${items.fold(0, (sum, item) => sum + item.proQty)} adet ürün, Toplam: $total TL");
    
    return total;
  }

  // Liste karşılaştırma yardımcı metodu  
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  double get remainingAmount => totalAmount - discount - orderPayAmount;

  void addProduct(Product product, {int opID = 0}) {
    developer.log("Sepete ürün ekleniyor: ${product.proName}, ID: ${product.proID}, Fiyat: ${product.proPrice}, OpID: $opID");
    
    // Benzersiz bir lineId oluştur
    int lineId = opID > 0 ? opID : getNextLineId();
    
    // Her seferinde yeni bir satır ekle, aynı ürünleri birleştirme
    items.add(BasketItem(
      product: product, 
      proQty: 1, 
      opID: opID,
      lineId: lineId
    ));
    
    developer.log("Yeni ürün sepete eklendi. Sepetteki ürün sayısı: ${items.length}, LineID: $lineId");
  }

  void removeProduct(int productId, {int? opID, int? lineId}) {
    if (lineId != null) {
      // Belirli bir lineId'ye sahip satırı kaldır
      developer.log("Sepetten belirli satır kaldırılıyor. LineID: $lineId");
      items.removeWhere((item) => item.lineId == lineId);
    }
    else if (opID != null) {
      // Belirli bir opID'ye sahip ürünü kaldır
      developer.log("Sepetten ürün kaldırılıyor. Ürün ID: $productId, OpID: $opID");
      items.removeWhere((item) => item.product.proID == productId && item.opID == opID);
    } else {
      // Tüm ürünleri kaldır (proID'ye göre)
      developer.log("Sepetten ürün kaldırılıyor. Ürün ID: $productId, tüm satırlar");
      items.removeWhere((item) => item.product.proID == productId);
    }
    
    developer.log("Sepetteki satır sayısı: ${items.length}");
  }

  void incrementQuantity(int lineId) {
    try {
      // Belirli bir lineId'ye sahip satırın miktarını artır
      final item = items.firstWhere((item) => item.lineId == lineId);
      item.proQty++;
      developer.log("Ürün miktarı artırıldı. Ürün: ${item.product.proName}, Miktar: ${item.proQty}, LineID: ${item.lineId}");
    } catch (e) {
      developer.log("Satır bulunamadı, miktar artırılamadı. LineID: $lineId", error: e);
    }
  }

  void decrementQuantity(int lineId) {
    try {
      // Belirli bir lineId'ye sahip satırın miktarını azalt
      final item = items.firstWhere((item) => item.lineId == lineId);
      if (item.proQty > 1) {
        item.proQty--;
        developer.log("Ürün miktarı azaltıldı. Ürün: ${item.product.proName}, Miktar: ${item.proQty}, LineID: ${item.lineId}");
      } else {
        items.remove(item);
        developer.log("Satır sepetten kaldırıldı. Son adet olduğu için. LineID: ${item.lineId}");
      }
    } catch (e) {
      developer.log("Satır bulunamadı, miktar azaltılamadı. LineID: $lineId", error: e);
    }
  }
  
  // Ürün ID'si ile miktar artırma/azaltma için uyumluluk metodları
  void incrementProductQuantity(int productId) {
    try {
      var productItems = items.where((item) => item.product.proID == productId).toList();
      if (productItems.isNotEmpty) {
        // En son eklenen satırı bul
        productItems.sort((a, b) => b.lineId.compareTo(a.lineId));
        incrementQuantity(productItems.first.lineId);
      }
    } catch (e) {
      developer.log("Ürün miktarını artırırken hata: $e", error: e);
    }
  }

  void decrementProductQuantity(int productId) {
    try {
      var productItems = items.where((item) => item.product.proID == productId).toList();
      if (productItems.isNotEmpty) {
        // En son eklenen satırı bul
        productItems.sort((a, b) => b.lineId.compareTo(a.lineId));
        decrementQuantity(productItems.first.lineId);
      }
    } catch (e) {
      developer.log("Ürün miktarını azaltırken hata: $e", error: e);
    }
  }

  void clear() {
    developer.log("Sepet temizleniyor. Önceki ürün sayısı: ${items.length}");
    items.clear();
    discount = 0.0;
    orderPayAmount = 0.0;
    developer.log("Sepet temizlendi.");
  }
  
  @override
  String toString() {
    return 'Basket(items: ${items.length}, totalAmount: $totalAmount, discount: $discount, orderPayAmount: $orderPayAmount, remainingAmount: $remainingAmount)';
  }
} 