import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:pos701/models/statistics_model.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/services/api_service.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/utils/app_logger.dart';

class StatisticsService {
  final ApiService _apiService;
  final AppLogger _logger = AppLogger();

  StatisticsService(this._apiService) {
    _logger.i('StatisticsService başlatıldı');
  }

  Future<ApiResponseModel<StatisticsModel>> getStatistics(int compID) async {
    try {
      _logger.d('İstatistik verileri alınıyor. CompID: $compID');
      
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        _logger.w('Token bulunamadı veya geçersiz');
        return ApiResponseModel<StatisticsModel>(
          error: true,
          success: false,
          errorCode: 'Token bulunamadı veya geçersiz. Lütfen tekrar giriş yapın.',
        );
      }
      
      // Yeni bir Dio örneği oluştur ve Basic Auth ile yapılandır
      final dio = Dio();
      dio.options.baseUrl = AppConstants.baseUrl;
      dio.options.connectTimeout = const Duration(seconds: 15); // Zaman aşımını artır
      dio.options.receiveTimeout = const Duration(seconds: 15); // Zaman aşımını artır
      
      // Basic Auth bilgilerini daha güvenli bir şekilde oluştur
      final credentials = '${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}';
      final encodedCredentials = base64Encode(utf8.encode(credentials));
      final basicAuthHeader = 'Basic $encodedCredentials';
      
      _logger.d('Kimlik doğrulama bilgileri hazırlandı');
      
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': basicAuthHeader,
        'Connection': 'keep-alive',
        'User-Agent': 'POS701/${AppConstants.appVersion}',
      };
      
      // API'nin özel durum kodlarını başarılı kabul et
      dio.options.validateStatus = (status) {
        return (status != null && (status >= 200 && status < 300)) || status == 410 || status == 417;
      };
      
      final data = {
        "userToken": token,
        "compID": compID
      };
      
      _logger.d('İstatistik verisi isteği hazırlandı');
      
      final endpoint = 'service/user/account/statistics';
      
      // Retry mekanizması ekle
      Response? response;
      int retryCount = 0;
      int maxRetries = 2;
      
      while (retryCount <= maxRetries) {
        try {
          _logger.d('İstatistik verisi isteği gönderiliyor (Deneme: ${retryCount + 1}): $data');
          response = await dio.put(endpoint, data: jsonEncode(data));
          break; // Başarılı olursa döngüden çık
        } catch (e) {
          retryCount++;
          if (retryCount > maxRetries) {
            throw e; // Tüm denemeler başarısız olursa hatayı fırlat
          }
          
          _logger.w('İstek başarısız oldu. Yeniden deneniyor (${retryCount}/${maxRetries})');
          await Future.delayed(Duration(milliseconds: 500 * retryCount)); // Her denemede bekle
        }
      }
      
      if (response == null) {
        throw Exception('API yanıtı alınamadı (tüm denemeler başarısız)');
      }
      
      int statusCode = response.statusCode ?? 0;
      String statusMessage = response.statusMessage ?? 'Durum mesajı yok';
      
      _logger.d('İstatistik yanıtı alındı. Status: $statusCode');
      _logger.d('HTTP Durum Kodu: $statusCode - $statusMessage');
      _logger.d('Yanıt Başlıkları: ${response.headers}');
      
      // Ham yanıt içeriğini loglayalım
      _logger.d('Ham yanıt tipi: ${response.data.runtimeType}');
      _logger.d('Ham yanıt içeriği: ${response.data}');
      
      // 401 durum kodu özel işleme - bu durumda yetkilendirme hatası var
      if (response.statusCode == 401) {
        final message = response.data is String 
            ? response.data 
            : 'Yetkisiz erişim hatası';
        _logger.w('HTTP 401 hatası: $message');
        
        return ApiResponseModel<StatisticsModel>(
          error: true,
          success: false,
          errorCode: message,
        );
      }
      
      // 417 durum kodu için özel işleme - yetkilendirme hatası
      if (response.statusCode == 417) {
        final message = response.data is String 
            ? response.data 
            : 'Yetkisiz erişim hatası (417)';
        _logger.w('HTTP 417 hatası: $message');
        
        return ApiResponseModel<StatisticsModel>(
          error: true,
          success: false,
          errorCode: 'Yetkisiz erişim: $message',
        );
      }
      
      // Yanıt formatını kontrol et ve işle
      Map<String, dynamic> responseData;
      
