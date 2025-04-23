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

  void addProduct(Product product) {
    developer.log("Sepete ürün ekleniyor: ${product.proName}, ID: ${product.proID}, Fiyat: ${product.proPrice}");
    
    final existingItemIndex = items.indexWhere((item) => item.product.proID == product.proID);
    
    if (existingItemIndex != -1) {
      items[existingItemIndex].quantity++;
      developer.log("Mevcut ürün miktarı artırıldı: ${items[existingItemIndex].quantity}");
    } else {
      items.add(BasketItem(product: product, quantity: 1));
      developer.log("Yeni ürün sepete eklendi. Sepetteki ürün sayısı: ${items.length}");
    }
  }

  void removeProduct(int productId) {
    developer.log("Sepetten ürün kaldırılıyor. Ürün ID: $productId");
    items.removeWhere((item) => item.product.proID == productId);
    developer.log("Sepetteki ürün sayısı: ${items.length}");
  }

  void incrementQuantity(int productId) {
    try {
      final item = items.firstWhere((item) => item.product.proID == productId);
      item.quantity++;
      developer.log("Ürün miktarı artırıldı. Ürün: ${item.product.proName}, Miktar: ${item.quantity}");
    } catch (e) {
      developer.log("Ürün miktarını artırırken hata: $e", error: e);
    }
  }

  void decrementQuantity(int productId) {
    try {
      final item = items.firstWhere((item) => item.product.proID == productId);
      if (item.quantity > 1) {
        item.quantity--;
        developer.log("Ürün miktarı azaltıldı. Ürün: ${item.product.proName}, Miktar: ${item.quantity}");
      } else {
        removeProduct(productId);
        developer.log("Ürün sepetten kaldırıldı. Son ürün olduğu için.");
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