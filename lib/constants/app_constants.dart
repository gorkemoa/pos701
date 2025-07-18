import 'package:package_info_plus/package_info_plus.dart';

class AppConstants {
  static const String appName = 'POS701';
  static late String appVersion;
  static late String buildNumber;

  static Future<void> init() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
  }

  static const String baseUrl = 'https://api.pos701.com/'; // API base URL bilginizi güncelleyin
  
  // API Endpoints
  static const String loginEndpoint = 'service/auth/login';
  static const String userInfoEndpoint = 'service/user/id/';
  static const String getTablesEndpoint = 'service/user/order/tableList';
  static const String tableOrderMergeEndpoint = 'service/user/order/tableOrderMerge';
  static const String tableChangeEndpoint = 'service/user/order/tableChange';
  static const String productDetailEndpoint = 'service/product/id/detail';
  static const String customersEndpoint = 'service/user/account/customers';
  static const String addCustomerEndpoint = 'service/user/account/customers/addCust';
  
  // Storage Keys
  static const String tokenKey = 'token';
  static const String userIdKey = 'userId';
  static const String userNameKey = 'userName';
  static const String rememberMeKey = 'rememberMe';
  static const String companyIdKey = 'companyId';
  
  // Colors
  static const int primaryColorValue = 0xFF1aa7e0; // Yeşil renk
  static const int incomeCardColor = 0xFFE76767; // Gelir kart rengi
  static const int expenseCardColor = 0xFF9C27B0; // Gider kart rengi
  static const int orderCardColor = 0xFF3F51B5; // Sipariş kart rengi
  static const int customerCardColor = 0xFF1B5E20; // Müşteri kart rengi
  static const int chartLineColor = 0xFF8FD8D2; // Grafik çizgi rengi

  // Basic Auth
  static const String basicAuthUsername = 'Tr1VAhW2ICWHPN2nlvp7K5ytGoyOJM';
  static const String basicAuthPassword = 'vRP4rT7APmjSmkI17I1EVpPH57Edl0';
}

class AppStrings {
  static const String errorTitle = 'Hata';
  static const String noRegionsFound = 'Bölge bulunamadı';
  static const String retryButtonText = 'Yeniden Dene';
  static const String supportButtonText = 'Destek İste';
} 