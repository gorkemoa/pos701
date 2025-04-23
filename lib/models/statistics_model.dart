import 'package:pos701/utils/app_logger.dart';
import 'package:flutter/material.dart';

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
    
    // Sales verisi dönüştürme
    List<SalesData> sales = [];
    if (statisticsData.containsKey('nowDaySales') && statisticsData['nowDaySales'] is List) {
      sales = (statisticsData['nowDaySales'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => SalesData.fromJson(item))
          .toList();
      
      logger.d('Satış verileri dönüştürüldü. Veri sayısı: ${sales.length}');
    }
    
    // Payment verisi dönüştürme
    List<PaymentData> payments = [];
    if (statisticsData.containsKey('nowDayPayments')) {
      if (statisticsData['nowDayPayments'] is List) {
        // Eski format: doğrudan liste
        payments = (statisticsData['nowDayPayments'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => PaymentData.fromJson(item))
            .toList();
      } else if (statisticsData['nowDayPayments'] is Map<String, dynamic>) {
        // Yeni format: payTypes, payAmounts ve colors içeren obje
        var paymentData = statisticsData['nowDayPayments'] as Map<String, dynamic>;
        
        if (paymentData.containsKey('payTypes') && 
            paymentData.containsKey('payAmounts') && 
            paymentData['payTypes'] is List && 
            paymentData['payAmounts'] is List) {
          
          List<String> payTypes = (paymentData['payTypes'] as List).map((e) => e.toString()).toList();
          List<dynamic> payAmounts = paymentData['payAmounts'] as List;
          List<String> colors = paymentData.containsKey('colors') && paymentData['colors'] is List 
              ? (paymentData['colors'] as List).map((e) => e.toString()).toList() 
              : List.filled(payTypes.length, '#000000');
          
          for (int i = 0; i < payTypes.length && i < payAmounts.length; i++) {
            double amount = payAmounts[i] is num 
                ? (payAmounts[i] as num).toDouble() 
                : double.tryParse(payAmounts[i].toString()) ?? 0.0;
            
            String color = i < colors.length ? colors[i] : '#000000';
            
            payments.add(PaymentData(
              type: payTypes[i],
              amount: amount,
              color: color,
            ));
          }
        }
      }
      logger.d('Ödeme verileri dönüştürüldü. Veri sayısı: ${payments.length}');
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
    // API'den gelen json'da total_sales veya amount olabilir
    var salesAmount = json.containsKey('total_sales') 
        ? json['total_sales'] 
        : json['amount'];
    
    return SalesData(
      hour: json['hour']?.toString(),
      amount: salesAmount is num 
          ? salesAmount.toDouble() 
          : (salesAmount != null 
              ? double.tryParse(salesAmount.toString()) ?? 0.0 
              : 0.0),
    );
  }
}

class PaymentData {
  final String? type;
  final double? amount;
  final String? color;  // Yeni eklenen renk alanı
  
  PaymentData({
    this.type,
    this.amount,
    this.color,
  });
  
  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      type: json['type']?.toString(),
      amount: json['amount'] is num 
          ? (json['amount'] as num).toDouble() 
          : (json['amount'] != null 
              ? double.tryParse(json['amount'].toString()) ?? 0.0 
              : 0.0),
      color: json['color']?.toString(),
    );
  }
  
  // HexColor'dan Color'a dönüştüren yardımcı metod
  Color getColor() {
    if (color == null || !color!.startsWith('#')) {
      return Colors.blue;  // Varsayılan renk
    }
    
    String hex = color!.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';  // Alfa kanalını ekle
    }
    
    return Color(int.parse('0x$hex'));
  }
} 