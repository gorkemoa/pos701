import 'package:pos701/utils/app_logger.dart';

class StatisticsModel {
  final String totalAmountText;
  final String totalExpenseAmountText;
  final String totalOpenAmountText;
  final String totalGuestText;
  final String totalAmount;
  final String totalExpenseAmount;
  final String totalOpenAmount;
  final int totalGuest;
  final int totalTables;
  final int orderTables;
  final List<SalesData> nowDaySales;
  final List<PaymentData> nowDayPayments;
  
  StatisticsModel({
    required this.totalAmountText,
    required this.totalExpenseAmountText,
    required this.totalOpenAmountText,
    required this.totalGuestText,
    required this.totalAmount,
    required this.totalExpenseAmount,
    required this.totalOpenAmount,
    required this.totalGuest,
    required this.totalTables,
    required this.orderTables,
    required this.nowDaySales,
    required this.nowDayPayments,
  });
  
  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    final logger = AppLogger();
    logger.d('StatisticsModel.fromJson çağrıldı');
    
    Map<String, dynamic> statisticsData;
    if (json.containsKey('statistics') && json['statistics'] is Map<String, dynamic>) {
      statisticsData = json['statistics'] as Map<String, dynamic>;
      logger.d('İstatistik verisi bulundu: $statisticsData');
    } else {
      // API direkt istatistik bilgilerini döndürmüş olabilir
      statisticsData = json;
      logger.d('İstatistik verisi direkt gönderilmiş olabilir: $statisticsData');
    }
    
    // Sales ve Payment verileri dönüştürme
    List<SalesData> sales = [];
    if (statisticsData.containsKey('nowDaySales') && statisticsData['nowDaySales'] is List) {
      sales = (statisticsData['nowDaySales'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => SalesData.fromJson(item))
          .toList();
    }
    
    List<PaymentData> payments = [];
    if (statisticsData.containsKey('nowDayPayments') && statisticsData['nowDayPayments'] is List) {
      payments = (statisticsData['nowDayPayments'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => PaymentData.fromJson(item))
          .toList();
    }
    
    return StatisticsModel(
      totalAmountText: statisticsData['totalAmountText']?.toString() ?? 'Bugünkü Toplam Satış Tutarı',
      totalExpenseAmountText: statisticsData['totalExpenseAmountText']?.toString() ?? 'Bugünkü Toplam Gider Tutarı',
      totalOpenAmountText: statisticsData['totalOpenAmountText']?.toString() ?? 'Bugün Açık Sipariş Toplamı',
      totalGuestText: statisticsData['totalGuestText']?.toString() ?? 'Bugün Ağırlanan Misafir Sayısı',
      totalAmount: statisticsData['totalAmount']?.toString() ?? '0,00 TL',
      totalExpenseAmount: statisticsData['totalExpenseAmount']?.toString() ?? '0,00 TL',
      totalOpenAmount: statisticsData['totalOpenAmount']?.toString() ?? '0,00 TL',
      totalGuest: statisticsData['totalGuest'] is int ? statisticsData['totalGuest'] : 0,
      totalTables: statisticsData['totalTables'] is int ? statisticsData['totalTables'] : 0,
      orderTables: statisticsData['orderTables'] is int ? statisticsData['orderTables'] : 0,
      nowDaySales: sales,
      nowDayPayments: payments,
    );
  }
}

class SalesData {
  final String? hour;
  final double? amount;
  
  SalesData({
    this.hour,
    this.amount,
  });
  
  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      hour: json['hour']?.toString(),
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : 0.0,
    );
  }
}

class PaymentData {
  final String? type;
  final double? amount;
  
  PaymentData({
    this.type,
    this.amount,
  });
  
  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      type: json['type']?.toString(),
      amount: json['amount'] is num ? (json['amount'] as num).toDouble() : 0.0,
    );
  }
} 