import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/product_category_model.dart';
import 'package:pos701/models/product_model.dart';
import 'package:pos701/models/product_detail_model.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:pos701/services/connectivity_service.dart';

class ProductService {
  final AppLogger _logger = AppLogger();

  Future<CategoryResponse> getCategories({
    required String userToken,
    required int compID,
  }) async {
    try {
      final String primaryUrl = '${AppConstants.baseUrl}service/product/category/all';
      final String fallbackUrl = '${AppConstants.localFallbackBaseUrl}${AppConstants.allCategoriesJsonEndpoint}';
      _logger.d('Kategori API isteği (primary): $primaryUrl');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
      };
      _logger.d('İstek verileri: $requestBody');
      
      http.Response? response;
      final bool hasInternet = await ConnectivityService().hasInternetConnection();
      if (hasInternet) {
        try {
          response = await http.put(
            Uri.parse(primaryUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
            },
            body: jsonEncode(requestBody),
          );
          _logger.d('Kategori yanıtı (primary). Status: ${response.statusCode}');
          if (!(response.statusCode == 200 || response.statusCode == 410)) {
            _logger.w('Primary kategori isteği başarısız (${response.statusCode}). Fallback: $fallbackUrl');
            response = await http.get(
              Uri.parse(fallbackUrl),
              headers: {
                'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
              },
            );
          }
        } catch (e) {
          _logger.w('Primary kategori isteğinde hata: $e. Fallback: $fallbackUrl');
          response = await http.get(
            Uri.parse(fallbackUrl),
            headers: {
              'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
            },
          );
        }
      } else {
        _logger.w('İnternet yok. Kategori fallback: $fallbackUrl');
        response = await http.get(
          Uri.parse(fallbackUrl),
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
          },
        );
      }

      _logger.d('Kategori yanıtı alındı. Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 410) {
        final dynamic raw = jsonDecode(response.body);
        if (raw is List) {
          // Fallback JSON doğrudan liste döndürüyorsa map'le ve sarmala
          final List<Category> categories = raw
              .whereType<dynamic>()
              .map((e) => Category.fromJson(e as Map<String, dynamic>))
              .toList();
          return CategoryResponse(
            error: false,
            success: true,
            data: CategoryData(categories: categories),
          );
        } else if (raw is Map<String, dynamic>) {
          final categoryResponse = CategoryResponse.fromJson(raw);
          return categoryResponse;
        } else {
          _logger.w('Beklenmeyen kategori yanıt formatı: ${raw.runtimeType}');
          throw Exception('Beklenmeyen kategori yanıt formatı');
        }
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
      final String primaryUrl = '${AppConstants.baseUrl}service/product/category/products';
      final String fallbackUrl = '${AppConstants.localFallbackBaseUrl}${AppConstants.allProductsJsonEndpoint}';
      _logger.d('Ürün API isteği (primary): $primaryUrl, KategoriID: $catID');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        'catID': catID,
      };
      _logger.d('İstek verileri: $requestBody');
      
