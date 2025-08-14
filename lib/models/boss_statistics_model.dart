class BossStatisticsModel {
  final String statisticsKey;
  final String statisticsTitle;
  final String statisticsDetail;
  final String statisticsAmount;
  final String statisticsIcon;

  BossStatisticsModel({
    required this.statisticsKey,
    required this.statisticsTitle,
    required this.statisticsDetail,
    required this.statisticsAmount,
    required this.statisticsIcon,
  });

  factory BossStatisticsModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsModel(
      statisticsKey: json['statisticsKey'] ?? '',
      statisticsTitle: json['statisticsTitle'] ?? '',
      statisticsDetail: json['statisticsDetail'] ?? '',
      statisticsAmount: json['statisticsAmount'] ?? '0,00 TL',
      statisticsIcon: json['statisticsIcon'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statisticsKey': statisticsKey,
      'statisticsTitle': statisticsTitle,
      'statisticsDetail': statisticsDetail,
      'statisticsAmount': statisticsAmount,
      'statisticsIcon': statisticsIcon,
    };
  }

  // Geriye uyumluluk için getter'lar
  String get title => statisticsTitle;
  String get amount => statisticsAmount;
}

class BossStatisticsGraphicModel {
  final String sortDate;
  final String date;
  final String amount;

  BossStatisticsGraphicModel({
    required this.sortDate,
    required this.date,
    required this.amount,
  });

  factory BossStatisticsGraphicModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsGraphicModel(
      sortDate: json['sortDate'] ?? '',
      date: json['date'] ?? '',
      amount: json['amount'] ?? '0,00 TL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sortDate': sortDate,
      'date': date,
      'amount': amount,
    };
  }

  // Pasta grafiği için sayısal değer döndürür
  double get numericAmount {
    try {
      // "1.595,00 TL" formatından sayısal değer çıkarır
      String cleanAmount = amount.replaceAll(' TL', '').replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(cleanAmount) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}

class BossStatisticsResponse {
  final bool error;
  final bool success;
  final BossStatisticsData data;

  BossStatisticsResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: BossStatisticsData.fromJson(json['data'] ?? {}),
    );
  }
}

class BossStatisticsData {
  final List<BossStatisticsModel> statistics;
  final List<BossStatisticsGraphicModel> graphics;

  BossStatisticsData({
    required this.statistics,
    required this.graphics,
  });

  factory BossStatisticsData.fromJson(Map<String, dynamic> json) {
    return BossStatisticsData(
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsModel.fromJson(item))
              .toList() ??
          [],
      graphics: (json['graphics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsGraphicModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class BossStatisticsDetailModel {
  final String title;
  final int count;
  final String amount;

  BossStatisticsDetailModel({
    required this.title,
    required this.count,
    required this.amount,
  });

  factory BossStatisticsDetailModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsDetailModel(
      title: json['title'] ?? '',
      count: json['count'] ?? 0,
      amount: json['amount'] ?? '0,00 TL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'count': count,
      'amount': amount,
    };
  }
}

class BossStatisticsDetailResponse {
  final bool error;
  final bool success;
  final BossStatisticsDetailData data;

  BossStatisticsDetailResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsDetailResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsDetailResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: BossStatisticsDetailData.fromJson(json['data'] ?? {}),
    );
  }
}

class BossStatisticsDetailData {
  final List<BossStatisticsDetailModel> statistics;
  final BossStatisticsSummary summary;

  BossStatisticsDetailData({
    required this.statistics,
    required this.summary,
  });

  factory BossStatisticsDetailData.fromJson(Map<String, dynamic> json) {
    return BossStatisticsDetailData(
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsDetailModel.fromJson(item))
              .toList() ??
          [],
      summary: BossStatisticsSummary.fromJson(json['summary'] ?? {}),
    );
  }

  // Geriye uyumluluk için getter'lar
  int get totalCount {
    return statistics.fold(0, (sum, item) => sum + item.count);
  }

  String get totalAmount {
    return summary.netTotal.amount;
  }
}

class BossStatisticsSummary {
  final BossStatisticsSummaryItem salesTotal;
  final BossStatisticsSummaryItem netTotal;

  BossStatisticsSummary({
    required this.salesTotal,
    required this.netTotal,
  });

  factory BossStatisticsSummary.fromJson(Map<String, dynamic> json) {
    return BossStatisticsSummary(
      salesTotal: BossStatisticsSummaryItem.fromJson(json['salesTotal'] ?? {}),
      netTotal: BossStatisticsSummaryItem.fromJson(json['netTotal'] ?? {}),
    );
  }
}

class BossStatisticsSummaryItem {
  final String title;
  final int count;
  final String amount;

  BossStatisticsSummaryItem({
    required this.title,
    required this.count,
    required this.amount,
  });

  factory BossStatisticsSummaryItem.fromJson(Map<String, dynamic> json) {
    return BossStatisticsSummaryItem(
      title: json['title'] ?? '',
      count: json['count'] ?? 0,
      amount: json['amount'] ?? '0,00 TL',
    );
  }
}

