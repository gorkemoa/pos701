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
    // Her bir sepet öğesini ayrı ayrı sipariş ürünü olarak oluştur
    final List<OrderProduct> orderProducts = [];

    for (var item in items) {
      // Debug için ürün bilgilerini logla
      debugPrint('🔄 [ORDER_VM] Sipariş ürünü hazırlanıyor: ${item.product.proName}, Miktar: ${item.proQty}, OpID: ${item.opID}, Not: ${item.proNote}, İkram: ${item.isGift}');
      
      // OrderProduct oluştur
      orderProducts.add(OrderProduct(
        opID: item.opID,
        postID: item.product.postID,
        proID: item.product.proID,
        proQty: item.proQty, // Sepetteki miktarı doğrudan kullan
        proPrice: item.product.proPrice,
        proNote: item.proNote, // Sepetteki notu kullan
        isGift: item.isGift, // İkram bilgisini kullan
      ));
    }
    
    // Oluşturulan sipariş ürünlerinin sayısını ve toplam miktarını logla
    final int toplamUrun = orderProducts.length;
    final int toplamMiktar = orderProducts.fold(0, (sum, product) => sum + product.proQty);
    debugPrint('✅ [ORDER_VM] Toplam ${toplamUrun} ürün hazırlandı, toplam miktar: $toplamMiktar');
    
    return orderProducts;
  }
  
  /// Sipariş sunucuya gönderilir
  ///
  /// Başarılı olduğunda true, başarısız olduğunda false döner
  Future<bool> siparisSunucuyaGonder({
    required String userToken,
    required int compID,
    required int tableID,
    required String tableName,
    required List<BasketItem> sepetUrunleri,
    required int orderType,
    required String orderDesc,
    required int orderGuest,
    int custID = 0,
    String custName = '',
    String custPhone = '',
    List<dynamic> custAdrs = const [],
    int kuverQty = 0,
    int isKuver = 0,
    int isWaiter = 0,
  }) async {
    if (sepetUrunleri.isEmpty) {
      _setError('Sepette ürün bulunamadı');
      return false;
    }
    
    try {
      _setStatus(OrderStatus.loading);
      
      // CustomerAddress nesnelerini doğrudan kullan veya dönüştür
      List<CustomerAddress> formattedAddresses = [];
      if (custAdrs.isNotEmpty) {
        for (var address in custAdrs) {
          if (address is CustomerAddress) {
            formattedAddresses.add(address); // Doğrudan CustomerAddress ekle
          }
        }
      }
      
      debugPrint('🔄 [ORDER_VM] Sipariş oluşturuluyor. Kuver: $isKuver, Garsoniye: $isWaiter değerleri ile gönderiliyor');
      
      final orderRequest = OrderRequest(
        userToken: userToken,
        compID: compID,
        tableID: tableID,
        orderType: orderType,
        orderName: tableName,
        orderDesc: orderDesc,
        orderGuest: orderGuest,
        kuverQty: kuverQty,
        isKuver: isKuver,
        isWaiter: isWaiter,
        products: sepettenSiparisUrunleriOlustur(sepetUrunleri),
        custID: custID, // Müşteri ID'sini ekle
        custName: custName, // Müşteri adını ekle
        custPhone: custPhone, // Müşteri telefonunu ekle
        custAdrs: formattedAddresses, // Müşteri adres bilgilerini CustomerAddress listesi olarak ekle
        isCust: custID > 0 || custName.isNotEmpty || custPhone.isNotEmpty, // Müşteri bilgisi varsa true olarak ayarla
      );
      
      debugPrint('📤 [ORDER_VM] Sipariş gönderiliyor. Masa: $tableName, Müşteri ID: $custID, Müşteri adı: $custName, Müşteri tel: $custPhone, Adres sayısı: ${formattedAddresses.length}');
      
      final response = await _orderService.createOrder(orderRequest);
      
      // API 410 hatasını başarılı olarak ele al - sepeti temizleme yan etkisini kaldır
      if (response.success && !response.error) {
        _orderResponse = response.data;
        _setStatus(OrderStatus.success);
        return true;
      } else {
        _setError(response.errorCode ?? 'Sipariş oluşturulamadı');
        return false;
      }
    } catch (e) {
      _setError('Sipariş gönderilirken hata: $e');
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
            debugPrint('🛒 [ORDER_VM] Ürün: ${product.proName}, ID: ${product.proID}, Miktar: ${product.proQty}, RetailPrice: ${product.retailPrice}, Toplam: ${product.price}');
          }
          
          // Tahsil edilen tutarı logla
          debugPrint('💰 [ORDER_VM] Sipariş toplam tutar: ${orderDetail.orderAmount}, Tahsil edilen: ${orderDetail.orderPayAmount}, İndirim: ${orderDetail.orderDiscount}');
          
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
    
    // Kuver ve garsoniye durumlarını logla
    debugPrint('🔵 [ORDER_VM] Sipariş kuver durumu: ${orderDetail.isKuver}, garsoniye durumu: ${orderDetail.isWaiter}');
    
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
    debugPrint('📊 [ORDER_VM] Sipariş detayları sepete aktarılıyor, toplam ${_orderDetail!.products.length} ürün...');
    
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
      
      // Fiyat bilgilerini kontrol et ve düzgün tara
      String fiyatStr = product.price.toString().trim();
      debugPrint('💲 [ORDER_VM] Ürün fiyatı: ${product.proName} - ${fiyatStr}');
      
      // OrderDetailProduct'tan Product nesnesine dönüştür
      final Product urun = Product(
        proID: product.proID,
        postID: product.postID,
        proName: product.proName,
        proUnit: product.proUnit,
        proStock: "0", // Stok bilgisi olmadığı için 0 olarak gönderildi
        proPrice: product.retailPrice.toString(), // product.price yerine product.retailPrice (birim fiyat) kullanıldı
        proNote: product.proNote ?? '', // API'den gelen notu ekle
      );
      
      // Kalan ödenmemiş miktar hesaplanır (proQty - paidQty)
      final int kalanMiktar = product.proQty - product.paidQty;
      
      // Birden fazla aynı ürün varsa, bunları tek bir sepet öğesi olarak ekle
      if (kalanMiktar > 0) {
        debugPrint('✅ [ORDER_VM] Ürün sepete aktarılıyor: ${urun.proName}, Toplam miktar: $kalanMiktar, OpID: ${product.opID}, Fiyat: ${urun.proPrice}, Not: ${urun.proNote}, İkram: ${product.isGift}');
        
        // Tek bir sepet öğesi oluştur
        final BasketItem sepetItem = BasketItem(
          product: urun,
          proQty: kalanMiktar, // Toplam miktar
          opID: product.opID, // OpID'ler aynı kalır - API hangi sipariş kalemi olduğunu bilmeli
          proNote: urun.proNote, // Ürün notu
          isGift: product.isGift, // İkram bilgisi
        );
        
        sepetItems.add(sepetItem);
      }
    }
    
    // Her bir sepet öğesi için detaylı bilgi göster
    double toplamFiyat = 0;
    for (var item in sepetItems) {
      double itemTotalPrice = item.isGift ? 0.0 : (item.birimFiyat * item.proQty);
      toplamFiyat += itemTotalPrice;
      
      debugPrint('🔢 [ORDER_VM] Sepet öğesi: ${item.product.proName}, Birim Fiyat: ${item.birimFiyat}, Miktar: ${item.proQty}, Toplam: $itemTotalPrice, Not: ${item.proNote}, İkram: ${item.isGift}');
    }
    
    debugPrint('🛒 [ORDER_VM] Sepete ${sepetItems.length} ürün çeşidi eklendi.');
    debugPrint('💰 [ORDER_VM] Toplam hesaplanan tutar: $toplamFiyat');
    
    return sepetItems;
  }
  
  /// Sipariş güncelleme işlemi
  Future<bool> siparisGuncelle({
    required String userToken,
    required int compID,
    required int orderID,
    required List<BasketItem> sepetUrunleri,
    String orderDesc = '',
    int orderGuest = 1,
    int kuverQty = 0,
    int custID = 0,
    String custName = '',
    String custPhone = '',
    List<dynamic> custAdrs = const [],
    required int isKuver,
    required int isWaiter,
  }) async {
    if (sepetUrunleri.isEmpty) {
      _setError('Sepette ürün bulunamadı');
      return false;
    }
    
    try {
      _setStatus(OrderStatus.loading);
      debugPrint('🔄 [ORDER_VM] Sipariş güncelleniyor. OrderID: $orderID, Müşteri ID: $custID, Müşteri adı: $custName, Müşteri tel: $custPhone, Adres sayısı: ${custAdrs.length}');
      debugPrint('🔄 [ORDER_VM] Kuver: $isKuver, Garsoniye: $isWaiter değerleri ile güncelleniyor');
      
      // CustomerAddress nesnelerini dönüştür
      List<dynamic> formattedAddresses = [];
      if (custAdrs.isNotEmpty) {
        for (var address in custAdrs) {
          if (address is CustomerAddress) {
            formattedAddresses.add(address.toJson()); // CustomerAddress verilerini Map olarak ekle
          }
        }
      }
      
      // Sipariş güncelleme isteği oluştur
      final orderUpdateRequest = OrderUpdateRequest(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        orderGuest: orderGuest,
        kuverQty: kuverQty,
        orderDesc: orderDesc,
        products: sepettenSiparisUrunleriOlustur(sepetUrunleri),
        custID: custID, // Müşteri ID'si ekle
        custName: custName, // Müşteri adını ekle
        custPhone: custPhone, // Müşteri telefonunu ekle
        custAdrs: formattedAddresses, // Dönüştürülmüş adresleri ekle
        isCust: custID > 0 || custName.isNotEmpty || custPhone.isNotEmpty ? 1 : 0, // Müşteri bilgisi varsa 1 olarak ayarla
        isKuver: isKuver, // Kuver durumu
        isWaiter: isWaiter, // Garsoniye durumu
      );
      
      // Siparişi güncelle
      final response = await _orderService.updateOrder(orderUpdateRequest);
      
      // API 410 hatasını başarılı olarak ele al - sepeti temizleme yan etkisini kaldır
      if (response.success && !response.error) {
        _orderResponse = response.data;
        _setStatus(OrderStatus.success);
        return true;
      } else {
        _setError(response.errorCode ?? 'Sipariş güncellenemedi');
        return false;
      }
    } catch (e) {
      _setError('Sipariş güncellenirken hata: $e');
      return false;
    }
  }
} 