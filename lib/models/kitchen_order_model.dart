class KitchenProduct {
  final int opID;
  final String proName;
  final String proUnit;
  final int proQty;
  final String proTime;

  KitchenProduct({
    required this.opID,
    required this.proName,
    required this.proUnit,
    required this.proQty,
    required this.proTime,
  });

  factory KitchenProduct.fromJson(Map<String, dynamic> json) {
    return KitchenProduct(
      opID: json['opID'] ?? 0,
      proName: json['proName'] ?? '',
      proUnit: json['proUnit'] ?? '',
      proQty: json['proQty'] ?? 0,
      proTime: json['proTime'] ?? '',
    );
  }
}

class KitchenOrder {
  final int orderID;
  final String userName;
  final String tableName;
  final String orderInfo;
  final List<KitchenProduct> products;

  KitchenOrder({
    required this.orderID,
    required this.userName,
    required this.tableName,
    required this.orderInfo,
    required this.products,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) {
    List<KitchenProduct> productsList = [];
    
    if (json['products'] != null) {
      productsList = List<KitchenProduct>.from(
        (json['products'] as List).map((x) => KitchenProduct.fromJson(x))
      );
    }

    return KitchenOrder(
      orderID: json['orderID'] ?? 0,
      userName: json['userName'] ?? '',
      tableName: json['tableName'] ?? '',
      orderInfo: json['orderInfo'] ?? '',
      products: productsList,
    );
  }
}

class KitchenOrdersResponse {
  final List<KitchenOrder> orders;

  KitchenOrdersResponse({
    required this.orders,
  });

  factory KitchenOrdersResponse.fromJson(Map<String, dynamic> json) {
    List<KitchenOrder> ordersList = [];
    
    if (json['orders'] != null) {
      ordersList = List<KitchenOrder>.from(
        (json['orders'] as List).map((x) => KitchenOrder.fromJson(x))
      );
    }

    return KitchenOrdersResponse(
      orders: ordersList,
    );
  }
}

class KitchenOrdersRequest {
  final String userToken;
  final int compID;

  KitchenOrdersRequest({
    required this.userToken,
    required this.compID,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'compID': compID,
    };
  }
} 