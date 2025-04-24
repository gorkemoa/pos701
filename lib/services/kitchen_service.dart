import 'package:pos701/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/models/kitchen_order_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pos701/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KitchenService {
  final ApiService _apiService;
  
  KitchenService({ApiService? apiService}) : _apiService = apiService ?? ApiService();
  
  /// Mutfak siparişlerini getirir
  ///
  /// API endpoint: service/user/order/kitchenOrders
  /// Method: POST
  Future<ApiResponseModel<KitchenOrdersResponse>> getKitchenOrders(KitchenOrdersRequest request) async {
    try {
      debugPrint('🔵 [MUTFAK SİPARİŞLERİ] Getiriliyor...');
      final url = '${AppConstants.baseUrl}service/user/order/kitchenOrders';
      final requestBody = request.toJson();
      
      // İstek gövdesini logla
      debugPrint('🔵 [MUTFAK SİPARİŞLERİ] İstek gövdesi: ${jsonEncode(requestBody)}');
      
      // SharedPreferences'tan token veya kimlik bilgilerini alarak header'ları hazırla
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString(AppConstants.tokenKey);
      
      debugPrint('🔵 [MUTFAK SİPARİŞLERİ] Token: ${savedToken ?? "Token bulunamadı"}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };
      
      // Eğer token varsa, header'a ekle
      if (savedToken != null && savedToken.isNotEmpty) {
        headers['X-Auth-Token'] = savedToken;
      }
      
      debugPrint('🔵 [MUTFAK SİPARİŞLERİ] Headers: $headers');
      debugPrint('🔵 [MUTFAK SİPARİŞLERİ] API isteği gönderiliyor: $url');
      
      final httpResponse = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      debugPrint('🔵 [MUTFAK SİPARİŞLERİ] HTTP yanıt kodu: ${httpResponse.statusCode}');
      debugPrint('🔵 [MUTFAK SİPARİŞLERİ] HTTP yanıt başlıkları: ${httpResponse.headers}');
      
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      debugPrint('🔵 [MUTFAK SİPARİŞLERİ] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      if (responseData == null) {
        debugPrint('🔴 [MUTFAK SİPARİŞLERİ] Sunucudan veri alınamadı');
        return ApiResponseModel<KitchenOrdersResponse>(
          error: true,
          success: false,
          errorCode: "Sunucudan veri alınamadı",
        );
      }
      
      // HTTP durum kodunu kontrol et
      if (httpResponse.statusCode == 200) {
        debugPrint('🟢 [MUTFAK SİPARİŞLERİ] Başarılı (200): ${jsonEncode(responseData)}');
        return ApiResponseModel.fromJson(
          responseData, 
          (data) => KitchenOrdersResponse.fromJson(data),
        );
      } else if (httpResponse.statusCode == 410) {
        debugPrint('🟡 [MUTFAK SİPARİŞLERİ] 410 Kodu Alındı: ${jsonEncode(responseData)}');
        return ApiResponseModel.fromJson(
          responseData, 
          (data) => KitchenOrdersResponse.fromJson(data),
        );
      } else if (httpResponse.statusCode == 417) {
        // 417 (Expectation Failed) durumu için özel işlem
        debugPrint('🔴 [MUTFAK SİPARİŞLERİ] 417 hatası alındı: ${jsonEncode(responseData)}');
        
        String errorMessage = "Sunucu beklentileri karşılanamadı (417)";
        if (responseData.containsKey('error_message')) {
          errorMessage = responseData['error_message'].toString();
        }
        
        return ApiResponseModel<KitchenOrdersResponse>(
          error: true,
          success: false,
          errorCode: errorMessage,
        );
      } else if (httpResponse.statusCode == 401) {
        debugPrint('🔴 [MUTFAK SİPARİŞLERİ] Yetkilendirme hatası (401): ${jsonEncode(responseData)}');
        return ApiResponseModel<KitchenOrdersResponse>(
          error: true,
          success: false,
          errorCode: "Yetkilendirme hatası: Lütfen yeniden giriş yapın",
        );
      } else {
        debugPrint('🔴 [MUTFAK SİPARİŞLERİ] Beklenmeyen hata kodu: ${httpResponse.statusCode}, Veri: ${jsonEncode(responseData)}');
        
        String errorMessage = "İşlem başarısız";
        if (responseData.containsKey('error_message')) {
          errorMessage = responseData['error_message'].toString();
        } else if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
        
        return ApiResponseModel<KitchenOrdersResponse>(
          error: true,
          success: false,
          errorCode: "$errorMessage (HTTP ${httpResponse.statusCode})",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [MUTFAK SİPARİŞLERİ] İSTİSNA: $e');
      debugPrint('🔴 [MUTFAK SİPARİŞLERİ] STACK TRACE: $stackTrace');
      return ApiResponseModel<KitchenOrdersResponse>(
        error: true,
        success: false,
        errorCode: "Mutfak siparişleri getirilirken hata: $e",
      );
    }
  }

  /// Mutfakta hazırlanan ürün veya siparişin hazır olduğunu bildirir
  ///
  /// API endpoint: service/user/order/ready
  /// Method: POST
  /// 
  /// [userToken] Kullanıcı token bilgisi
  /// [compID] Şirket ID
  /// [orderID] Sipariş ID
  /// [opID] İşlem ID (Ürün hazırsa ürün ID'si, tümü hazırsa 0)
  /// [step] İşlem tipi ("product": Ürün hazır, "order": Tümü hazır)
  Future<ApiResponseModel<dynamic>> markOrderReady({
    required String userToken,
    required int compID,
    required int orderID,
    int opID = 0,
    required String step,
  }) async {
    try {
      debugPrint('🔵 [MUTFAK HAZIR] İşlem başlatılıyor: orderID=$orderID, opID=$opID, step=$step');
      final url = '${AppConstants.baseUrl}service/user/order/ready';
      
      final Map<String, dynamic> requestBody = {
        'userToken': userToken,
        'compID': compID,
        'orderID': orderID,
        'opID': opID,
        'step': step,
      };
      
      // İstek gövdesini logla
      debugPrint('🔵 [MUTFAK HAZIR] İstek gövdesi: ${jsonEncode(requestBody)}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };
      
      // Eğer token varsa, header'a ekle
      if (userToken.isNotEmpty) {
        headers['X-Auth-Token'] = userToken;
      }
      
      debugPrint('🔵 [MUTFAK HAZIR] API isteği gönderiliyor: $url');
      
      final httpResponse = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      debugPrint('🔵 [MUTFAK HAZIR] HTTP yanıt kodu: ${httpResponse.statusCode}');
      
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      debugPrint('🔵 [MUTFAK HAZIR] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      if (responseData == null) {
        debugPrint('🔴 [MUTFAK HAZIR] Sunucudan veri alınamadı');
        return ApiResponseModel<dynamic>(
          error: true,
          success: false,
          errorCode: "Sunucudan veri alınamadı",
        );
      }
      
      // HTTP durum kodunu kontrol et
      if (httpResponse.statusCode == 410) {
        debugPrint('🟢 [MUTFAK HAZIR] Başarılı (410): ${jsonEncode(responseData)}');
        return ApiResponseModel.fromJson(
          responseData, 
          (data) => data,
        );
      } else {
        debugPrint('🔴 [MUTFAK HAZIR] Hata: ${httpResponse.statusCode}, Veri: ${jsonEncode(responseData)}');
        
        String errorMessage = "İşlem başarısız";
        if (responseData.containsKey('error_message')) {
          errorMessage = responseData['error_message'].toString();
        } else if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
        
        return ApiResponseModel<dynamic>(
          error: true,
          success: false,
          errorCode: "$errorMessage (HTTP ${httpResponse.statusCode})",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [MUTFAK HAZIR] İSTİSNA: $e');
      debugPrint('🔴 [MUTFAK HAZIR] STACK TRACE: $stackTrace');
      return ApiResponseModel<dynamic>(
        error: true,
        success: false,
        errorCode: "Sipariş hazır işaretlenirken hata: $e",
      );
    }
  }
} 