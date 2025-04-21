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
      
      if (response.statusCode == 410) {
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
}