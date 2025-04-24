import 'package:flutter/foundation.dart';
import 'package:pos701/models/order_model.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/services/order_service.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/models/product_model.dart';

enum OrderStatus {
  idle,
  loading,
  success,
  error,
}

class OrderViewModel extends ChangeNotifier {
  final OrderService _orderService;
  OrderStatus _status = OrderStatus.idle;
  String? _errorMessage;
  OrderResponse? _orderResponse;
  
  OrderViewModel({OrderService? orderService}) 
      : _orderService = orderService ?? OrderService();
  
  OrderStatus get status => _status;
  String? get errorMessage => _errorMessage;
  OrderResponse? get orderResponse => _orderResponse;
  
  void _setStatus(OrderStatus status) {
    _status = status;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    _setStatus(OrderStatus.error);
  }
  
  void resetState() {
    _status = OrderStatus.idle;
    _errorMessage = null;
    _orderResponse = null;
    notifyListeners();
  }
  
  /// Sepeti sipariş modeline dönüştürür
  List<OrderProduct> sepettenSiparisUrunleriOlustur(List<BasketItem> items) {
    // Burada aynı ürünleri gruplarız (proID ve postID'ye göre grupla)
    final Map<String, OrderProduct> productMap = {};

    for (var item in items) {
      // Ürün kimliğini oluştur (proID-postID)
      final key = '${item.product.proID}-${item.product.postID}';
      
      if (productMap.containsKey(key)) {
        // Aynı ürünse miktarını arttır
        final existingProduct = productMap[key]!;
        productMap[key] = OrderProduct(
          opID: item.opID, // opID korunur
          postID: item.product.postID,
          proID: item.product.proID,
          proQty: existingProduct.proQty + item.quantity,
          proPrice: item.product.proPrice,
        );
      } else {
        // Yeni bir ürünse yeni ekleme yap
        productMap[key] = OrderProduct(
          opID: item.opID,
          postID: item.product.postID,
          proID: item.product.proID,
          proQty: item.quantity,
          proPrice: item.product.proPrice,
        );
      }
    }
    
    return productMap.values.toList();
  }
  
  /// Yeni bir sipariş oluşturur
  Future<bool> siparisSunucuyaGonder({
    required String userToken,
    required int compID,
    required int tableID,
    required String tableName,
    required List<BasketItem> sepetUrunleri,
    int orderType = 1, // 1- Masa Siparişi varsayılan
    int orderGuest = 1,
    int kuverQty = 1,
    bool isKuver = false,
    bool isWaiter = false,
  }) async {
    if (sepetUrunleri.isEmpty) {
      _setError('Sepette ürün bulunamadı');
      return false;
    }
    
    try {
      _setStatus(OrderStatus.loading);
      
      final orderRequest = OrderRequest(
        userToken: userToken,
        compID: compID,
        tableID: tableID,
        orderType: orderType,
        orderName: tableName,
        orderGuest: orderGuest,
        kuverQty: kuverQty,
        isKuver: isKuver,
        isWaiter: isWaiter,
        products: sepettenSiparisUrunleriOlustur(sepetUrunleri),
      );
      
      final response = await _orderService.createOrder(orderRequest);
      
      if (response.success && !response.error) {
        _orderResponse = response.data;
        _setStatus(OrderStatus.success);
        return true;
      } else {
        _setError(response.errorCode ?? 'Bilinmeyen bir hata oluştu');
        return false;
      }
    } catch (e) {
      _setError('Sipariş gönderilirken hata oluştu: ${e.toString()}');
      return false;
    }
  }
  
  /// Sipariş detaylarını getir
  Future<bool> getSiparisDetayi({
    required String userToken,
    required int compID,
    required int orderID,
  }) async {
    try {
      _setStatus(OrderStatus.loading);
      debugPrint('🔄 [ORDER_VM] Sipariş detayları getiriliyor. OrderID: $orderID');
      
      final orderDetailRequest = OrderDetailRequest(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
      );
      
      final response = await _orderService.getOrderDetail(orderDetailRequest);
      
      debugPrint('🔄 [ORDER_VM] API yanıtı - Success: ${response.success}, Error: ${response.error}');
      
      if (response.success && !response.error) {
        final orderDetail = response.data;
        if (orderDetail != null) {
          debugPrint('✅ [ORDER_VM] Sipariş detayları alındı. Ürün sayısı: ${orderDetail.products.length}');
          // Ürünlerin detaylarını logla
          for (var product in orderDetail.products) {
            debugPrint('🛒 [ORDER_VM] Ürün: ${product.proName}, ID: ${product.proID}, Miktar: ${product.proQty}, Fiyat: ${product.price}');
          }
          
          // Sepeti temizle ve sipariş ürünlerini sepete ekle
          _siparisDetayiniSepeteAktar(orderDetail);
          _setStatus(OrderStatus.success);
          return true;
        } else {
          debugPrint('⛔️ [ORDER_VM] Sipariş detayları alınamadı: Veri yok');
          _setError('Sipariş detayları alınamadı: Veri yok');
          return false;
        }
      } else {
        debugPrint('⛔️ [ORDER_VM] Sipariş detayları alınamadı: ${response.errorCode}');
        _setError(response.errorCode ?? 'Bilinmeyen bir hata oluştu');
        return false;
      }
    } catch (e) {
      debugPrint('🔴 [ORDER_VM] Sipariş detayları alınırken hata: $e');
      _setError('Sipariş detayları alınırken hata oluştu: ${e.toString()}');
      return false;
    }
  }
  
