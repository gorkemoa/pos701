import 'package:flutter/foundation.dart';

class CustomerAddress {
  final String adrTitle;
  final String adrAdress;
  final String adrNote;
  final bool isDefault;

  CustomerAddress({
    required this.adrTitle,
    required this.adrAdress,
    required this.adrNote,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() {
    return {
      'adrTitle': adrTitle,
      'adrAdress': adrAdress,
      'adrNote': adrNote,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      adrTitle: json['adrTitle'] ?? '',
      adrAdress: json['adrAdress'] ?? '',
      adrNote: json['adrNote'] ?? '',
      isDefault: json['isDefault'] == 1,
    );
  }
}

class OrderProduct {
  final int opID;
  final int postID;
  final int proID;
  final int proQty;
  final String proPrice;
  final String proNote;
  final bool isGift;
  final int isRemove;

  OrderProduct({
    required this.opID,
    required this.postID,
    required this.proID,
    required this.proQty,
    required this.proPrice,
    this.proNote = '',
    this.isGift = false,
    this.isRemove = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'opID': opID,
      'postID': postID,
      'proID': proID,
      'proQty': proQty,
      'proPrice': proPrice,
      'proNote': proNote,
      'isGift': isGift ? 1 : 0,
      'isRemove': isRemove,
    };
  }

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      opID: json['opID'] ?? 0,
      postID: json['postID'] ?? 0,
      proID: json['proID'] ?? 0,
      proQty: json['proQty'] ?? 0,
      proPrice: json['proPrice'] ?? '0',
      proNote: json['proNote'] ?? '',
      isGift: json['isGift'] == 1,
      isRemove: json['isRemove'] ?? 0,
    );
  }
}

class OrderRequest {
  final String userToken;
  final int compID;
  final int tableID;
  final int custID;
  final int orderType;
  final String orderName;
  final String orderDesc;
  final int orderGuest;
  final int custAdrID;
  final int kuverQty;
  final int isKuver;
  final int isWaiter;
  final bool isCust;
  final String custName;
  final String custPhone;
  final List<CustomerAddress> custAdrs;
  final List<OrderProduct> products;
  final int orderPayType;

  OrderRequest({
    required this.userToken,
    required this.compID,
    required this.tableID,
    this.custID = 0,
    required this.orderType,
    this.orderName = '',
    this.orderDesc = '',
    required this.orderGuest,
    required this.custAdrID,
    required this.kuverQty,
    this.isKuver = 0,
    this.isWaiter = 0,
    this.isCust = false,
    this.custName = '',
    this.custPhone = '',
    this.custAdrs = const [],
    required this.products,
    this.orderPayType = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'compID': compID,
      'tableID': tableID,
      'custID': custID,
      'orderType': orderType,
      'orderDesc': orderDesc,
      'orderGuest': orderGuest,
      'custAdrID': custAdrID,
      'kuverQty': kuverQty,
      'isKuver': isKuver,
      'isWaiter': isWaiter,
      'isCust': isCust ? 1 : 0,
      'custName': custName,
      'custPhone': custPhone,
      'custAdrs': custAdrs.map((address) => address.toJson()).toList(),
      'products': products.map((product) => product.toJson()).toList(),
      'orderPayType': orderPayType,
    };
  }
}

class OrderResponse {
  final int orderID;
  final String message;
  final bool success;

  OrderResponse({
    required this.orderID,
    required this.message,
    required this.success,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      orderID: json['orderID'],
      message: json['message'],
      success: json['success'],
    );
  }
}

class OrderDetailRequest {
  final String userToken;
  final int compID;
  final int orderID;

  OrderDetailRequest({
    required this.userToken,
    required this.compID,
    required this.orderID,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'compID': compID,
      'orderID': orderID,
    };
  }
}

class OrderDetail {
  final int orderID;
  final int tableID;
  final int custID;
  final String orderCode;
  final String orderName;
  final double orderAmount;
  final double orderPayAmount;
  final double orderDiscount;
  final String orderDesc;
  final int orderGuest;
  final String orderStatus;
  final String orderDate;
  final bool isActive;
  final bool isCanceled;
  final Map<String, dynamic> customer;
  final List<OrderDetailProduct> products;
  final int isKuver;
  final int isWaiter;