      http.Response? response;
      final bool hasInternet = await ConnectivityService().hasInternetConnection();
      if (hasInternet) {
        try {
          response = await http.put(
            Uri.parse(primaryUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
            },
            body: jsonEncode(requestBody),
          );
          _logger.d('Ürün yanıtı (primary). Status: ${response.statusCode}');
          if (!(response.statusCode == 200 || response.statusCode == 410 || response.statusCode == 417)) {
            _logger.w('Primary ürün isteği başarısız (${response.statusCode}). Fallback: $fallbackUrl');
            response = await http.get(
              Uri.parse(fallbackUrl),
              headers: {
                'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
              },
            );
          }
        } catch (e) {
          _logger.w('Primary ürün isteğinde hata: $e. Fallback: $fallbackUrl');
          response = await http.get(
            Uri.parse(fallbackUrl),
            headers: {
              'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
            },
          );
        }
      } else {
        _logger.w('İnternet yok. Ürün fallback: $fallbackUrl');
        response = await http.get(
          Uri.parse(fallbackUrl),
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
          },
        );
      }

      _logger.d('Ürün yanıtı alındı. Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 410 || response.statusCode == 417) {
        final dynamic raw = jsonDecode(response.body);
        if (raw is List) {
          // Local fallback: tüm ürünler gelir, catID'ye göre filtrele
          final List<Product> filtered = raw
              .whereType<dynamic>()
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .where((p) => p.catID == catID)
              .toList();
          return ProductResponse(
            error: false,
            success: true,
            data: ProductData(products: filtered),
          );
        } else if (raw is Map<String, dynamic>) {
          // Map formatı: API veya local JSON olabilir. Local JSON'da da filtre uygula.
          final bool isLocalFallback = (response.request?.url.host == '192.168.1.50');
          if (isLocalFallback) {
            List<dynamic> list = <dynamic>[];
            if (raw.containsKey('products') && raw['products'] is List) {
              list = raw['products'] as List<dynamic>;
            } else if (raw['data'] is Map<String, dynamic> && (raw['data'] as Map<String, dynamic>)['products'] is List) {
              list = (raw['data'] as Map<String, dynamic>)['products'] as List<dynamic>;
            }

            if (list.isNotEmpty) {
              final List<Product> filtered = list
                  .whereType<dynamic>()
                  .map((e) => Product.fromJson(e as Map<String, dynamic>))
                  .where((p) => p.catID == catID)
                  .toList();
              return ProductResponse(
                error: false,
                success: true,
                data: ProductData(products: filtered),
              );
            }
          }
          // API yanıtı: sunucu zaten kategoriye göre filtreli döner; ekstra filtre uygulama
          return ProductResponse.fromJson(raw);
        } else {
          _logger.w('Beklenmeyen ürün yanıt formatı: ${raw.runtimeType}');
          throw Exception('Beklenmeyen ürün yanıt formatı');
        }
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

  Future<ProductResponse> getAllProducts({
    required String userToken,
    required int compID,
    String searchText = '',
  }) async {
    try {
      final String primaryUrl = '${AppConstants.baseUrl}${AppConstants.allProductsEndpoint}';
      final String fallbackUrl = '${AppConstants.localFallbackBaseUrl}${AppConstants.allProductsJsonEndpoint}';
      _logger.d('Tüm Ürünler API isteği (primary): $primaryUrl');
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        if (searchText.isNotEmpty) 'searchText': searchText,
      };
      _logger.d('İstek verileri: $requestBody');
      http.Response? response;
      final bool hasInternet = await ConnectivityService().hasInternetConnection();
      if (hasInternet) {
        try {
          response = await http.put(
            Uri.parse(primaryUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
            },
            body: jsonEncode(requestBody),
          );
          _logger.d('Tüm Ürünler yanıtı (primary). Status: ${response.statusCode}');
          if (!(response.statusCode == 200 || response.statusCode == 410)) {
            _logger.w('Primary tüm ürünler isteği başarısız (${response.statusCode}). Fallback: $fallbackUrl');
            response = await http.get(
              Uri.parse(fallbackUrl),
              headers: {
                'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
              },
            );
          }
        } catch (e) {
          _logger.w('Primary tüm ürünler isteğinde hata: $e. Fallback: $fallbackUrl');
          response = await http.get(
            Uri.parse(fallbackUrl),
            headers: {
              'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
            },
          );
        }
      } else {
        _logger.w('İnternet yok. Tüm ürünler fallback: $fallbackUrl');
        response = await http.get(
          Uri.parse(fallbackUrl),
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
          },
        );
      }

      _logger.d('Tüm Ürünler yanıtı alındı. Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 410) {
        final dynamic raw = jsonDecode(response.body);
        if (raw is List) {
          final List<Product> products = raw
              .whereType<dynamic>()
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
          return ProductResponse(
            error: false,
            success: true,
            data: ProductData(products: products),
          );
        } else if (raw is Map<String, dynamic>) {
          final productResponse = ProductResponse.fromJson(raw);
          return productResponse;
        } else {
          _logger.w('Beklenmeyen tüm ürünler yanıt formatı: ${raw.runtimeType}');
          throw Exception('Beklenmeyen tüm ürünler yanıt formatı');
        }
      } else if (response.statusCode == 401) {
        _logger.w('HTTP 401: Yetkisiz erişim');
        throw Exception('Oturumunuz sona erdi. Lütfen tekrar giriş yapın.');
      } else {
        _logger.w('HTTP ${response.statusCode} hatası: Tüm ürünler alınamadı');
        throw Exception('HTTP ${response.statusCode}: Tüm ürünler alınamadı');
      }
    } catch (e) {
      _logger.e('Tüm ürünler alınırken hata oluştu', e);
      throw Exception('Tüm ürünler alınırken hata oluştu: $e');
    }
  }
}