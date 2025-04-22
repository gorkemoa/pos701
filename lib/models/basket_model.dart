import 'package:pos701/models/product_model.dart';
import 'dart:developer' as developer;

class BasketItem {
  final Product product;
  int quantity;
  
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
      return price * quantity;
    } catch (e) {
      developer.log("Fiyat hesaplama hatası: ${e.toString()}", error: e);
      return 0.0;
    }
  }

  BasketItem({
    required this.product,
    this.quantity = 1,
  });
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
    return total;
  }

  double get remainingAmount => totalAmount - discount - collectedAmount;

  void addProduct(Product product) {
    final existingItemIndex = items.indexWhere((item) => item.product.proID == product.proID);
    
    if (existingItemIndex != -1) {
      items[existingItemIndex].quantity++;
    } else {
      items.add(BasketItem(product: product));
    }
  }

  void removeProduct(int productId) {
    items.removeWhere((item) => item.product.proID == productId);
  }

  void incrementQuantity(int productId) {
    final item = items.firstWhere((item) => item.product.proID == productId);
    item.quantity++;
  }

  void decrementQuantity(int productId) {
    final item = items.firstWhere((item) => item.product.proID == productId);
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      removeProduct(productId);
    }
  }

  void clear() {
    items.clear();
    discount = 0.0;
    collectedAmount = 0.0;
  }
} 