  /// Sipariş detayını sepet modeline aktar
  void _siparisDetayiniSepeteAktar(OrderDetail orderDetail) {
    debugPrint('🔄 [ORDER_VM] Sipariş detayları sepete aktarılıyor');
    // ViewModel'e basketViewModel enjekte edilmediği için buradan doğrudan sepeti güncelleyemiyoruz
    // Bu fonksiyon basket_view.dart içerisinden kullanılacak
    _orderDetail = orderDetail;
    notifyListeners();
  }
  
  OrderDetail? _orderDetail;
  OrderDetail? get orderDetail => _orderDetail;
  
  /// Sipariş ürünlerini ürün modeline dönüştür
  List<BasketItem> siparisUrunleriniSepeteAktar() {
    if (_orderDetail == null) {
      debugPrint('⛔️ [ORDER_VM] Sipariş detayları bulunamadı, sepete aktarılamıyor');
      return [];
    }
    
    final List<BasketItem> sepetItems = [];
    
    for (var product in _orderDetail!.products) {
      // İptal edilmiş veya ödenmiş ürünleri sepete eklememek için kontrol
      if (product.isCanceled) {
        debugPrint('ℹ️ [ORDER_VM] İptal edilmiş ürün sepete eklenmedi: ${product.proName}');
        continue;
      }
      
      // Ödenmiş ürünleri kontrol et (isPaid flag'i veya paidQty değerine göre)
      if (product.isPaid == true || product.paidQty >= product.proQty) {
        debugPrint('💰 [ORDER_VM] Ödenmiş ürün sepete eklenmedi: ${product.proName}, opID: ${product.opID}');
        continue;
      }
      
      // OrderDetailProduct'tan Product nesnesine dönüştür
      final Product urun = Product(
        proID: product.proID,
        postID: product.postID,
        proName: product.proName,
        proUnit: product.proUnit,
        proStock: "0", // Stok bilgisi olmadığı için 0 olarak gönderildi
        proPrice: product.price.toString(),
      );
      
      // Kalan ödenmemiş miktar hesaplanır (proQty - paidQty)
      final int kalanMiktar = product.proQty - product.paidQty;
      
      // Önemli: Aynı üründen birden fazla varsa, her biri için ayrı sepet öğeleri oluştur
      // Bu, parçalı ödeme için gereklidir - kullanıcı her bir ürünü ayrı ayrı seçebilmelidir
      for (int i = 0; i < kalanMiktar; i++) {
        debugPrint('✅ [ORDER_VM] Ürün sepete aktarılıyor: ${urun.proName}, Birim: ${i+1}/$kalanMiktar, OpID: ${product.opID}');
        
        // Her birim için ayrı bir sepet öğesi oluştur
        final BasketItem sepetItem = BasketItem(
          product: urun,
          quantity: 1, // Her öğe için miktar 1 olmalı
          opID: product.opID, // OpID'ler aynı kalır - API hangi sipariş kalemi olduğunu bilmeli
        );
        
        sepetItems.add(sepetItem);
      }
    }
    
    debugPrint('🛒 [ORDER_VM] Sepete aktarılan toplam ürün sayısı: ${sepetItems.length}');
    return sepetItems;
  }
  
  /// Sipariş güncelleme işlemi
  Future<bool> siparisGuncelle({
    required String userToken,
    required int compID,
    required int orderID,
    required List<BasketItem> sepetUrunleri,
    int orderGuest = 1,
    int kuverQty = 1,
    bool isKuver = false,
    bool isWaiter = false,
  }) async {
    if (sepetUrunleri.isEmpty) {
      _setError('Sepette ürün bulunamadı');
      return false;
    }
    
    try {
      _setStatus(OrderStatus.loading);
      
      final orderUpdateRequest = OrderUpdateRequest(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        orderGuest: orderGuest,
        kuverQty: kuverQty,
        isKuver: isKuver ? 1 : 0,
        isWaiter: isWaiter ? 1 : 0,
        products: sepettenSiparisUrunleriOlustur(sepetUrunleri),
      );
      
      debugPrint('🔄 [ORDER_VM] Sipariş güncelleniyor. OrderID: $orderID');
      final response = await _orderService.updateOrder(orderUpdateRequest);
      
      if (response.success && !response.error) {
        debugPrint('✅ [ORDER_VM] Sipariş başarıyla güncellendi. OrderID: $orderID');
        _orderResponse = response.data;
        _setStatus(OrderStatus.success);
        return true;
      } else {
        debugPrint('⛔️ [ORDER_VM] Sipariş güncellenemedi: ${response.errorCode}');
        _setError(response.errorCode ?? 'Bilinmeyen bir hata oluştu');
        return false;
      }
    } catch (e) {
      debugPrint('🔴 [ORDER_VM] Sipariş güncellenirken hata: $e');
      _setError('Sipariş güncellenirken hata oluştu: ${e.toString()}');
      return false;
    }
  }
} 