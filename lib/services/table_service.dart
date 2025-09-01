import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pos701/models/table_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/main.dart';
import 'package:pos701/views/login_view.dart';
import 'package:pos701/viewmodels/company_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos701/services/connectivity_service.dart';

class TableService {
  Future<TablesResponse> getTables({
    required String userToken,
    required int compID,
  }) async {
    try {
      // Eğer boş değer gelmişse SharedPreferences'tan otomatik tamamla
      if (userToken.isEmpty || compID == 0) {
        final prefs = await SharedPreferences.getInstance();
        final String? storedToken = prefs.getString(AppConstants.tokenKey);
        final int? storedCompId = prefs.getInt(AppConstants.companyIdKey);
        if (userToken.isEmpty && storedToken != null) {
          userToken = storedToken;
        }
        if (compID == 0 && storedCompId != null) {
          compID = storedCompId;
        }
      }

      final String primaryUrl = '${AppConstants.baseUrl}${AppConstants.getTablesEndpoint}';
      final String fallbackUrl = '${AppConstants.localFallbackBaseUrl}${AppConstants.getTablesJsonEndpoint}';
      debugPrint('API isteği (primary): $primaryUrl');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
      };
      debugPrint('İstek verileri: $requestBody');
      
      http.Response? response;

      // Önce internet var mı kontrol et
      final bool hasInternet = await ConnectivityService().hasInternetConnection();

      if (hasInternet) {
        // Online ise ana endpointi dene; hata fırlarsa fallback uygula
        try {
          response = await http.put(
            Uri.parse(primaryUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
            },
            body: jsonEncode(requestBody),
          );
          debugPrint('Yanıt kodu (primary): ${response.statusCode}');
          debugPrint('Yanıt içeriği (primary): ${response.body}');

          // Başarılı değilse fallback dene
          if (!(response.statusCode == 410 || response.statusCode == 200)) {
            debugPrint('Primary başarısız. Fallback URL deneniyor: $fallbackUrl');
            response = await http.get(
              Uri.parse(fallbackUrl),
              headers: {
                'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
              },
            );
            debugPrint('Yanıt kodu (fallback): ${response.statusCode}');
            debugPrint('Yanıt içeriği (fallback): ${response.body}');
            CompanyViewModel.instance.setOffline();
          }
        } catch (primaryError) {
          // Örn. TLS/CERT hatası vs. durumda doğrudan fallback dene
          debugPrint('Primary istek hata verdi: $primaryError. Fallback URL deneniyor: $fallbackUrl');
          response = await http.get(
            Uri.parse(fallbackUrl),
            headers: {
              'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
            },
          );
          debugPrint('Yanıt kodu (fallback-ex): ${response.statusCode}');
          debugPrint('Yanıt içeriği (fallback-ex): ${response.body}');
          CompanyViewModel.instance.setOffline();
        }
      } else {
        // İnternet yoksa direkt fallback dene
        debugPrint('İnternet yok. Doğrudan fallback URL deneniyor: $fallbackUrl');
        response = await http.get(
          Uri.parse(fallbackUrl),
          headers: {
            'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
          },
        );
        debugPrint('Yanıt kodu (fallback-offline): ${response.statusCode}');
        debugPrint('Yanıt içeriği (fallback-offline): ${response.body}');
        CompanyViewModel.instance.setOffline();
      }
      
      debugPrint('Yanıt kodu: ${response.statusCode}');
      debugPrint('Yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 410 || response.statusCode == 200) {
        // Başarılı API yanıtı - CompanyViewModel'i online yap
        if (hasInternet && response.request?.url.toString() == primaryUrl) {
          CompanyViewModel.instance.setOnline();
        }
        
        final Map<String, dynamic> data = jsonDecode(response.body);
        return TablesResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        debugPrint('403 hatası yakalandı. Token temizleniyor ve login sayfasına yönlendiriliyor.');
        await _handle403Error();
        throw Exception('Geçersiz token. Üye doğrulama bilgileri hatalı.');
      } else {
        // Diğer hata durumları - CompanyViewModel'i offline yap
        CompanyViewModel.instance.setOffline();
        throw Exception('Sunucu hatası: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      // Exception durumunda CompanyViewModel'i offline yap
      CompanyViewModel.instance.setOffline();
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
    required String step,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.tableOrderMergeEndpoint}';
      debugPrint('Masa ${step == "merged" ? "birleştirme" : "ayırma"} API isteği: $url');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        'tableID': tableID,
        'orderID': orderID,
        'step': step, // "merged" veya "unmerged"
        'mergeTables': mergeTables.map((id) => id.toString()).toList(),
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
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Loglamayı genişlet - başarılı veya başarısız yanıtları detaylı göster
        final success = responseData['success'] ?? false;
        debugPrint('🔄 ${step == "merged" ? "Birleştirme" : "Ayırma"} işlemi: ${success ? "Başarılı ✅" : "Başarısız ❌"}');
        
        // Hata durumunda hata mesajını detaylı göster
        if (!success) {
          final errorMessage = responseData['error_message'] ?? 'Bilinmeyen hata';
          debugPrint('❌ Hata detayı: $errorMessage');
        }
        
        // Başarılı yanıtta dönen veriyi incele - veri yapısını anlamak için
        if (success && responseData.containsKey('data')) {
          final data = responseData['data'];
          debugPrint('📊 Dönen veri yapısı: ${data.runtimeType}');
          
          if (data is Map) {
            // Mevcut sipariş verilerini göster
            if (data.containsKey('order')) {
              final order = data['order'];
              
              // Birleştirilmiş masa bilgilerini ara
              if (order is Map && order.containsKey('mergeTables')) {
              }
            }
          }
        }
        
        return responseData;
      } else {
        return {
          'success': false,
          'error_message': 'HTTP error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Masa ${step == "merged" ? "birleştirme" : "ayırma"} işlemi sırasında hata: $e');
      return {
        'success': false,
        'error_message': e.toString(),
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
      debugPrint('🌐 Adisyon aktarım API isteği: $url');
      
      final requestBody = {
        'userToken': userToken,
        'compID': compID,
        'oldOrderID': oldOrderID,
        'newOrderID': newOrderID,
      };
      debugPrint('📤 Adisyon aktarım istek verileri: $requestBody');
      
      // API yanıt süresini ölçmek için başlangıç zamanı
      final startTime = DateTime.now();
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode(requestBody),
      );
      
      // API yanıt süresini hesapla
      final duration = DateTime.now().difference(startTime);
      debugPrint('⏱️ Adisyon aktarım API yanıt süresi: ${duration.inMilliseconds}ms');
      
      debugPrint('📊 Adisyon aktarım yanıt kodu: ${response.statusCode}');
      
      // Yanıt başarılı olmasa bile içeriği logla
      debugPrint('📋 Adisyon aktarım yanıt içeriği: ${response.body}');
      
      if (response.statusCode == 410 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Yanıtı daha detaylı logla
        final success = responseData['success'] ?? false;
        final message = responseData['success_message'] ?? responseData['error_message'] ?? 'Bilinmeyen yanıt';
        
        debugPrint('${success ? "✅" : "❌"} Adisyon aktarım sonucu: $message');
        
        // İşlem başarılıysa, yanıttaki ürün detaylarını da loglamaya çalış
        if (success && responseData.containsKey('data') && responseData['data'] != null) {
          try {
            final data = responseData['data'];
            if (data is Map && data.containsKey('products')) {
              final products = data['products'];
              if (products is List) {
                debugPrint('📦 Aktarılan ürünler: ${products.length} adet');
                
                // Ürün miktarlarının toplamını hesapla
                int totalQty = 0;
                for (var product in products) {
                  if (product is Map && product.containsKey('proQty')) {
                    totalQty += (product['proQty'] as num).toInt();
                  }
                }
                debugPrint('📦 Aktarılan toplam ürün miktarı: $totalQty');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Ürün detayları loglama hatası: $e');
          }
        }
        
        return responseData;
      } else if (response.statusCode == 401) {
        debugPrint('🔒 Adisyon aktarım yetkilendirme hatası (401)');
        return {
          'success': false,
          'error_message': 'Yetkilendirme hatası: Lütfen tekrar giriş yapın.',
        };
      } else {
        debugPrint('⛔ Adisyon aktarım sunucu hatası: ${response.statusCode}');
        return {
          'success': false,
          'error_message': 'Sunucu hatası: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('🔴 Adisyon aktarım işlemi sırasında hata: $e');
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

  Future<Map<String, dynamic>> partPay({
    required String userToken,
    required int compID,
    required int orderID,
    required int opID,
    required int opQty,
    required int payType,
  }) async {
    try {
      final url = "${AppConstants.baseUrl}service/user/order/payment/partPay";
      
      final requestBody = {
        "userToken": userToken,
        "compID": compID,
        "orderID": orderID,
        "opID": opID,
        "opQty": opQty,
        "payType": payType
      };
      
      debugPrint('📤 Parçalı ödeme gönderiliyor: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('📥 Parçalı ödeme yanıtı alındı: ${response.statusCode}');
      
      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      debugPrint('Parçalı ödeme işlemi sırasında hata: $e');
      return {
        'success': false,
        'error_message': 'İstek gönderilirken bir hata oluştu: $e',
      };
    }
  }
  
  /// Sipariş iptal etme metodu
  Future<Map<String, dynamic>> cancelOrder({
    required String userToken,
    required int compID,
    required int orderID,
    String? cancelDesc,
  }) async {
    try {
      final url = "${AppConstants.baseUrl}service/user/order/cancel";
      
      final requestBody = {
        "userToken": userToken,
        "compID": compID,
        "orderID": orderID,
        if (cancelDesc != null && cancelDesc.isNotEmpty) "cancelDesc": cancelDesc
      };
      
      debugPrint('📤 Sipariş iptali gönderiliyor: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}'))}',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('📥 Sipariş iptali yanıtı alındı: ${response.statusCode}');
      debugPrint('📄 Yanıt içeriği: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      debugPrint('Sipariş iptali sırasında hata: $e');
      return {
        'success': false,
        'error_message': 'İstek gönderilirken bir hata oluştu: $e',
      };
    }
  }
  
  /// 403 hatası durumunda token temizleme ve login sayfasına yönlendirme
  Future<void> _handle403Error() async {
    try {
      debugPrint('403 hatası yakalandı. Token temizleniyor ve login sayfasına yönlendiriliyor.');
      
      // Token'ı temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.companyIdKey);
      
      // Login sayfasına yönlendir
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        // Mevcut tüm route'ları temizle ve login sayfasına yönlendir
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
        
        // Kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('403 hatası işlenirken hata oluştu: $e');
    }
  }
}