class BossStatisticsOrderModel {
  final String orderID;
  final String orderCode;
  final String orderAmount;
  final String orderDiscount;
  final String orderDate;
  final String userID;

  BossStatisticsOrderModel({
    required this.orderID,
    required this.orderCode,
    required this.orderAmount,
    required this.orderDiscount,
    required this.orderDate,
    required this.userID,
  });

  factory BossStatisticsOrderModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsOrderModel(
      orderID: json['orderID']?.toString() ?? '',
      orderCode: json['orderCode'] ?? '',
      orderAmount: json['orderAmount'] ?? '0,00 TL',
      orderDiscount: json['orderDiscount'] ?? '0,00 TL',
      orderDate: json['orderDate'] ?? '',
      userID: json['userID']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderID': orderID,
      'orderCode': orderCode,
      'orderAmount': orderAmount,
      'orderDiscount': orderDiscount,
      'orderDate': orderDate,
      'userID': userID,
    };
  }
}

class BossStatisticsCashOrderModel {
  final int orderID;
  final String orderCode;
  final String orderAmount;
  final String orderDiscount;
  final String netOrderAmount;
  final String paidAmount;
  final String remainingAmount;
  final String orderDate;
  final int userID;

  BossStatisticsCashOrderModel({
    required this.orderID,
    required this.orderCode,
    required this.orderAmount,
    required this.orderDiscount,
    required this.netOrderAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.orderDate,
    required this.userID,
  });

  factory BossStatisticsCashOrderModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsCashOrderModel(
      orderID: json['orderID'] ?? 0,
      orderCode: json['orderCode'] ?? '',
      orderAmount: json['orderAmount'] ?? '0,00 TL',
      orderDiscount: json['orderDiscount'] ?? '0,00 TL',
      netOrderAmount: json['netOrderAmount'] ?? '0,00 TL',
      paidAmount: json['paidAmount'] ?? '0,00 TL',
      remainingAmount: json['remainingAmount'] ?? '0,00 TL',
      orderDate: json['orderDate'] ?? '',
      userID: json['userID'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderID': orderID,
      'orderCode': orderCode,
      'orderAmount': orderAmount,
      'orderDiscount': orderDiscount,
      'netOrderAmount': netOrderAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'orderDate': orderDate,
      'userID': userID,
    };
  }
}

class BossStatisticsOrderResponse {
  final bool error;
  final bool success;
  final BossStatisticsOrderData data;

  BossStatisticsOrderResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsOrderResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsOrderResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: BossStatisticsOrderData.fromJson(json['data'] ?? {}),
    );
  }
}

class BossStatisticsOrderData {
  final List<BossStatisticsOrderModel> statistics;
  final int totalCount;
  final String totalAmount;

  BossStatisticsOrderData({
    required this.statistics,
    required this.totalCount,
    required this.totalAmount,
  });

  factory BossStatisticsOrderData.fromJson(Map<String, dynamic> json) {
    return BossStatisticsOrderData(
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsOrderModel.fromJson(item))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      totalAmount: json['totalAmount'] ?? '0,00 TL',
    );
  }
}

class BossStatisticsCashOrderResponse {
  final bool error;
  final bool success;
  final BossStatisticsCashOrderData data;

  BossStatisticsCashOrderResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsCashOrderResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsCashOrderResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: BossStatisticsCashOrderData.fromJson(json['data'] ?? {}),
    );
  }
}

class BossStatisticsCashOrderData {
  final List<BossStatisticsCashOrderModel> statistics;
  final int totalCount;
  final String totalAmount;
  final String totalOrderAmount;
  final String totalDiscountAmount;
  final String totalPaidAmount;
  final String totalRemainingAmount;

  BossStatisticsCashOrderData({
    required this.statistics,
    required this.totalCount,
    required this.totalAmount,
    required this.totalOrderAmount,
    required this.totalDiscountAmount,
    required this.totalPaidAmount,
    required this.totalRemainingAmount,
  });

  factory BossStatisticsCashOrderData.fromJson(Map<String, dynamic> json) {
    return BossStatisticsCashOrderData(
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsCashOrderModel.fromJson(item))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      totalAmount: json['totalAmount'] ?? '0,00 TL',
      totalOrderAmount: json['totalOrderAmount'] ?? '0,00 TL',
      totalDiscountAmount: json['totalDiscountAmount'] ?? '0,00 TL',
      totalPaidAmount: json['totalPaidAmount'] ?? '0,00 TL',
      totalRemainingAmount: json['totalRemainingAmount'] ?? '0,00 TL',
    );
  }
}

class BossStatisticsProductModel {
  final String productName;
  final String productUnit;
  final String productPrice;
  final int productQuantity;
  final String productTotalAmount;

  BossStatisticsProductModel({
    required this.productName,
    required this.productUnit,
    required this.productPrice,
    required this.productQuantity,
    required this.productTotalAmount,
  });

  factory BossStatisticsProductModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsProductModel(
      productName: json['productName'] ?? '',
      productUnit: json['productUnit'] ?? '',
      productPrice: json['productPrice'] ?? '0,00 TL',
      productQuantity: json['productQuantity'] ?? 0,
      productTotalAmount: json['productTotalAmount'] ?? '0,00 TL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'productUnit': productUnit,
      'productPrice': productPrice,
      'productQuantity': productQuantity,
      'productTotalAmount': productTotalAmount,
    };
  }
}

