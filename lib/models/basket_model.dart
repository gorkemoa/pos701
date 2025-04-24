import 'package:pos701/models/product_model.dart';
import 'dart:developer' as developer;

class BasketItem {
  final Product product;
  int quantity;
  final int opID;
  
  double get totalPrice {
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
      
      // Debug için
      developer.log("Fiyat dönüşümü: '${product.proPrice}' -> '$priceStr'");
      
      double price = double.tryParse(priceStr) ?? 0.0;
      if (price <= 0) {
        developer.log("Fiyat 0 veya negatif: $price, orijinal değer: ${product.proPrice}");
      }
      return price * quantity;
    } catch (e) {
      developer.log("Fiyat hesaplama hatası: ${e.toString()}", error: e);
      return 0.0;
    }
  }

  BasketItem({
    required this.product,
    required this.quantity,
    this.opID = 0,
  }) {
    // Oluşturulduğunda fiyatı kontrol et
    developer.log("Yeni sepet öğesi: ${product.proName}, Fiyat: ${product.proPrice}, Miktar: $quantity");
  }
  
  @override
  String toString() {
    return 'BasketItem{product: ${product.proName}, quantity: $quantity, opID: $opID, totalPrice: $totalPrice}';
  }
}

class Basket {
  List<BasketItem> items = [];
  double discount = 0.0;
  double collectedAmount = 0.0;

  double get totalAmount {
    double total = 0.0;
    for (var item in items) {
      total += item.totalPrice;
    }
    developer.log("Sepet toplam tutarı: $total (${items.length} ürün)");
    return total;
  }

  double get remainingAmount => totalAmount - discount - collectedAmount;

  void addProduct(Product product, {int opID = 0}) {
    developer.log("Sepete ürün ekleniyor: ${product.proName}, ID: ${product.proID}, Fiyat: ${product.proPrice}, OpID: $opID");
    
    // OpID'yi de dikkate alarak mevcut ürünü ara
    final existingItemIndex = items.indexWhere(
      (item) => item.product.proID == product.proID && item.opID == opID
    );
    
    if (existingItemIndex != -1) {
      items[existingItemIndex].quantity++;
      developer.log("Mevcut ürün miktarı artırıldı: ${items[existingItemIndex].quantity}, OpID: $opID");
    } else {
      items.add(BasketItem(product: product, quantity: 1, opID: opID));
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
        newItems.first.quantity++;
        developer.log("Yeni eklenen ürün miktarı artırıldı. Ürün: ${newItems.first.product.proName}, Miktar: ${newItems.first.quantity}");
        return;
      }
      
      // Eğer yeni eklenmiş ürün yoksa, ilk bulunan ürünü artır
      final item = items.firstWhere((item) => item.product.proID == productId);
      item.quantity++;
      developer.log("Ürün miktarı artırıldı. Ürün: ${item.product.proName}, Miktar: ${item.quantity}, OpID: ${item.opID}");
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
        if (newItems.first.quantity > 1) {
          newItems.first.quantity--;
          developer.log("Yeni eklenen ürün miktarı azaltıldı. Ürün: ${newItems.first.product.proName}, Miktar: ${newItems.first.quantity}");
        } else {
          items.remove(newItems.first);
          developer.log("Yeni eklenen ürün sepetten kaldırıldı. Son ürün olduğu için.");
        }
        return;
      }
      
      // Eğer yeni eklenmiş ürün yoksa, ilk bulunan ürünü azalt
      final item = items.firstWhere((item) => item.product.proID == productId);
      if (item.quantity > 1) {
        item.quantity--;
        developer.log("Ürün miktarı azaltıldı. Ürün: ${item.product.proName}, Miktar: ${item.quantity}, OpID: ${item.opID}");
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
    collectedAmount = 0.0;
    developer.log("Sepet temizlendi.");
  }
  
  @override
  String toString() {
    return 'Basket(items: ${items.length}, totalAmount: $totalAmount, discount: $discount, collectedAmount: $collectedAmount, remainingAmount: $remainingAmount)';
  }
} 