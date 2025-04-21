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
      if (token == null) {
        _logger.w('Token bulunamadı');
        return ApiResponseModel<StatisticsModel>(
          error: true,
          success: false,
          errorCode: 'Token bulunamadı',
        );
      }
      
      // Yeni bir Dio örneği oluştur ve Basic Auth ile yapılandır
      final dio = Dio();
      dio.options.baseUrl = AppConstants.baseUrl;
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      
      // Basic Auth header oluştur
      final credentials = '${AppConstants.basicAuthUsername}:${AppConstants.basicAuthPassword}';
      final encodedCredentials = base64Encode(utf8.encode(credentials));
      final basicAuthHeader = 'Basic $encodedCredentials';
      
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': basicAuthHeader,
      };
      
      // API'nin 401 ve 410 durum kodlarını başarılı kabul et
      dio.options.validateStatus = (status) {
        return (status != null && (status >= 200 && status < 300)) || status == 410;
      };
      
      final data = {
        "userToken": token,
        "compID": compID
      };
      
      _logger.d('İstatistik verisi isteği gönderiliyor: $data');
      
      final endpoint = 'service/user/account/statistics';
      final response = await dio.post(endpoint, data: jsonEncode(data));
      
      _logger.d('İstatistik yanıtı alındı. Status: ${response.statusCode}');
      _logger.d('HTTP Durum Kodu: ${response.statusCode} - ${response.statusMessage}');
      _logger.d('Yanıt Başlıkları: ${response.headers}');
      
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
      
      // 410 durum kodu için özel işlem
      if (response.statusCode == 410) {
        _logger.i('HTTP 410 durum kodu alındı. Bu API için normal bir yanıt.');
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
        
        // Yanıtın yapısını detaylı log'la
        _logger.d('API yanıt yapısı: ${responseData.keys.toList()}');
        _logger.d('API yanıtının tam içeriği: $responseData');
        
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
        
        // Yanıt "data" içeriyorsa ama "data" null ise, hata mesajı ekle
        if (responseData.containsKey('data') && responseData['data'] == null) {
          responseData['error'] = true;
          responseData['success'] = false;
          responseData['errorCode'] = 'API yanıtı boş data döndürdü';
          _logger.w('API yanıtında data null: $responseData');
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
        
        if (apiResponse.success && apiResponse.data != null) {
          _logger.i('İstatistik verileri başarıyla alındı');
        } else {
          // Daha detaylı hata mesajı oluştur
          String hataMesaji = apiResponse.errorCode ?? "Bilinmeyen hata: API başarısız yanıt döndü fakat hata kodu yok";
          if (apiResponse.data == null && apiResponse.success) {
            hataMesaji = "Başarılı yanıt alındı fakat veri yok";
          }
          _logger.w('İstatistik verileri alınamadı. Yanıt: $hataMesaji');
          _logger.d('Ham yanıt içeriği: $responseData');
        }
        
        return apiResponse;
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