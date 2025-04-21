import 'package:logger/logger.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late Logger _logger;

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: Level.verbose,
    );
  }

  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void v(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }

  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  void apiRequest(String method, String endpoint, {dynamic body, Map<String, dynamic>? headers}) {
    final logMessage = '''
    API İSTEĞİ GÖNDERİLDİ:
    → Metod: $method
    → Endpoint: $endpoint
    → Headers: $headers
    → Body: $body
    ''';
    _logger.i(logMessage);
  }

  void apiResponse(String method, String endpoint, int statusCode, dynamic data, {int? executionTime}) {
    final executionTimeText = executionTime != null ? ' ($executionTime ms)' : '';
    final logMessage = '''
    API YANITI ALINDI$executionTimeText:
    ← Metod: $method
    ← Endpoint: $endpoint
    ← Status: $statusCode
    ← Veri: $data
    ''';
    _logger.i(logMessage);
  }

  void apiError(String method, String endpoint, dynamic error, {dynamic response, int? executionTime}) {
    final executionTimeText = executionTime != null ? ' ($executionTime ms)' : '';
    final logMessage = '''
    API HATASI$executionTimeText:
    ✗ Metod: $method
    ✗ Endpoint: $endpoint
    ✗ Hata: $error
    ✗ Yanıt: $response
    ''';
    _logger.e(logMessage);
  }
} 