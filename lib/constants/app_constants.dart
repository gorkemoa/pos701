class AppConstants {
  static const String appName = 'POS701';
  static const String appVersion = '2.1';
  static const String baseUrl = 'https://api.pos701.com/'; // API base URL bilginizi güncelleyin
  
  // API Endpoints
  static const String loginEndpoint = 'service/auth/login';
  static const String userInfoEndpoint = 'service/user/id/';
  
  // Storage Keys
  static const String tokenKey = 'token';
  static const String userIdKey = 'userId';
  static const String userNameKey = 'userName';
  static const String rememberMeKey = 'rememberMe';
  
  // Colors
  static const int primaryColorValue = 0xFF77c178; // Yeşil renk
  static const int incomeCardColor = 0xFFE76767; // Gelir kart rengi
  static const int expenseCardColor = 0xFF9C27B0; // Gider kart rengi
  static const int orderCardColor = 0xFF3F51B5; // Sipariş kart rengi
  static const int customerCardColor = 0xFF1B5E20; // Müşteri kart rengi
  static const int chartLineColor = 0xFF8FD8D2; // Grafik çizgi rengi

  // Basic Auth
  static const String basicAuthUsername = 'Tr1VAhW2ICWHPN2nlvp7K5ytGoyOJM';
  static const String basicAuthPassword = 'vRP4rT7APmjSmkI17I1EVpPH57Edl0';
} 