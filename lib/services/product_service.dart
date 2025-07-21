import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/product_category_model.dart';
import 'package:pos701/models/product_model.dart';
import 'package:pos701/models/product_detail_model.dart';
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
      //_logger.d('Yanıt Başlıkları: ${response.headers}');
      
      if (response.statusCode == 200 || response.statusCode == 410) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        //_logger.d('Ham yanıt tipi: ${jsonResponse.runtimeType}');
        
        //_logger.d('Ham yanıt içeriği: $jsonResponse');
        
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

  Future<ProductResponse> getProductsOfCategory({
    required String userToken,
    required int compID,
    required int catID,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}service/product/category/products';
      _logger.d('Ürün API isteği: $url, KategoriID: $catID');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        'catID': catID,
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
      
      _logger.d('Ürün yanıtı alındı. Status: ${response.statusCode}');
      _logger.d('HTTP Durum Kodu: ${response.statusCode}');
      _logger.d('Yanıt Başlıkları: ${response.headers}');
      _logger.d('Ham yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 410 || response.statusCode == 417) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        _logger.d('Ham yanıt tipi: ${jsonResponse.runtimeType}');
        _logger.d('Ham yanıt içeriği: $jsonResponse');
        
        final productResponse = ProductResponse.fromJson(jsonResponse);
        return productResponse;
      } else {
        _logger.w('HTTP ${response.statusCode} hatası: Ürün verileri alınamadı');
        throw Exception('HTTP ${response.statusCode}: Ürün verileri alınamadı');
      }
    } catch (e) {
      _logger.e('Ürünler alınırken hata oluştu', e);
      throw Exception('Ürünler alınırken hata oluştu: $e');
    }
  }
  
  Future<ProductDetailResponse> getProductDetail({
    required String userToken,
    required int compID,
    required int postID,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.productDetailEndpoint}';
      _logger.d('Ürün Detay API isteği: $url, PostID: $postID');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        'postID': postID,
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
      
      _logger.d('Ürün Detay yanıtı alındı. Status: ${response.statusCode}');
      _logger.d('HTTP Durum Kodu: ${response.statusCode}');
      _logger.d('Yanıt Başlıkları: ${response.headers}');
      _logger.d('Ham yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 410) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        _logger.d('Ham yanıt tipi: ${jsonResponse.runtimeType}');
        _logger.d('Ham yanıt içeriği: $jsonResponse');
        
        final productDetailResponse = ProductDetailResponse.fromJson(jsonResponse);
        return productDetailResponse;
      } else {
        _logger.w('HTTP ${response.statusCode} hatası: Ürün detayları alınamadı');
        throw Exception('HTTP ${response.statusCode}: Ürün detayları alınamadı');
      }
    } catch (e) {
      _logger.e('Ürün detayları alınırken hata oluştu', e);
      throw Exception('Ürün detayları alınırken hata oluştu: Kullanıcı bilgileri yüklenemedi. Hata: $e');
    }
  }
}