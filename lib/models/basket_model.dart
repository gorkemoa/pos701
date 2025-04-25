import 'package:pos701/models/product_model.dart';
import 'dart:developer' as developer;

class BasketItem {
  final Product product;
  int proQty;
  final int opID;
  
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
  }) {
    // Oluşturulduğunda fiyatı kontrol et
    developer.log("Yeni sepet öğesi: ${product.proName}, Miktar: $proQty, OpID: $opID");
  }
  
  @override
  String toString() {
    return 'BasketItem{product: ${product.proName}, quantity: $proQty, opID: $opID}';
  }
}

class Basket {
  List<BasketItem> items = [];
  double discount = 0.0;
  double orderPayAmount = 0.0;
  
  // Cache için
  double? _cachedTotalAmount;
  List<int>? _cachedItemIds;
  List<int>? _cachedQuantities;
  
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
    
    // OpID'yi de dikkate alarak mevcut ürünü ara
    final existingItemIndex = items.indexWhere(
      (item) => item.product.proID == product.proID && item.opID == opID
    );
    
    if (existingItemIndex != -1) {
      items[existingItemIndex].proQty++;
      developer.log("Mevcut ürün miktarı artırıldı: ${items[existingItemIndex].proQty}, OpID: $opID");
    } else {
      items.add(BasketItem(product: product, proQty: 1, opID: opID));
      developer.log("Yeni ürün sepete eklendi. Sepetteki ürün sayısı: ${items.length}, OpID: $opID");
    }
  }

  void removeProduct(int productId, {int? opID}) {
    developer.log("Sepetten ürün kaldırılıyor. Ürün ID: $productId, OpID: ${opID ?? 'tümü'}");
    
    if (opID != null) {
      // Belirli bir opID'ye sahip ürünü kaldır
      items.removeWhere((item) => item.product.proID == productId && item.opID == opID);
    } else {
      // Tüm ürünleri kaldır (proID'ye göre)
      items.removeWhere((item) => item.product.proID == productId);
    }
    
    developer.log("Sepetteki ürün sayısı: ${items.length}");
  }

  void incrementQuantity(int productId) {
    try {
      // Önce opID=0 olan ürünleri ara (yeni eklenmiş ürünler)
      var newItems = items.where((item) => item.product.proID == productId && item.opID == 0).toList();
      
      if (newItems.isNotEmpty) {
        // Yeni eklenmiş ürün varsa ilk onu artır
        newItems.first.proQty++;
        developer.log("Yeni eklenen ürün miktarı artırıldı. Ürün: ${newItems.first.product.proName}, Miktar: ${newItems.first.proQty}");
        return;
      }
      
      // Eğer yeni eklenmiş ürün yoksa, ilk bulunan ürünü artır
      final item = items.firstWhere((item) => item.product.proID == productId);
      item.proQty++;
      developer.log("Ürün miktarı artırıldı. Ürün: ${item.product.proName}, Miktar: ${item.proQty}, OpID: ${item.opID}");
    } catch (e) {
      developer.log("Ürün miktarını artırırken hata: $e", error: e);
    }
  }

  void decrementQuantity(int productId) {
    try {
      // Önce opID=0 olan ürünleri ara (yeni eklenmiş ürünler)
      var newItems = items.where((item) => item.product.proID == productId && item.opID == 0).toList();
      
      if (newItems.isNotEmpty) {
        // Yeni eklenmiş ürün varsa ilk onu azalt
        if (newItems.first.proQty > 1) {
          newItems.first.proQty--;
          developer.log("Yeni eklenen ürün miktarı azaltıldı. Ürün: ${newItems.first.product.proName}, Miktar: ${newItems.first.proQty}");
        } else {
          items.remove(newItems.first);
          developer.log("Yeni eklenen ürün sepetten kaldırıldı. Son ürün olduğu için.");
        }
        return;
      }
      
      // Eğer yeni eklenmiş ürün yoksa, ilk bulunan ürünü azalt
      final item = items.firstWhere((item) => item.product.proID == productId);
      if (item.proQty > 1) {
        item.proQty--;
        developer.log("Ürün miktarı azaltıldı. Ürün: ${item.product.proName}, Miktar: ${item.proQty}, OpID: ${item.opID}");
      } else {
        items.remove(item);
        developer.log("Ürün sepetten kaldırıldı. Son ürün olduğu için. OpID: ${item.opID}");
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