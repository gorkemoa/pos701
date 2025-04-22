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
  final int postID;
  final int proID;
  final int proQty;
  final String proPrice;
  final String proNote;
  final bool isGift;

  OrderProduct({
    required this.postID,
    required this.proID,
    required this.proQty,
    required this.proPrice,
    this.proNote = '',
    this.isGift = false,
  });

  Map<String, dynamic> toJson() {
    return {
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
      orderID: json['orderID'] ?? 0,
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }
} 