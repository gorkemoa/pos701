import 'package:flutter/foundation.dart';
import 'package:pos701/models/order_model.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/services/order_service.dart';
import 'package:pos701/models/api_response_model.dart';

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
    return items.map((item) => OrderProduct(
      postID: item.product.postID,
      proID: item.product.proID,
      proQty: item.quantity,
      proPrice: item.product.proPrice,
    )).toList();
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
} 