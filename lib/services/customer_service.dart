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

  /// Yeni müşteri ekler
  ///
  /// API endpoint: service/user/account/customers/addCust
  /// Method: POST
  /// 
  /// [userToken] Kullanıcı token bilgisi
  /// [compID] Şirket ID
  /// [custName] Müşteri adı
  /// [custPhone] Müşteri telefonu (05555555555 formatında olmalı)
  /// [custAdrs] Müşteri adresleri (opsiyonel)
  Future<ApiResponseModel<Customer>> addCustomer({
    required String userToken,
    required int compID,
    required String custName,
    required String custPhone,
    List<Map<String, dynamic>> custAdrs = const [],
  }) async {
    try {
      final String url = '$_baseUrl${AppConstants.addCustomerEndpoint}';

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };

      final Map<String, dynamic> requestBody = {
        'userToken': userToken,
        'compID': compID,
        'custName': custName,
        'custPhone': custPhone,
        'custAdrs': custAdrs,
      };

      debugPrint('🔵 [MÜŞTERİ EKLE] İstek URL: $url');
      debugPrint('🔵 [MÜŞTERİ EKLE] İstek başlıkları: ${headers.toString()}');
      debugPrint('🔵 [MÜŞTERİ EKLE] İstek gönderiliyor: ${jsonEncode(requestBody)}');

      final httpResponse = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      debugPrint('🔵 [MÜŞTERİ EKLE] HTTP yanıt kodu: ${httpResponse.statusCode}');
      
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      debugPrint('🔵 [MÜŞTERİ EKLE] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      if (responseData == null) {
        debugPrint('🔴 [MÜŞTERİ EKLE] Sunucudan veri alınamadı');
        return ApiResponseModel<Customer>(
          error: true,
          success: false,
          errorCode: "Sunucudan veri alınamadı",
        );
      }
      
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        debugPrint('🟢 [MÜŞTERİ EKLE] Başarılı (${httpResponse.statusCode}): ${jsonEncode(responseData)}');
        if (responseData['success'] == true) {
          // Başarılı yanıtı işle
          final customerData = responseData['data'];
          if (customerData != null) {
            return ApiResponseModel<Customer>(
              error: false,
              success: true,
              data: Customer.fromJson(customerData),
            );
          } else {
            return ApiResponseModel<Customer>(
              error: false,
              success: true,
              data: Customer(
                custID: 0,
                custCode: '',
                custName: custName,
                custEmail: '',
                custPhone: custPhone,
                custPhone2: '',
                addresses: [],
              ),
            );
          }
        } else {
          return ApiResponseModel<Customer>(
            error: true,
            success: false,
            errorCode: responseData['message'] ?? "İşlem başarısız",
          );
        }
      } else if (httpResponse.statusCode == 410) {
        debugPrint('🟡 [MÜŞTERİ EKLE] 410 Kodu Alındı: ${jsonEncode(responseData)}');
        if (responseData['success'] == true) {
          // Başarılı yanıtı işle
          final customerData = responseData['data'];
          if (customerData != null) {
            return ApiResponseModel<Customer>(
              error: false,
              success: true,
              data: Customer.fromJson(customerData),
            );
          } else {
            return ApiResponseModel<Customer>(
              error: false,
              success: true,
              data: Customer(
                custID: 0,
                custCode: '',
                custName: custName,
                custEmail: '',
                custPhone: custPhone,
                custPhone2: '',
                addresses: [],
              ),
            );
          }
        } else {
          return ApiResponseModel<Customer>(
            error: true,
            success: false,
            errorCode: responseData['message'] ?? "İşlem başarısız",
          );
        }
      } else if (httpResponse.statusCode == 417) {
        debugPrint('🔴 [MÜŞTERİ EKLE] 417 hatası alındı: ${jsonEncode(responseData)}');
        
        String errorMessage = "Sunucu beklentileri karşılanamadı (417)";
        if (responseData.containsKey('error_message')) {
          errorMessage = responseData['error_message'].toString();
        }
        
        return ApiResponseModel<Customer>(
          error: true,
          success: false,
          errorCode: errorMessage,
        );
      } else if (httpResponse.statusCode == 401) {
        debugPrint('🔴 [MÜŞTERİ EKLE] Yetkilendirme hatası (401): ${jsonEncode(responseData)}');
        return ApiResponseModel<Customer>(
          error: true,
          success: false,
          errorCode: "Yetkilendirme hatası: Lütfen yeniden giriş yapın",
        );
      } else {
        debugPrint('🔴 [MÜŞTERİ EKLE] Beklenmeyen hata kodu: ${httpResponse.statusCode}, Veri: ${jsonEncode(responseData)}');
        
        String errorMessage = "İşlem başarısız";
        if (responseData.containsKey('error_message')) {
          errorMessage = responseData['error_message'].toString();
        } else if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }
        
        return ApiResponseModel<Customer>(
          error: true,
          success: false,
          errorCode: "$errorMessage (HTTP ${httpResponse.statusCode})",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [MÜŞTERİ EKLE] İSTİSNA: $e');
      debugPrint('🔴 [MÜŞTERİ EKLE] STACK TRACE: $stackTrace');
      return ApiResponseModel<Customer>(
        error: true,
        success: false,
        errorCode: "Müşteri eklenirken hata: $e",
      );
    }
  }
} 