import 'package:flutter/foundation.dart';

// Sipariş detayı yanıt modeli
class OrderDetailResponse {
  final int orderID;
  final int tableID;
  final int custID;
  final String orderCode;
  final String orderName;
  final double orderAmount;
  final double orderDiscount;
  final String orderDesc;
  final int orderGuest;
  final String orderStatus;
  final String orderDate;
  final bool isActive;
  final bool isCanceled;
  final List<dynamic> customer;
  final List<OrderProductDetail> products;

  OrderDetailResponse({
    required this.orderID,
    required this.tableID,
    required this.custID,
    required this.orderCode,
    required this.orderName,
    required this.orderAmount,
    required this.orderDiscount,
    required this.orderDesc,
    required this.orderGuest,
    required this.orderStatus,
    required this.orderDate,
    required this.isActive,
    required this.isCanceled,
    required this.customer,
    required this.products,
  });

  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) {
    try {
      // products alanı kontrol edilir - eğer null veya liste değilse boş liste olarak işlenir
      final productsData = json['products'];
      List<OrderProductDetail> productsList = [];
      
      if (productsData != null) {
        if (productsData is List) {
          productsList = List<OrderProductDetail>.from(
            productsData.map((item) => OrderProductDetail.fromJson(item))
          );
        } else {
          debugPrint('⚠️ [OrderDetail] products alanı liste formatında değil, boş liste kullanılıyor');
        }
      } else {
        debugPrint('⚠️ [OrderDetail] products alanı null, boş liste kullanılıyor');
      }
      
      return OrderDetailResponse(
        orderID: json['orderID'],
        tableID: json['tableID'],
        custID: json['custID'],
        orderCode: json['orderCode'],
        orderName: json['orderName'],
        orderAmount: (json['orderAmount'] ?? 0).toDouble(),
        orderDiscount: (json['orderDiscount'] ?? 0).toDouble(),
        orderDesc: json['orderDesc'],
        orderGuest: json['orderGuest'],
        orderStatus: json['orderStatus'],
        orderDate: json['orderDate'],
        isActive: json['isActive'],
        isCanceled: json['isCanceled'],
        customer: json['customer'],
        products: productsList,
      );
    } catch (e) {
      debugPrint('🔴 [OrderDetail] JSON ayrıştırma hatası: $e');
      rethrow; // Hata ayıklama için hatayı yeniden fırlat
    }
  }
}

class OrderProductDetail {
  final int postID;
  final int proID;
  final String proName;
  final String proUnit;
  final int proQty;
  final int paidQty;
  final int currentQty;
  final double retailPrice;
  final double price;
  final bool isCanceled;
  final bool isGift;
  final bool isPaid;

  OrderProductDetail({
    required this.postID,
    required this.proID,
    required this.proName,
    required this.proUnit,
    required this.proQty,
    required this.paidQty,
    required this.currentQty,
    required this.retailPrice,
    required this.price,
    required this.isCanceled,
    required this.isGift,
    required this.isPaid,
  });

  factory OrderProductDetail.fromJson(Map<String, dynamic> json) {
    return OrderProductDetail(
      postID: json['postID'] ?? 0,
      proID: json['proID'] ?? 0,
      proName: json['proName'] ?? '',
      proUnit: json['proUnit'] ?? '',
      proQty: json['proQty'] ?? 0,
      paidQty: json['paidQty'] ?? 0,
      currentQty: json['currentQty'] ?? 0,
      retailPrice: (json['retailPrice'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      isCanceled: json['isCanceled'] ?? false,
      isGift: json['isGift'] ?? false,
      isPaid: json['isPaid'] ?? false,
    );
  }
}
