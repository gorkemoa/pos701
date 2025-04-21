import 'package:pos701/utils/app_logger.dart';

class ApiResponseModel<T> {
  final bool error;
  final bool success;
  final T? data;
  final String? errorCode;

  ApiResponseModel({
    required this.error,
    required this.success,
    this.data,
    this.errorCode,
  });

  factory ApiResponseModel.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    final logger = AppLogger();
    logger.d('API yanıtı işleniyor: $json');
    
    // API'nin özel durum: 410 (Gone) kodu başarılı bir yanıt göstergesi olabilir
    // '410' değeri bir String veya başka bir tip olabilir
    bool hasGoneCode = false;
    
    if (json.containsKey('410')) {
      final gone410Value = json['410'];
      if (gone410Value is String && gone410Value == 'Gone') {
        hasGoneCode = true;
        logger.i('Yanıtta "410": "Gone" (String) bulundu');
      } else if (gone410Value != null) {
        // Diğer tip kontrolü
        hasGoneCode = true;
        logger.i('Yanıtta "410" kodu farklı tipte (${gone410Value.runtimeType}) bulundu: $gone410Value');
      }
    }
    
    // Eğer API yanıtında success: true ise, 410 kodu olsa bile işlem başarılı
    // Null kontrolü ekleyerek, null değerleri varsayılan değerlerle değiştirelim
    final isSuccess = json.containsKey('success') ? 
        (json['success'] is bool ? json['success'] as bool : true) : true;
    
    // Error alanı için de null kontrolü yapalım
    final isError = json.containsKey('error') ? 
        (json['error'] is bool ? json['error'] as bool : false) : false;
    
    // Data kontrolü - API yanıtında data olabilir veya olmayabilir
    T? parsedData;
    if (json.containsKey('data') && json['data'] != null) {
      try {
        if (json['data'] is Map<String, dynamic>) {
          parsedData = fromJsonT(json['data'] as Map<String, dynamic>);
          logger.d('Data başarıyla ayrıştırıldı');
        } else {
          logger.w('Data ayrıştırılamadı: data bir Map değil, tipi: ${json['data'].runtimeType}');
        }
      } catch (e) {
        logger.e('Data ayrıştırma hatası', e);
      }
    } else {
      logger.d('Yanıtta data bilgisi yok veya null');
    }
    
    // Tüm olası hatalar için errorCode oluşturma
    String? finalErrorCode;
    if (hasGoneCode) {
      finalErrorCode = "410: Gone";
    } else if (json.containsKey('message') && json['message'] != null) {
      // Eğer API yanıtında message varsa hata mesajı olarak kullan
      finalErrorCode = json['message'].toString();
    }
    
    return ApiResponseModel<T>(
      error: isError,
      success: isSuccess,
      data: parsedData,
      errorCode: finalErrorCode,
    );
  }
} 