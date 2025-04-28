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

  factory ApiResponseModel.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
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
        final dynamic dataValue = json['data'];
        // Data alanı hem Map<String, dynamic> hem de List<dynamic> veya başka tip olabilir
        logger.d('Data alanının tipi: ${dataValue.runtimeType}, değeri: $dataValue');
        parsedData = fromJsonT(dataValue);
        logger.d('Data başarıyla ayrıştırıldı');
      } catch (e, stackTrace) {
        logger.e('Data ayrıştırma hatası: $e', e);
        logger.e('Data ayrıştırma hata yığını: $stackTrace');
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