import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/product_category_model.dart';
import 'package:pos701/utils/app_logger.dart';

class ProductService {
  final AppLogger _logger = AppLogger();

  Future<CategoryResponse> getCategories({
    required String userToken,
    required int compID,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}service/product/category/all';
      _logger.d('Kategori API isteği: $url');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
      };
      _logger.d('İstek verileri: $requestBody');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode(requestBody),
      );
      
      _logger.d('Kategori yanıtı alındı. Status: ${response.statusCode}');
      _logger.d('HTTP Durum Kodu: ${response.statusCode}');
      _logger.d('Yanıt Başlıkları: ${response.headers}');
      
      if (response.statusCode == 200 || response.statusCode == 410) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        _logger.d('Ham yanıt tipi: ${jsonResponse.runtimeType}');
        _logger.d('Ham yanıt içeriği: $jsonResponse');
        
        final categoryResponse = CategoryResponse.fromJson(jsonResponse);
        return categoryResponse;
      } else {
        _logger.w('HTTP ${response.statusCode} hatası: Kategori verileri alınamadı');
        throw Exception('HTTP ${response.statusCode}: Kategori verileri alınamadı');
      }
    } catch (e) {
      _logger.e('Kategoriler alınırken hata oluştu', e);
      throw Exception('Kategoriler alınırken hata oluştu: $e');
    }
  }
} 