      try {
        // Önce yanıt tipini kontrol et
        if (response.data is String) {
          // String yanıtı JSON'a dönüştür
          responseData = jsonDecode(response.data);
        } else if (response.data is Map) {
          // Zaten Map ise doğrudan kullan
          responseData = Map<String, dynamic>.from(response.data);
        } else {
          throw FormatException('Beklenmeyen yanıt formatı: ${response.data.runtimeType}');
        }
        
        // API yanıtında özel durum kodu var mı kontrol et (410 Gone, vb.)
        bool hasSpecialStatusCode = false;
        String specialStatusInfo = "";
        
        // HTTP durum kodu doğrudan anahtarda bulunuyor mu?
        if (responseData.containsKey('200') || responseData.containsKey('410')) {
          String statusKey = responseData.containsKey('410') ? '410' : '200';
          specialStatusInfo = "HTTP $statusKey: ${responseData[statusKey]}";
          _logger.d('Özel durum kodu bulundu: $specialStatusInfo');
          hasSpecialStatusCode = true;
        }
        
        // Yanıtın yapısını detaylı log'la
        _logger.d('API yanıt yapısı: ${responseData.keys.toList()}');
        _logger.d('API yanıtının tam içeriği: $responseData');
        
        // Yanıtta veri olması gerektiği halde yoksa
        if (responseData.containsKey('data') && responseData['data'] == null) {
          // 410 koduna sahipse veya yanıtın kendisi 410 ise özel olarak işle
          if (responseData.containsKey('410') || statusCode == 410) {
            responseData['errorCode'] = 'API 410 Gone durumu döndürdü: Veriler kullanılamıyor';
            _logger.w('API 410 Gone durumu: $responseData');
          } else {
            responseData['error'] = true;
            responseData['success'] = false;
            responseData['errorCode'] = 'API yanıtı boş data döndürdü';
            _logger.w('API yanıtında data null: $responseData');
          }
        }
        
        // Yanıt içinde istatistik verilerinin doğrudan olup olmadığını kontrol et
        if (!responseData.containsKey('data') && responseData.containsKey('statistics')) {
          // Eğer data yoksa ama statistics varsa, responseData'yı yeniden yapılandır
          responseData = {
            'error': false,
            'success': true,
            'data': responseData,
            '410': responseData.containsKey('410') ? responseData['410'] : null
          };
          _logger.d('Yeniden yapılandırılmış yanıt: $responseData');
        }
        
        // Eğer yalnızca özel durum kodu içeriyorsa ve başka veri yoksa
        if (responseData.keys.length <= 2 && 
            (responseData.containsKey('200') || responseData.containsKey('410') || 
             responseData.containsKey('error') || responseData.containsKey('success'))) {
          
          _logger.w('API sadece durum kodu içeriyor, veri yok. İçerik: $responseData');
          String durum = responseData.containsKey('410') ? '410 Gone' : 
                        (responseData.containsKey('200') ? '200 OK' : 'Bilinmeyen durum');
          
          // 200 OK durumuna özel işleme (API veri dönmüyor ama 200 OK durumu)
          if (durum == '200 OK') {
            responseData = {
              'error': true,
              'success': false,
              'errorCode': 'API veri döndürmüyor fakat başarılı HTTP kodu döndürüyor (200 OK). Bu bir backend sorunu olabilir.',
              'data': null,
              'statusCode': durum
            };
            _logger.w('Backend sorunu olabilir - API veri döndürmüyor, sadece başarı durumu döndürüyor: 200 OK');
            
            // Bu durumu backend ekibine bildirmek için alternatif bir istek yapabiliriz (opsiyonel)
            try {
              _logger.i('İstatistik servisi durum kontrolü yapılıyor...');
              // Burada alternatif bir endpoint veya debug endpoint'i çağrılabilir
              
              // Token ve kullanıcı bilgilerini logla
              _logger.i('Kullanıcı token: $token, CompID: $compID');
              
              // API durumunu belirlemek için diğer bilgileri de logla
              final currentTime = DateTime.now().toIso8601String();
              _logger.i('API isteği zamanı: $currentTime');
              _logger.i('Endpoint: service/user/account/statistics');
            } catch (e) {
            }
          } else {
            responseData = {
              'error': false,
              'success': false,
              'errorCode': 'API sadece durum kodu döndürdü: $durum - Veri yok',
              'data': null,
              'statusCode': durum
            };
          }
        }
        
      } catch (e) {
        _logger.e('API yanıtı işlenirken format hatası: $e. Yanıt: ${response.data}');
        return ApiResponseModel<StatisticsModel>(
          error: true,
          success: false,
          errorCode: 'API yanıtı format hatası: ${e.toString()}',
        );
      }
      
      _logger.d('İşlenmiş yanıt verisi: $responseData');
      
      try {
        final apiResponse = ApiResponseModel<StatisticsModel>.fromJson(
          responseData,
          (data) => StatisticsModel.fromJson(data),
        );
        
        // HTTP durum kodunu ve mesajını ekleyelim
        final responseWithStatusInfo = ApiResponseModel<StatisticsModel>(
          error: apiResponse.error,
          success: apiResponse.success,
          data: apiResponse.data,
          errorCode: apiResponse.errorCode != null 
              ? "${apiResponse.errorCode} (HTTP: $statusCode - $statusMessage)" 
              : "HTTP: $statusCode - $statusMessage"
        );
        
        if (responseWithStatusInfo.success && responseWithStatusInfo.data != null) {
          _logger.i('İstatistik verileri başarıyla alındı');
        } else {
          // Daha detaylı hata mesajı oluştur
          String hataMesaji = responseWithStatusInfo.errorCode ?? "Bilinmeyen hata: API başarısız yanıt döndü fakat hata kodu yok";
          if (responseWithStatusInfo.data == null && responseWithStatusInfo.success) {
            hataMesaji = "Başarılı yanıt alındı fakat veri yok (HTTP: $statusCode - $statusMessage)";
          }
          _logger.w('İstatistik verileri alınamadı. Yanıt: $hataMesaji');
          _logger.d('Ham yanıt içeriği: $responseData');
        }
        
        return responseWithStatusInfo;
      } catch (parseError) {
        _logger.e('API yanıtı işlenirken hata: $parseError', parseError);
        
        // Hata mesajını daha ayrıntılı hale getir
        var errorDetails = parseError.toString();
        if (parseError is TypeError) {
          errorDetails = 'Tip uyumsuzluğu hatası: $parseError. Yanıt: $responseData';
        }
        
        return ApiResponseModel<StatisticsModel>(
          error: true,
          success: false,
          errorCode: 'API yanıtı işleme hatası: $errorDetails',
        );
      }
    } catch (e) {
      _logger.e('İstatistik verileri alınırken hata oluştu', e);
      return ApiResponseModel<StatisticsModel>(
        error: true,
        success: false,
        errorCode: e.toString(),
      );
    }
  }
} 