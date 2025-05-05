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
      
      // Ödeme türü ayrıca logla
      if (requestBody.containsKey('orderPayType')) {
        debugPrint('💳 [SİPARİŞ OLUŞTURMA] Ödeme Türü: ${requestBody['orderPayType']} (${requestBody['orderType'] != 1 ? 'Paket Sipariş' : 'Normal Sipariş'})');
      } else {
        debugPrint('⚠️ [SİPARİŞ OLUŞTURMA] DİKKAT: orderPayType isteğe eklenmemiş!');
      }
      
      // OrderType kontrolü
      if (requestBody.containsKey('orderType')) {
        debugPrint('🔄 [SİPARİŞ OLUŞTURMA] Sipariş Türü: ${requestBody['orderType']} ${requestBody['orderType'] == 2 ? '(Paket Sipariş)' : '(Normal Sipariş)'}');
      }
      
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
      
      // Yanıtta orderPayment kontrolü
      try {
        final responseData = jsonDecode(responseBody);
        if (responseData != null && responseData is Map && responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is Map && data.containsKey('orderPayment')) {
            debugPrint('💳 [SİPARİŞ OLUŞTURMA] Yanıtta orderPayment: ${data['orderPayment']}');
          } else {
            debugPrint('⚠️ [SİPARİŞ OLUŞTURMA] Yanıtta orderPayment bulunamadı!');
          }
        }
      } catch (e) {
        debugPrint('🔴 [SİPARİŞ OLUŞTURMA] Yanıt işlenirken hata: $e');
      }
      
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
      
      // "410": "Gone" alanını temizle - bu alan Map'in List olarak yorumlanmasına neden oluyor
      if (responseData.containsKey('410')) {
        responseData.remove('410');
        debugPrint('🔵 [SİPARİŞ DETAYI] "410" anahtarı yanıttan temizlendi');
      }
      
      // 200 veya 410 durum kodlarını başarılı olarak kabul et
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 410) {
        if (responseData['success'] == true) {
          debugPrint('🟢 [SİPARİŞ DETAYI] Başarılı (${httpResponse.statusCode}): ${jsonEncode(responseData)}');
          
          // Data null kontrolü yap
          if (responseData['data'] == null) {
            debugPrint('🟡 [SİPARİŞ DETAYI] Data alanı null, boş yanıt döndürülüyor');
            return ApiResponseModel<OrderDetail>(
              error: false,
              success: true,
              errorCode: null,
            );
          }
          
          try {
            final dynamic dataField = responseData['data'];
            
            // Data alanı List tipinde olabilir, bu durumda boş veri döndürülecek
            if (dataField is List) {
              debugPrint('🟡 [SİPARİŞ DETAYI] Data alanı bir liste, boş yanıt döndürülüyor');
              return ApiResponseModel<OrderDetail>(
                error: false,
                success: true,
                errorCode: "Veri yok",
              );
            }
            
            // Data alanı Map tipinde ise normal işleme devam et
            if (dataField is Map<String, dynamic>) {
              // ApiResponseModel.fromJson kullanarak veriyi dönüştür
              return ApiResponseModel<OrderDetail>.fromJson(
                responseData,
                (data) => OrderDetail.fromJson(data),
              );
            } else {
              debugPrint('🟡 [SİPARİŞ DETAYI] Data alanı beklenmeyen tipte: ${dataField.runtimeType}');
              return ApiResponseModel<OrderDetail>(
                error: false,
                success: true,
                errorCode: "Veri formatı geçersiz",
              );
            }
          } catch (e, stackTrace) {
            debugPrint('🔴 [SİPARİŞ DETAYI] Veri ayrıştırma hatası: $e');
            debugPrint('🔴 [SİPARİŞ DETAYI] Hata ayrıntıları: $stackTrace');
            return ApiResponseModel<OrderDetail>(
              error: true,
              success: false,
              errorCode: "Veri ayrıştırma hatası: $e",
            );
          }
        } else {
          debugPrint('🔴 [SİPARİŞ DETAYI] API başarısız yanıt döndü: ${jsonEncode(responseData)}');
          return ApiResponseModel<OrderDetail>(
            error: true,
            success: false,
            errorCode: responseData['message'] ?? "İşlem başarısız",
          );
        }
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
      
      // isRemove değerini logla
      if (requestBody.containsKey('isRemove')) {
        debugPrint('🔵 [SİPARİŞ GÜNCELLEME] Ürün çıkarma durumu: ${requestBody['isRemove'] == 1 ? "Evet" : "Hayır"}');
      } else {
        debugPrint('⚠️ [SİPARİŞ GÜNCELLEME] DİKKAT: isRemove parametresi isteğe eklenmemiş!');
      }
      
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

  Future<OrderModel> getOrderList({
    required String userToken,
    required int compID,
  }) async {
    const url = '${AppConstants.baseUrl}/service/user/order/orderList';
    
    try {
      debugPrint('🔵 [SİPARİŞ LİSTESİ] İstek başlatılıyor...');
      
      // SharedPreferences'tan token veya kimlik bilgilerini alarak header'ları hazırla
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString(AppConstants.tokenKey);
      
      debugPrint('🔵 [SİPARİŞ LİSTESİ] Token: ${savedToken ?? "Token bulunamadı"}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };
      
      // Eğer token varsa, header'a ekle
      if (savedToken != null && savedToken.isNotEmpty) {
        headers['X-Auth-Token'] = savedToken;
      }
      
      debugPrint('🔵 [SİPARİŞ LİSTESİ] Headers: $headers');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'userToken': userToken,
          'compID': compID,
        }),
      );
      
      debugPrint('🔵 [SİPARİŞ LİSTESİ] HTTP yanıt kodu: ${response.statusCode}');
      
      // UTF-8 karakter kodlamasını kullan
      final String responseBody = utf8.decode(response.bodyBytes);
      debugPrint('🔵 [SİPARİŞ LİSTESİ] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      
      // Tüm olası yanıt kodlarını işle
      if (response.statusCode == 200 || response.statusCode == 410) {
        if (responseData['success'] == true) {
          return OrderModel.fromJson(responseData);
        } else {
          throw Exception('Veri alınamadı: ${responseData['message'] ?? 'Bilinmeyen hata'}');
        }
      } else if (response.statusCode == 417) {
        debugPrint('🔵 [SİPARİŞ LİSTESİ] Sipariş yok mesajı (417)');
        // Bu özel durum için bir OrderModel döndür, ancak boş liste ile
        return OrderModel(orders: []);
      } else if (response.statusCode == 401) {
        debugPrint('🔴 [SİPARİŞ LİSTESİ] Yetkilendirme hatası (401)');
        // Token ile ilgili sorun olabilir, token'ı temizle
        await prefs.remove(AppConstants.tokenKey);
        throw Exception('Oturum süresi dolmuş olabilir. Lütfen yeniden giriş yapın.');
      } else {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 [SİPARİŞ LİSTESİ] Hata: $e');
      throw Exception('Sipariş listesi alınırken hata oluştu: $e');
    }
  }

  /// Siparişe ürün ekler
  ///
  /// API endpoint: service/user/order/addProduct
  /// Method: POST
  Future<ApiResponseModel<AddProductResponse>> addProductToOrder({
    required String userToken,
    required int compID,
    required int orderID,
    required int productID,
    required int quantity,
    String? proNote,
    int isGift = 0,
    int orderPayType = 0,
  }) async {
    try {
      debugPrint('🔵 [SİPARİŞE ÜRÜN EKLEME] Başlatılıyor...');
      final url = '${AppConstants.baseUrl}service/user/order/addProduct';
      
      final Map<String, dynamic> requestBody = {
        'userToken': userToken,
        'compID': compID,
        'orderID': orderID,
        'proID': productID,
        'proQty': quantity,
        'proNote': proNote ?? '',
        'isGift': isGift,
        'orderPayType': orderPayType,
      };
      
      // İstek gövdesini logla
      debugPrint('🔵 [SİPARİŞE ÜRÜN EKLEME] İstek gövdesi: ${jsonEncode(requestBody)}');
      
      // SharedPreferences'tan token veya kimlik bilgilerini alarak header'ları hazırla
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString(AppConstants.tokenKey);
      
      debugPrint('🔵 [SİPARİŞE ÜRÜN EKLEME] Token: ${savedToken ?? "Token bulunamadı"}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };
      
      // Eğer token varsa, header'a ekle
      if (savedToken != null && savedToken.isNotEmpty) {
        headers['X-Auth-Token'] = savedToken;
      }
      
      debugPrint('🔵 [SİPARİŞE ÜRÜN EKLEME] Headers: $headers');
      debugPrint('🔵 [SİPARİŞE ÜRÜN EKLEME] API isteği gönderiliyor: $url');
      
      final httpResponse = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      debugPrint('🔵 [SİPARİŞE ÜRÜN EKLEME] HTTP yanıt kodu: ${httpResponse.statusCode}');
      
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      debugPrint('🔵 [SİPARİŞE ÜRÜN EKLEME] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      
      // HTTP durum kodunu kontrol et
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 410) {
        debugPrint('🟢 [SİPARİŞE ÜRÜN EKLEME] Başarılı: ${jsonEncode(responseData)}');
        return ApiResponseModel.fromJson(
          responseData, 
          (data) => AddProductResponse.fromJson(data),
        );
      } else {
        debugPrint('🔴 [SİPARİŞE ÜRÜN EKLEME] Hata: ${httpResponse.statusCode}, Veri: ${jsonEncode(responseData)}');
        return ApiResponseModel<AddProductResponse>(
          error: true,
          success: false,
          errorCode: responseData['message'] ?? "İşlem başarısız: HTTP ${httpResponse.statusCode}",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SİPARİŞE ÜRÜN EKLEME] İSTİSNA: $e');
      debugPrint('🔴 [SİPARİŞE ÜRÜN EKLEME] STACK TRACE: $stackTrace');
      return ApiResponseModel<AddProductResponse>(
        error: true,
        success: false,
        errorCode: "Siparişe ürün eklenirken hata: $e",
      );
    }
  }

  /// Sipariş tamamla işlemi (Gel Al ve Paket siparişler için)
  ///
  /// API endpoint: service/user/order/complated
  /// Method: POST
  Future<ApiResponseModel<dynamic>> completeOrder({
    required String userToken,
    required int compID,
    required int orderID,
  }) async {
    try {
      debugPrint('🔵 [SİPARİŞ TAMAMLAMA] Başlatılıyor...');
      final url = '${AppConstants.baseUrl}service/user/order/complated';
      
      final Map<String, dynamic> requestBody = {
        'userToken': userToken,
        'compID': compID,
        'orderID': orderID,
      };
      
      // İstek gövdesini logla
      debugPrint('🔵 [SİPARİŞ TAMAMLAMA] İstek gövdesi: ${jsonEncode(requestBody)}');
      
      // SharedPreferences'tan token veya kimlik bilgilerini alarak header'ları hazırla
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString(AppConstants.tokenKey);
      
      debugPrint('🔵 [SİPARİŞ TAMAMLAMA] Token: ${savedToken ?? "Token bulunamadı"}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
      };
      
      // Eğer token varsa, header'a ekle
      if (savedToken != null && savedToken.isNotEmpty) {
        headers['X-Auth-Token'] = savedToken;
      }
      
      debugPrint('🔵 [SİPARİŞ TAMAMLAMA] Headers: $headers');
      debugPrint('🔵 [SİPARİŞ TAMAMLAMA] API isteği gönderiliyor: $url');
      
      final httpResponse = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      debugPrint('🔵 [SİPARİŞ TAMAMLAMA] HTTP yanıt kodu: ${httpResponse.statusCode}');
      
      final String responseBody = utf8.decode(httpResponse.bodyBytes);
      debugPrint('🔵 [SİPARİŞ TAMAMLAMA] HTTP yanıt gövdesi: $responseBody');
      
      final responseData = jsonDecode(responseBody);
      
      // "410": "Gone" alanını temizle - bu alan Map'in List olarak yorumlanmasına neden oluyor
      if (responseData.containsKey('410')) {
        responseData.remove('410');
        debugPrint('🔵 [SİPARİŞ TAMAMLAMA] "410" anahtarı yanıttan temizlendi');
      }
      
      // HTTP durum kodunu kontrol et
      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 410) {
        debugPrint('🟢 [SİPARİŞ TAMAMLAMA] Başarılı: ${jsonEncode(responseData)}');
        return ApiResponseModel<dynamic>(
          error: false,
          success: true,
          errorCode: null,
          successMessage: responseData['success_message'] ?? 'Sipariş başarıyla tamamlandı',
        );
      } else {
        debugPrint('🔴 [SİPARİŞ TAMAMLAMA] Hata: ${httpResponse.statusCode}, Veri: ${jsonEncode(responseData)}');
        return ApiResponseModel<dynamic>(
          error: true,
          success: false,
          errorCode: responseData['message'] ?? "İşlem başarısız: HTTP ${httpResponse.statusCode}",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [SİPARİŞ TAMAMLAMA] İSTİSNA: $e');
      debugPrint('🔴 [SİPARİŞ TAMAMLAMA] STACK TRACE: $stackTrace');
      return ApiResponseModel<dynamic>(
        error: true,
        success: false,
        errorCode: "Sipariş tamamlanırken hata oluştu: $e",
      );
    }
  }

} 