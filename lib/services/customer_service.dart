import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/models/customer_model.dart';

class CustomerService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Müşteri listesini getirir
  ///
  /// API endpoint: service/user/account/customers
  /// Method: POST
  /// 
  /// [userToken] Kullanıcı token bilgisi
  /// [compID] Şirket ID
  /// [searchText] Arama metni (boş gönderilebilir)
  Future<ApiResponseModel<CustomerListResponse>> getCustomers({
    required String userToken,
    required int compID,
    String searchText = '',
  }) async {
    try {
      final String url = '$_baseUrl${AppConstants.customersEndpoint}';

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };

      final Map<String, dynamic> requestBody = {
        'userToken': userToken,
        'compID': compID,
        'searchText': searchText,
      };

      debugPrint('🔵 [MÜŞTERİ LİSTESİ] İstek gönderiliyor: ${jsonEncode(requestBody)}');

      final httpResponse = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      debugPrint('🔵 [MÜŞTERİ LİSTESİ] HTTP yanıt kodu: ${httpResponse.statusCode}');
      
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      debugPrint('🔵 [MÜŞTERİ LİSTESİ] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      if (responseData == null) {
        debugPrint('🔴 [MÜŞTERİ LİSTESİ] Sunucudan veri alınamadı');
        return ApiResponseModel<CustomerListResponse>(
          error: true,
          success: false,
          errorCode: "Sunucudan veri alınamadı",
        );
      }
      
      if (httpResponse.statusCode == 200) {
        debugPrint('🟢 [MÜŞTERİ LİSTESİ] Başarılı (200): ${jsonEncode(responseData)}');
        if (responseData['success'] == true) {
          return ApiResponseModel.fromJson(
            responseData, 
            (data) => CustomerListResponse.fromJson(data),
          );
        } else {
          return ApiResponseModel<CustomerListResponse>(
            error: true,
            success: false,
            errorCode: responseData['message'] ?? "İşlem başarısız",
          );
        }
      } else if (httpResponse.statusCode == 410) {
        debugPrint('🟡 [MÜŞTERİ LİSTESİ] 410 Kodu Alındı: ${jsonEncode(responseData)}');
        return ApiResponseModel.fromJson(
          responseData, 
          (data) => CustomerListResponse.fromJson(data),
        );
      } else if (httpResponse.statusCode == 417) {
        debugPrint('🔴 [MÜŞTERİ LİSTESİ] 417 hatası alındı: ${jsonEncode(responseData)}');
        
        String errorMessage = "Sunucu beklentileri karşılanamadı (417)";
        if (responseData.containsKey('error_message')) {
          errorMessage = responseData['error_message'].toString();
        }
        
        return ApiResponseModel<CustomerListResponse>(
          error: true,
          success: false,
          errorCode: errorMessage,
        );
      } else if (httpResponse.statusCode == 401) {
        debugPrint('🔴 [MÜŞTERİ LİSTESİ] Yetkilendirme hatası (401): ${jsonEncode(responseData)}');
        return ApiResponseModel<CustomerListResponse>(
          error: true,
          success: false,
          errorCode: "Yetkilendirme hatası: Lütfen yeniden giriş yapın",
        );
      } else {
        debugPrint('🔴 [MÜŞTERİ LİSTESİ] Beklenmeyen hata kodu: ${httpResponse.statusCode}, Veri: ${jsonEncode(responseData)}');
        
        String errorMessage = "İşlem başarısız";
        if (responseData.containsKey('error_message')) {
          errorMessage = responseData['error_message'].toString();
        } else if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
        
        return ApiResponseModel<CustomerListResponse>(
          error: true,
          success: false,
          errorCode: "$errorMessage (HTTP ${httpResponse.statusCode})",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [MÜŞTERİ LİSTESİ] İSTİSNA: $e');
      debugPrint('🔴 [MÜŞTERİ LİSTESİ] STACK TRACE: $stackTrace');
      return ApiResponseModel<CustomerListResponse>(
        error: true,
        success: false,
        errorCode: "Müşteri listesi getirilirken hata: $e",
      );
    }
  }
} 