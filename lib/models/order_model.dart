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

  OrderProduct({
    required this.opID,
    required this.postID,
    required this.proID,
    required this.proQty,
    required this.proPrice,
    this.proNote = '',
    this.isGift = false,
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
  final int kuverQty;
  final bool isKuver;
  final bool isWaiter;
  final bool isCust;
  final String custName;
  final String custPhone;
  final List<CustomerAddress> custAdrs;
  final List<OrderProduct> products;

  OrderRequest({
    required this.userToken,
    required this.compID,
    required this.tableID,
    this.custID = 0,
    required this.orderType,
    this.orderName = '',
    this.orderDesc = '',
    required this.orderGuest,
    required this.kuverQty,
    this.isKuver = false,
    this.isWaiter = false,
    this.isCust = false,
    this.custName = '',
    this.custPhone = '',
    this.custAdrs = const [],
    required this.products,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'compID': compID,
      'tableID': tableID,
      'custID': custID,
      'orderType': orderType,
      'orderName': orderName,
      'orderDesc': orderDesc,
      'orderGuest': orderGuest,
      'kuverQty': kuverQty,
      'isKuver': isKuver ? 1 : 0,
      'isWaiter': isWaiter ? 1 : 0,
      'isCust': isCust ? 1 : 0,
      'custName': custName,
      'custPhone': custPhone,
      'custAdrs': custAdrs.map((address) => address.toJson()).toList(),
      'products': products.map((product) => product.toJson()).toList(),
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
  final double orderDiscount;
  final String orderDesc;
  final int orderGuest;
  final String orderStatus;
  final String orderDate;
  final bool isActive;
  final bool isCanceled;
  final List<dynamic> customer;
  final List<OrderDetailProduct> products;

  OrderDetail({
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

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
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
      products: List<OrderDetailProduct>.from(
        (json['products'] ?? []).map((product) => OrderDetailProduct.fromJson(product))
      ),
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
  });

  factory OrderDetailProduct.fromJson(Map<String, dynamic> json) {
    return OrderDetailProduct(
      opID: json['opID'],
      postID: json['postID'],
      proID: json['proID'],
      proName: json['proName'],
      proUnit: json['proUnit'],
      proQty: json['proQty'],
      paidQty: json['paidQty'],
      currentQty: json['currentQty'],
      retailPrice: (json['retailPrice'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      isCanceled: json['isCanceled'],
      isGift: json['isGift'],
      isPaid: json['isPaid'],
    );
  }
}

// Sipariş Güncelleme İstek Modeli
class OrderUpdateRequest {
  final String userToken;
  final int compID;
  final int orderID;
  final int custID;
  final String orderName;
  final String orderDesc;
  final int orderGuest;
  final int kuverQty;
  final int isKuver;
  final int isWaiter;
  final int isCust;
  final String custName;
  final String custPhone;
  final List<dynamic> custAdrs;
  final List<OrderProduct> products;

  OrderUpdateRequest({
    required this.userToken,
    required this.compID,
    required this.orderID,
    this.custID = 0,
    this.orderName = '',
    this.orderDesc = '',
    this.orderGuest = 1,
    this.kuverQty = 1,
    this.isKuver = 0,
    this.isWaiter = 0,
    this.isCust = 0,
    this.custName = '',
    this.custPhone = '',
    this.custAdrs = const [],
    required this.products,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'compID': compID,
      'orderID': orderID,
      'custID': custID,
      'orderName': orderName,
      'orderDesc': orderDesc,
      'orderGuest': orderGuest,
      'kuverQty': kuverQty,
      'isKuver': isKuver,
      'isWaiter': isWaiter,
      'isCust': isCust,
      'custName': custName,
      'custPhone': custPhone,
      'custAdrs': custAdrs,
      'products': products.map((product) => product.toJson()).toList(),
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