class BossStatisticsProductResponse {
  final bool error;
  final bool success;
  final BossStatisticsProductData data;

  BossStatisticsProductResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsProductResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsProductResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: BossStatisticsProductData.fromJson(json['data'] ?? {}),
    );
  }
}

class BossStatisticsProductData {
  final List<BossStatisticsProductModel> statistics;
  final int totalCount;
  final int totalQuantity;
  final String totalAmount;

  BossStatisticsProductData({
    required this.statistics,
    required this.totalCount,
    required this.totalQuantity,
    required this.totalAmount,
  });

  factory BossStatisticsProductData.fromJson(Map<String, dynamic> json) {
    return BossStatisticsProductData(
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsProductModel.fromJson(item))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
      totalAmount: json['totalAmount'] ?? '0,00 TL',
    );
  }
}

class BossStatisticsExpenseModel {
  final int id;
  final String title;
  final String paymentType;
  final String description;
  final String amount;
  final String date;
  final int userID;
  // Zayi için ek alanlar
  final String personName;
  final int quantity;
  final String productInfo;

  BossStatisticsExpenseModel({
    required this.id,
    required this.title,
    required this.paymentType,
    required this.description,
    required this.amount,
    required this.date,
    required this.userID,
    this.personName = '',
    this.quantity = 0,
    this.productInfo = '',
  });

  factory BossStatisticsExpenseModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsExpenseModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      paymentType: json['paymentType'] ?? '',
      description: json['description'] ?? '',
      amount: json['amount'] ?? '0,00 TL',
      date: json['date'] ?? '',
      userID: json['userID'] ?? 0,
      personName: json['personName'] ?? '',
      quantity: json['quantity'] ?? 0,
      productInfo: json['productInfo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'paymentType': paymentType,
      'description': description,
      'amount': amount,
      'date': date,
      'userID': userID,
      'personName': personName,
      'quantity': quantity,
      'productInfo': productInfo,
    };
  }
}

class BossStatisticsExpenseResponse {
  final bool error;
  final bool success;
  final BossStatisticsExpenseData data;

  BossStatisticsExpenseResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsExpenseResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsExpenseResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: BossStatisticsExpenseData.fromJson(json['data'] ?? {}),
    );
  }
}

class BossStatisticsExpenseData {
  final List<BossStatisticsExpenseModel> statistics;
  final int totalCount;
  final String totalAmount;

  BossStatisticsExpenseData({
    required this.statistics,
    required this.totalCount,
    required this.totalAmount,
  });

  factory BossStatisticsExpenseData.fromJson(Map<String, dynamic> json) {
    return BossStatisticsExpenseData(
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsExpenseModel.fromJson(item))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      totalAmount: json['totalAmount'] ?? '0,00 TL',
    );
  }
} 

// Cashier detail models
class BossStatisticsCashierModel {
  final int paymentTypeID;
  final String paymentTypeName;
  final String paymentTypeColor;
  final String paymentTypeImage;
  final int paymentCount;
  final String totalAmount;

  BossStatisticsCashierModel({
    required this.paymentTypeID,
    required this.paymentTypeName,
    required this.paymentTypeColor,
    required this.paymentTypeImage,
    required this.paymentCount,
    required this.totalAmount,
  });

  factory BossStatisticsCashierModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsCashierModel(
      paymentTypeID: json['paymentTypeID'] ?? 0,
      paymentTypeName: json['paymentTypeName'] ?? '',
      paymentTypeColor: json['paymentTypeColor'] ?? '#000000',
      paymentTypeImage: json['paymentTypeImage'] ?? '',
      paymentCount: json['paymentCount'] ?? 0,
      totalAmount: json['totalAmount'] ?? '0,00 TL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentTypeID': paymentTypeID,
      'paymentTypeName': paymentTypeName,
      'paymentTypeColor': paymentTypeColor,
      'paymentTypeImage': paymentTypeImage,
      'paymentCount': paymentCount,
      'totalAmount': totalAmount,
    };
  }
}

class BossStatisticsCashierResponse {
  final bool error;
  final bool success;
  final BossStatisticsCashierData data;

  BossStatisticsCashierResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsCashierResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsCashierResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: BossStatisticsCashierData.fromJson(json['data'] ?? {}),
    );
  }
}

class BossStatisticsCashierData {
  final List<BossStatisticsCashierModel> statistics;
  final int totalTypes;
  final int totalCount;
  final String totalAmount;

  BossStatisticsCashierData({
    required this.statistics,
    required this.totalTypes,
    required this.totalCount,
    required this.totalAmount,
  });

  factory BossStatisticsCashierData.fromJson(Map<String, dynamic> json) {
    return BossStatisticsCashierData(
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsCashierModel.fromJson(item))
              .toList() ??
          [],
      totalTypes: json['totalTypes'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      totalAmount: json['totalAmount'] ?? '0,00 TL',
    );
  }
}