import 'package:pos701/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/models/order_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pos701/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  final ApiService _apiService;
  
  OrderService({ApiService? apiService}) : _apiService = apiService ?? ApiService();
  
  /// Yeni sipariş oluşturur
  ///
  /// API endpoint: service/user/order/add
  /// Method: POST
  Future<ApiResponseModel<OrderResponse>> createOrder(OrderRequest orderRequest) async {
    try {
      debugPrint('🔵 [SİPARİŞ OLUŞTURMA] Başlatılıyor...');
      final url = '${AppConstants.baseUrl}service/user/order/add';
      final requestBody = orderRequest.toJson();
      
      // İstek gövdesini logla
      debugPrint('🔵 [SİPARİŞ OLUŞTURMA] İstek gövdesi: ${jsonEncode(requestBody)}');
      
      // SharedPreferences'tan token veya kimlik bilgilerini alarak header'ları hazırla
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString(AppConstants.tokenKey);
      
      debugPrint('🔵 [SİPARİŞ OLUŞTURMA] Token: ${savedToken ?? "Token bulunamadı"}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };
      
      // Eğer token varsa, header'a ekle
      if (savedToken != null && savedToken.isNotEmpty) {
        headers['X-Auth-Token'] = savedToken;
      }
      
      debugPrint('🔵 [SİPARİŞ OLUŞTURMA] Headers: $headers');
      debugPrint('🔵 [SİPARİŞ OLUŞTURMA] API isteği gönderiliyor: $url');
      
      final httpResponse = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      debugPrint('🔵 [SİPARİŞ OLUŞTURMA] HTTP yanıt kodu: ${httpResponse.statusCode}');
      debugPrint('🔵 [SİPARİŞ OLUŞTURMA] HTTP yanıt başlıkları: ${httpResponse.headers}');
      
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      debugPrint('🔵 [SİPARİŞ OLUŞTURMA] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      if (responseData == null) {
        debugPrint('🔴 [SİPARİŞ OLUŞTURMA] Sunucudan veri alınamadı');
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: "Sunucudan veri alınamadı",
        );
      }
      
      // HTTP durum kodunu kontrol et ve 417 hatasını ele al
      if (httpResponse.statusCode == 200) {
        debugPrint('🟢 [SİPARİŞ OLUŞTURMA] Başarılı (200): ${jsonEncode(responseData)}');
        return ApiResponseModel.fromJson(
          responseData, 
          (data) => OrderResponse.fromJson(data),
        );
      } else if (httpResponse.statusCode == 410) {
        debugPrint('🟡 [SİPARİŞ OLUŞTURMA] 410 Kodu Alındı: ${jsonEncode(responseData)}');
        return ApiResponseModel.fromJson(
          responseData, 
          (data) => OrderResponse.fromJson(data),
        );
      } else if (httpResponse.statusCode == 417) {
        // 417 (Expectation Failed) durumu için özel işlem
        debugPrint('🔴 [SİPARİŞ OLUŞTURMA] 417 hatası alındı: ${jsonEncode(responseData)}');
        
        // Eğer token ile ilgili bir sorun varsa, token'ı yenilemeyi deneyebilirsiniz
        if (responseData.containsKey('message') && 
            (responseData['message'].toString().contains('token') || 
             responseData['message'].toString().contains('yetki'))) {
          
          debugPrint('🔴 [SİPARİŞ OLUŞTURMA] Token sorunu tespit edildi, token temizleniyor');
          // Token ile ilgili bir sorun varsa token'ı temizle
          // Kullanıcının yeniden giriş yapması gerekecek
          await prefs.remove(AppConstants.tokenKey);
          
          return ApiResponseModel<OrderResponse>(
            error: true,
            success: false,
            errorCode: "Oturum süresi dolmuş olabilir. Lütfen yeniden giriş yapın.",
          );
        }
        
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: responseData['message'] ?? "Sunucu beklentileri karşılanamadı (417)",
        );
      } else if (httpResponse.statusCode == 401) {
        debugPrint('🔴 [SİPARİŞ OLUŞTURMA] Yetkilendirme hatası (401): ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: "Yetkilendirme hatası: Lütfen yeniden giriş yapın",
        );
      } else if (httpResponse.statusCode == 400) {
        debugPrint('🔴 [SİPARİŞ OLUŞTURMA] Geçersiz istek (400): ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: responseData['message'] ?? "Geçersiz istek formatı",
        );
      } else if (httpResponse.statusCode == 500) {
        debugPrint('🔴 [SİPARİŞ OLUŞTURMA] Sunucu hatası (500): ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: "Sunucu hatası: Lütfen daha sonra tekrar deneyin",
        );
      } else if (httpResponse.statusCode == 503) {
        debugPrint('🔴 [SİPARİŞ OLUŞTURMA] Servis kullanılamıyor (503): ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: "Servis şu anda kullanılamıyor: Lütfen daha sonra tekrar deneyin",
        );
      } else {
        debugPrint('🔴 [SİPARİŞ OLUŞTURMA] Beklenmeyen hata kodu: ${httpResponse.statusCode}, Veri: ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: "İşlem başarısız: HTTP ${httpResponse.statusCode} - ${responseData['message'] ?? 'Bilinmeyen hata'}",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SİPARİŞ OLUŞTURMA] İSTİSNA: $e');
      debugPrint('🔴 [SİPARİŞ OLUŞTURMA] STACK TRACE: $stackTrace');
      return ApiResponseModel<OrderResponse>(
        error: true,
        success: false,
        errorCode: "Sipariş oluşturulurken hata: $e",
      );
    }
  }
  
  /// Sipariş detaylarını getirir
  ///
  /// API endpoint: service/user/order/id
  /// Method: PUT
  Future<ApiResponseModel<OrderDetail>> getOrderDetail(OrderDetailRequest request) async {
    try {
      debugPrint('🔵 [SİPARİŞ DETAYI] Getiriliyor...');
      final url = '${AppConstants.baseUrl}service/user/order/id';
      final requestBody = request.toJson();
      
      // İstek gövdesini logla
      debugPrint('🔵 [SİPARİŞ DETAYI] İstek gövdesi: ${jsonEncode(requestBody)}');
      
      // SharedPreferences'tan token veya kimlik bilgilerini alarak header'ları hazırla
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString(AppConstants.tokenKey);
      
      debugPrint('🔵 [SİPARİŞ DETAYI] Token: ${savedToken ?? "Token bulunamadı"}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };
      
      // Eğer token varsa, header'a ekle
      if (savedToken != null && savedToken.isNotEmpty) {
        headers['X-Auth-Token'] = savedToken;
      }
      
      debugPrint('🔵 [SİPARİŞ DETAYI] Headers: $headers');
      debugPrint('🔵 [SİPARİŞ DETAYI] API isteği gönderiliyor: $url');
      
      final httpResponse = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      debugPrint('🔵 [SİPARİŞ DETAYI] HTTP yanıt kodu: ${httpResponse.statusCode}');
      debugPrint('🔵 [SİPARİŞ DETAYI] HTTP yanıt başlıkları: ${httpResponse.headers}');
      
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      debugPrint('🔵 [SİPARİŞ DETAYI] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      if (responseData == null) {
        debugPrint('🔴 [SİPARİŞ DETAYI] Sunucudan veri alınamadı');
        return ApiResponseModel<OrderDetail>(
          error: true,
          success: false,
          errorCode: "Sunucudan veri alınamadı",
        );
      }
      
      // HTTP durum kodunu kontrol et
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 410) {
        debugPrint('🟢 [SİPARİŞ DETAYI] Başarılı (${httpResponse.statusCode}): ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderDetail>.fromJson(
          responseData, 
          (data) => OrderDetail.fromJson(data),
        );
      } else if (httpResponse.statusCode == 417) {
        // 417 (Expectation Failed) durumu için özel işlem
        debugPrint('🔴 [SİPARİŞ DETAYI] 417 hatası alındı: ${jsonEncode(responseData)}');
        
        // Eğer token ile ilgili bir sorun varsa, token'ı yenilemeyi deneyebilirsiniz
        if (responseData.containsKey('message') && 
            (responseData['message'].toString().contains('token') || 
             responseData['message'].toString().contains('yetki'))) {
          
          debugPrint('🔴 [SİPARİŞ DETAYI] Token sorunu tespit edildi, token temizleniyor');
          // Token ile ilgili bir sorun varsa token'ı temizle
          // Kullanıcının yeniden giriş yapması gerekecek
          await prefs.remove(AppConstants.tokenKey);
          
          return ApiResponseModel<OrderDetail>(
            error: true,
            success: false,
            errorCode: "Oturum süresi dolmuş olabilir. Lütfen yeniden giriş yapın.",
          );
        }
        
        return ApiResponseModel<OrderDetail>(
          error: true,
          success: false,
          errorCode: responseData['message'] ?? "Sunucu beklentileri karşılanamadı (417)",
        );
      } else if (httpResponse.statusCode == 401) {
        debugPrint('🔴 [SİPARİŞ DETAYI] Yetkilendirme hatası (401): ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderDetail>(
          error: true,
          success: false,
          errorCode: "Yetkilendirme hatası: Lütfen yeniden giriş yapın",
        );
      } else {
        debugPrint('🔴 [SİPARİŞ DETAYI] Beklenmeyen hata kodu: ${httpResponse.statusCode}, Veri: ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderDetail>(
          error: true,
          success: false,
          errorCode: "İşlem başarısız: HTTP ${httpResponse.statusCode} - ${responseData['message'] ?? 'Bilinmeyen hata'}",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SİPARİŞ DETAYI] İSTİSNA: $e');
      debugPrint('🔴 [SİPARİŞ DETAYI] STACK TRACE: $stackTrace');
      return ApiResponseModel<OrderDetail>(
        error: true,
        success: false,
        errorCode: "Sipariş detayları alınırken hata: $e",
      );
    }
  }

  /// Sipariş güncelleme işlemi
  ///
  /// API endpoint: service/user/order/update
  /// Method: POST
  Future<ApiResponseModel<OrderResponse>> updateOrder(OrderUpdateRequest request) async {
    try {
      debugPrint('🔵 [SİPARİŞ GÜNCELLEME] Başlatılıyor...');
      final url = '${AppConstants.baseUrl}service/user/order/update';
      final requestBody = request.toJson();
      
      // İstek gövdesini logla
      debugPrint('🔵 [SİPARİŞ GÜNCELLEME] İstek gövdesi: ${jsonEncode(requestBody)}');
      
      // SharedPreferences'tan token veya kimlik bilgilerini alarak header'ları hazırla
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString(AppConstants.tokenKey);
      
      debugPrint('🔵 [SİPARİŞ GÜNCELLEME] Token: ${savedToken ?? "Token bulunamadı"}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };
      
      // Eğer token varsa, header'a ekle
      if (savedToken != null && savedToken.isNotEmpty) {
        headers['X-Auth-Token'] = savedToken;
      }
      
      debugPrint('🔵 [SİPARİŞ GÜNCELLEME] Headers: $headers');
      debugPrint('🔵 [SİPARİŞ GÜNCELLEME] API isteği gönderiliyor: $url');
      
      final httpResponse = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      debugPrint('🔵 [SİPARİŞ GÜNCELLEME] HTTP yanıt kodu: ${httpResponse.statusCode}');
      debugPrint('🔵 [SİPARİŞ GÜNCELLEME] HTTP yanıt başlıkları: ${httpResponse.headers}');
      
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      debugPrint('🔵 [SİPARİŞ GÜNCELLEME] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      if (responseData == null) {
        debugPrint('🔴 [SİPARİŞ GÜNCELLEME] Sunucudan veri alınamadı');
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: "Sunucudan veri alınamadı",
        );
      }
      
      // HTTP durum kodunu kontrol et
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 410) {
        debugPrint('🟢 [SİPARİŞ GÜNCELLEME] Başarılı (${httpResponse.statusCode}): ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderResponse>.fromJson(
          responseData, 
          (data) => OrderResponse.fromJson(data),
        );
      } else if (httpResponse.statusCode == 417) {
        // 417 (Expectation Failed) durumu için özel işlem
        debugPrint('🔴 [SİPARİŞ GÜNCELLEME] 417 hatası alındı: ${jsonEncode(responseData)}');
        
        // Eğer token ile ilgili bir sorun varsa, token'ı yenilemeyi deneyebilirsiniz
        if (responseData.containsKey('message') && 
            (responseData['message'].toString().contains('token') || 
             responseData['message'].toString().contains('yetki'))) {
          
          debugPrint('🔴 [SİPARİŞ GÜNCELLEME] Token sorunu tespit edildi, token temizleniyor');
          // Token ile ilgili bir sorun varsa token'ı temizle
          // Kullanıcının yeniden giriş yapması gerekecek
          await prefs.remove(AppConstants.tokenKey);
          
          return ApiResponseModel<OrderResponse>(
            error: true,
            success: false,
            errorCode: "Oturum süresi dolmuş olabilir. Lütfen yeniden giriş yapın.",
          );
        }
        
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: responseData['message'] ?? "Sunucu beklentileri karşılanamadı (417)",
        );
      } else {
        debugPrint('🔴 [SİPARİŞ GÜNCELLEME] Beklenmeyen hata kodu: ${httpResponse.statusCode}, Veri: ${jsonEncode(responseData)}');
        return ApiResponseModel<OrderResponse>(
          error: true,
          success: false,
          errorCode: "İşlem başarısız: HTTP ${httpResponse.statusCode} - ${responseData['message'] ?? 'Bilinmeyen hata'}",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SİPARİŞ GÜNCELLEME] İSTİSNA: $e');
      debugPrint('🔴 [SİPARİŞ GÜNCELLEME] STACK TRACE: $stackTrace');
      return ApiResponseModel<OrderResponse>(
        error: true,
        success: false,
        errorCode: "Sipariş güncellenirken hata: $e",
      );
    }
  }
} 