  OrderDetail({
    required this.orderID,
    required this.tableID,
    required this.custID,
    required this.orderCode,
    required this.orderName,
    required this.orderAmount,
    this.orderPayAmount = 0.0,
    required this.orderDiscount,
    required this.orderDesc,
    required this.orderGuest,
    required this.orderStatus,
    required this.orderDate,
    required this.isActive,
    required this.isCanceled,
    required this.customer,
    required this.products,
    this.isKuver = 0,
    this.isWaiter = 0,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    // Products alanı için güvenli dönüşüm ve hata kontrolü
    List<OrderDetailProduct> productList = [];
    
    try {
      final productsData = json['products'];
      if (productsData != null) {
        if (productsData is List) {
          productList = List<OrderDetailProduct>.from(
            productsData.map((product) => OrderDetailProduct.fromJson(product))
          );
        } else {
          debugPrint('⚠️ [OrderDetail] products alanı liste tipinde değil: ${productsData.runtimeType}');
        }
      } else {
        debugPrint('⚠️ [OrderDetail] products alanı null');
      }
    } catch (e) {
      debugPrint('🔴 [OrderDetail] Products dönüştürme hatası: $e');
    }
    
    // Customer alanı için güvenli dönüşüm
    Map<String, dynamic> customerData = {};
    try {
      final customerField = json['customer'];
      if (customerField != null) {
        if (customerField is Map) {
          customerData = Map<String, dynamic>.from(customerField);
        } else if (customerField is List) {
          debugPrint('⚠️ [OrderDetail] customer alanı bir liste, boş Map kullanılacak');
          // List yerine boş Map kullan
        } else {
          debugPrint('⚠️ [OrderDetail] customer alanı beklenmeyen tipte: ${customerField.runtimeType}');
        }
      }
    } catch (e) {
      debugPrint('🔴 [OrderDetail] Customer alanı dönüştürme hatası: $e');
    }
    
    // isKuver ve isWaiter değerlerini string'den int'e dönüştür
    int isKuver = 0;
    int isWaiter = 0;
    
    try {
      if (json.containsKey('isKuver')) {
        if (json['isKuver'] is String) {
          isKuver = int.tryParse(json['isKuver']) ?? 0;
          debugPrint('🔄 [OrderDetail] isKuver string değeri int\'e dönüştürüldü: ${json['isKuver']} -> $isKuver');
        } else if (json['isKuver'] is int) {
          isKuver = json['isKuver'];
        }
      }
      
      if (json.containsKey('isWaiter')) {
        if (json['isWaiter'] is String) {
          isWaiter = int.tryParse(json['isWaiter']) ?? 0;
          debugPrint('🔄 [OrderDetail] isWaiter string değeri int\'e dönüştürüldü: ${json['isWaiter']} -> $isWaiter');
        } else if (json['isWaiter'] is int) {
          isWaiter = json['isWaiter'];
        }
      }
      
      debugPrint('🔵 [OrderDetail] isKuver: $isKuver, isWaiter: $isWaiter değerleri parse edildi');
    } catch (e) {
      debugPrint('⚠️ [OrderDetail] isKuver/isWaiter dönüştürme hatası: $e');
    }
    
    return OrderDetail(
      orderID: json['orderID'] ?? 0,
      tableID: json['tableID'] ?? 0,
      custID: json['custID'] ?? 0,
      orderCode: json['orderCode'] ?? '',
      orderName: json['orderName'] ?? '',
      orderAmount: (json['orderAmount'] ?? 0).toDouble(),
      orderPayAmount: (json['orderPayAmount'] ?? 0).toDouble(),
      orderDiscount: (json['orderDiscount'] ?? 0).toDouble(),
      orderDesc: json['orderDesc'] ?? '',
      orderGuest: json['orderGuest'] ?? 1,
      orderStatus: json['orderStatus'] ?? '',
      orderDate: json['orderDate'] ?? '',
      isActive: json['isActive'] ?? false,
      isCanceled: json['isCanceled'] ?? false,
      customer: customerData,
      products: productList,
      isKuver: isKuver,
      isWaiter: isWaiter,
    );
  }
}

class OrderDetailProduct {
  final int opID;
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
  final String? proNote;

