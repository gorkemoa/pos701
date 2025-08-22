import 'dart:io';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  /// İnternet bağlantısını kontrol eder
  /// Returns true if internet connection is available, false otherwise
  Future<bool> hasInternetConnection() async {
    try {
      // Google DNS sunucusuna erişmeyi dene
      final result = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// API isteklerinden önce internet kontrolü yapan yardımcı metod
  /// Eğer internet yoksa false döner ve API isteği yapılmaz
  Future<bool> checkInternetBeforeApiCall() async {
    final hasConnection = await hasInternetConnection();
    if (!hasConnection) {
      print('⚠️ İnternet bağlantısı yok, API isteği iptal edildi');
    }
    return hasConnection;
  }
}
