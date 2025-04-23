import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos701/models/table_model.dart';
import 'package:pos701/constants/app_constants.dart';

class TableService {
  Future<TablesResponse> getTables({
    required String userToken,
    required int compID,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.getTablesEndpoint}';
      debugPrint('API isteği: $url');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
      };
      debugPrint('İstek verileri: $requestBody');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Yanıt kodu: ${response.statusCode}');
      debugPrint('Yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 410 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return TablesResponse.fromJson(data);
      } else {
        throw Exception('Sunucu hatası: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Tablolar alınırken hata: $e');
      throw Exception('Tablolar alınırken hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> changeTable({
    required String userToken,
    required int compID,
    required int orderID,
    required int tableID,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.tableChangeEndpoint}';
      debugPrint('Masa değiştirme API isteği: $url');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        'orderID': orderID,
        'tableID': tableID, // Yeni masanın ID değeri
      };
      debugPrint('Masa değiştirme istek verileri: $requestBody');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Masa değiştirme yanıt kodu: ${response.statusCode}');
      debugPrint('Masa değiştirme yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 410) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Masa değiştirme hatası: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Masa değiştirme işlemi sırasında hata: $e');
      throw Exception('Masa değiştirme işlemi sırasında hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> mergeTables({
    required String userToken,
    required int compID,
    required int tableID,
    required int orderID,
    required List<int> mergeTables,
    required String step, // "merged" veya "unmerged" değeri alabilir
  }) async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.tableChangeEndpoint}';
      debugPrint('Masa ${step == "merged" ? "birleştirme" : "ayırma"} API isteği: $url');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        'tableID': tableID,
        'orderID': orderID,
        'step': step,
        'mergeTables': mergeTables,
      };
      debugPrint('Masa ${step == "merged" ? "birleştirme" : "ayırma"} istek verileri: $requestBody');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Masa ${step == "merged" ? "birleştirme" : "ayırma"} yanıt kodu: ${response.statusCode}');
      debugPrint('Masa ${step == "merged" ? "birleştirme" : "ayırma"} yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 410 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error_message': 'Yetkilendirme hatası: Lütfen tekrar giriş yapın.',
        };
      } else {
        return {
          'success': false,
          'error_message': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Masa ${step == "merged" ? "birleştirme" : "ayırma"} işlemi sırasında hata: $e');
      return {
        'success': false,
        'error_message': 'İşlem sırasında bir hata oluştu: $e',
      };
    }
  }

  Future<Map<String, dynamic>> transferOrder({
    required String userToken,
    required int compID,
    required int oldOrderID,
    required int newOrderID,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}service/user/order/tableOrderTransfer';
      debugPrint('Adisyon aktarım API isteği: $url');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        'oldOrderID': oldOrderID,
        'newOrderID': newOrderID,
      };
      debugPrint('Adisyon aktarım istek verileri: $requestBody');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Adisyon aktarım yanıt kodu: ${response.statusCode}');
      debugPrint('Adisyon aktarım yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 410 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error_message': 'Yetkilendirme hatası: Lütfen tekrar giriş yapın.',
        };
      } else {
        return {
          'success': false,
          'error_message': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Adisyon aktarım işlemi sırasında hata: $e');
      return {
        'success': false,
        'error_message': 'İstek gönderilirken bir hata oluştu: $e',
      };
    }
  }

  Future<Map<String, dynamic>> fastPay({
    required String userToken,
    required int compID,
    required int orderID,
    required int isDiscount,
    required int discountType,
    required int discount,
    required int payType,
    required String payAction,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}service/user/order/payment/fastPay';
      debugPrint('Hızlı ödeme API isteği: $url');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        'orderID': orderID,
        'isDiscount': isDiscount,
        'discountType': discountType,
        'discount': discount,
        'payType': payType,
        'payAction': payAction,
      };
      debugPrint('Hızlı ödeme istek verileri: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Hızlı ödeme yanıt kodu: ${response.statusCode}');
      debugPrint('Hızlı ödeme yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 410 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error_message': 'Yetkilendirme hatası: Lütfen tekrar giriş yapın.',
        };
      } else {
        return {
          'success': false,
          'error_message': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Hızlı ödeme işlemi sırasında hata: $e');
      return {
        'success': false,
        'error_message': 'İstek gönderilirken bir hata oluştu: $e',
      };
    }
  }
}