  OrderDetailProduct({
    this.opID = 0,
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
    this.proNote,
  });

  factory OrderDetailProduct.fromJson(Map<String, dynamic> json) {
    return OrderDetailProduct(
      opID: json['opID'] ?? 0,
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
      proNote: json['proNote'],
    );
  }
}

// Sipariş Güncelleme İstek Modeli
class OrderUpdateRequest {
  final String userToken;
  final int compID;
  final int orderID;
  final int orderGuest;
  final int kuverQty;
  final String orderDesc;
  final int custID;
  final String custName;
  final String custPhone;
  final List<dynamic> custAdrs;
  final int isCust;
  final List<OrderProduct> products;
  final int isKuver;
  final int isWaiter;
  final int orderPayType;
  final int isRemove;

  OrderUpdateRequest({
    required this.userToken,
    required this.compID,
    required this.orderID,
    required this.orderGuest,
    required this.kuverQty,
    this.orderDesc = '',
    this.custID = 0,
    this.custName = '',
    this.custPhone = '',
    this.custAdrs = const [],
    this.isCust = 0,
    required this.products,
    required this.isKuver,
    required this.isWaiter,
    this.orderPayType = 0,
    this.isRemove = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'compID': compID,
      'orderID': orderID,
      'orderGuest': orderGuest,
      'kuverQty': kuverQty,
      'orderDesc': orderDesc,
      'custID': custID,
      'custName': custName,
      'custPhone': custPhone,
      'custAdrs': custAdrs,
      'isCust': isCust,
      'products': products.map((product) => product.toJson()).toList(),
      'isKuver': isKuver,
      'isWaiter': isWaiter,
      'orderPayType': orderPayType,
      'isRemove': isRemove,
    };
  }
}

class OrderModel {
  final List<Order> orders;

  OrderModel({
    required this.orders,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orders: List<Order>.from(
        json['data']['orders'].map((order) => Order.fromJson(order)),
      ),
    );
  }
}

class Order {
  final int orderID;
  final String orderCode;
  final String orderName;
  final String orderUserName;
  final String orderStatusID;
  final String orderStatus;
  final String orderDate;
  final int orderTime;
  final String orderPayment;
  final String orderAmount;
  final String payAmount;
  final String remainingAmount;
  final List<Payment> payments;

  Order({
    required this.orderID,
    required this.orderCode,
    required this.orderName,
    required this.orderUserName,
    required this.orderStatusID,
    required this.orderStatus,
    required this.orderDate,
    required this.orderTime,
    required this.orderPayment,
    required this.orderAmount,
    required this.payAmount,
    required this.remainingAmount,
    required this.payments,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderID: json['orderID'],
      orderCode: json['orderCode'],
      orderName: json['orderName'],
      orderUserName: json['orderUserName'],
      orderStatusID: json['orderStatusID'],
      orderStatus: json['orderStatus'],
      orderDate: json['orderDate'],
      orderTime: json['orderTime'],
      orderPayment: json['orderPayment'] ?? '',
      orderAmount: json['orderAmount'],
      payAmount: json['payAmount'],
      remainingAmount: json['remainingAmount'],
      payments: json['payments'] != null
          ? List<Payment>.from(
              json['payments'].map((payment) => Payment.fromJson(payment)))
          : [],
    );
  }
}

class Payment {
  final String payType;

  Payment({
    required this.payType,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      payType: json['payType'],
    );
  }
}

/// Ürün ekleme API çağrısından dönen yanıt
class AddProductResponse {
  final int opID; // Sipariş ürün ID
  final String message;
  final bool success;
  
  AddProductResponse({
    required this.opID,
    required this.message,
    required this.success,
  });
  
  factory AddProductResponse.fromJson(Map<String, dynamic> json) {
    return AddProductResponse(
      opID: json['opID'] ?? 0,
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }
} 