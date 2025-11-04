import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pos701/viewmodels/order_list_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pos701/views/login_view.dart';
import 'package:pos701/services/api_service.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/services/statistics_service.dart';
import 'package:pos701/services/kitchen_service.dart';
import 'package:pos701/viewmodels/login_viewmodel.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/viewmodels/statistics_viewmodel.dart';
import 'package:pos701/viewmodels/basket_viewmodel.dart';
import 'package:pos701/viewmodels/order_viewmodel.dart';
import 'package:pos701/viewmodels/kitchen_viewmodel.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/views/home_view.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:pos701/views/basket_view.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/viewmodels/customer_viewmodel.dart';
import 'package:pos701/services/customer_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pos701/services/firebase_messaging_service.dart';
import 'package:pos701/viewmodels/notification_viewmodel.dart';
import 'package:pos701/viewmodels/boss_statistics_viewmodel.dart';
import 'package:pos701/viewmodels/company_viewmodel.dart';
import 'package:pos701/firebase_options.dart';
import 'package:upgrader/upgrader.dart';

// Global navigator key - 403 hatası durumunda login'e yönlendirme için
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
 
// Uygulama başlatıldı mı kontrolü için global değişken
bool _isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Uygulama sabitlerini başlat
   await AppConstants.init();
  // Cihaz tipine göre (telefon/tablet) oryantasyonu ayarla
  final ui.FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
  final double logicalWidth = view.physicalSize.width / view.devicePixelRatio;
  final double logicalHeight = view.physicalSize.height / view.devicePixelRatio;
  final double shortestSide = logicalWidth < logicalHeight ? logicalWidth : logicalHeight;
  final bool isTablet = shortestSide >= 600;
  if (isTablet) {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } else {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
  }
  
  final logger = AppLogger();
  logger.i('Uygulama başlatılıyor');
  logger.i('Uygulama Versiyonu: ${AppConstants.appVersion} (${AppConstants.buildNumber})');
  logger.i('API Base URL: ${AppConstants.baseUrl}');
  
  // Firebase'i başlat
  await _initializeFirebase(logger);
  
  // Firebase Messaging servisini oluştur
  final firebaseMessagingService = FirebaseMessagingService();
  
  // Firebase Messaging servisini başlat
  try {
    await firebaseMessagingService.initialize();
    logger.i('Firebase Messaging servisi başarıyla başlatıldı');
  } catch (e) {
    logger.e('Firebase Messaging servisi başlatılamadı: $e');
  }
  
  
  final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
  debugPrint("📲 APNs Token: $apnsToken");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Firebase Messaging servisini al
    final firebaseMessagingService = FirebaseMessagingService();
    
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        ProxyProvider<ApiService, AuthService>(
          update: (_, apiService, __) => AuthService(apiService),
        ),
        ProxyProvider<ApiService, StatisticsService>(
          update: (_, apiService, __) => StatisticsService(apiService),
        ),
        ProxyProvider<ApiService, KitchenService>(
          update: (_, apiService, __) => KitchenService(apiService: apiService),
        ),
        ChangeNotifierProxyProvider2<AuthService, ApiService, LoginViewModel>(
          create: (context) => LoginViewModel(
            Provider.of<AuthService>(context, listen: false),
            Provider.of<ApiService>(context, listen: false),
          ),
          update: (_, authService, apiService, previous) => LoginViewModel(authService, apiService),
        ),
        // CompanyViewModel'i singleton olarak ekle
        ChangeNotifierProvider<CompanyViewModel>(
          create: (_) => CompanyViewModel.instance,
        ),
        ChangeNotifierProxyProvider2<AuthService, CompanyViewModel, UserViewModel>(
          create: (context) => UserViewModel(
            Provider.of<AuthService>(context, listen: false),
            companyViewModel: Provider.of<CompanyViewModel>(context, listen: false),
          ),
          update: (_, authService, companyViewModel, __) => UserViewModel(
            authService,
            companyViewModel: companyViewModel,
          ),
        ),
        ChangeNotifierProxyProvider<StatisticsService, StatisticsViewModel>(
          create: (_) => StatisticsViewModel(StatisticsService(ApiService())),
          update: (_, statisticsService, __) => StatisticsViewModel(statisticsService),
        ),
        ChangeNotifierProxyProvider<KitchenService, KitchenViewModel>(
          create: (_) => KitchenViewModel(kitchenService: KitchenService()),
          update: (_, kitchenService, __) => KitchenViewModel(kitchenService: kitchenService),
        ),
        ChangeNotifierProvider<BasketViewModel>(
          create: (_) => BasketViewModel(),
        ),
        ChangeNotifierProvider<OrderViewModel>(
          create: (_) => OrderViewModel(),
        ),
        ChangeNotifierProvider<OrderListViewModel>(
          create: (_) => OrderListViewModel(),
        ),
        ChangeNotifierProvider<TablesViewModel>(
          create: (_) => TablesViewModel(),
        ),
        ChangeNotifierProvider<CustomerViewModel>(
          create: (_) => CustomerViewModel(customerService: CustomerService()),
        ),
        // Firebase başlatma durumunu provider olarak ekle
        Provider<bool>(
          create: (_) => _isFirebaseInitialized,
        ),
        // Firebase Messaging servisini provider olarak ekle
        Provider<FirebaseMessagingService>(
          create: (_) => firebaseMessagingService,
          dispose: (_, service) => service.dispose(),
        ),
        // Notification ViewModel ekle
        ChangeNotifierProxyProvider<FirebaseMessagingService, NotificationViewModel>(
          create: (context) => NotificationViewModel(
            Provider.of<FirebaseMessagingService>(context, listen: false),
          ),
          update: (_, messagingService, previous) => previous ?? NotificationViewModel(messagingService),
        ),
        // Boss Statistics ViewModel ekle
        ChangeNotifierProvider<BossStatisticsViewModel>(
          create: (_) => BossStatisticsViewModel(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        locale: const Locale('tr', 'TR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        theme: ThemeData(
          primaryColor: Color(AppConstants.primaryColorValue),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(AppConstants.primaryColorValue),
            primary: Color(AppConstants.primaryColorValue),
          ),
        ),
        routes: {
          '/basket': (context) => const BasketView(tableName: 'Sipariş Detayı'),
          '/order_details': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return BasketView(
              tableName: args['tableName'] ?? 'Sipariş Detayı',
              orderID: args['orderID'],
            );
          },
        },
        home: UpgradeAlert(
          upgrader: Upgrader(
            debugDisplayAlways: false, // Sadece gerçekten yeni versiyon varsa göster
            debugLogging: true, // Log görmek için
            durationUntilAlertAgain: const Duration(seconds: 0), // Her açılışta kontrol et
            messages: UpgraderMessages(
              code: 'tr',
            ),
            countryCode: 'TR',
          ),
          dialogStyle: UpgradeDialogStyle.cupertino, // iOS tarzı dialog
          child: FutureBuilder<bool>(
            future: _checkIfLoggedIn(AuthService(ApiService())),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                final logger = AppLogger();
                logger.d('Oturum durumu kontrol ediliyor...');
                return Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: Stack(
                      children: [
                        // Tam ekran kaplayan splash görseli
                        Positioned.fill(
                          child: Image.asset(
                            'assets/splash/powered_by.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Alt kısımda loading indicator
                        Positioned(
                          bottom: 100,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26B4E9)), // Mavi 7 rengi
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                final isLoggedIn = snapshot.data ?? false;
                final logger = AppLogger();
                logger.i('Oturum durumu: ${isLoggedIn ? 'Giriş yapılmış' : 'Giriş yapılmamış'}');
                
                if (isLoggedIn) {
                  // Kullanıcı giriş yapmışsa ana sayfaya yönlendir
                  return const HomeView();
                } else {
                  // Kullanıcı giriş yapmamışsa giriş sayfasına yönlendir
                  return const LoginView();
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Firebase başlatma işlemi
Future<void> _initializeFirebase(AppLogger logger) async {
  if (_isFirebaseInitialized) {
    logger.i('Firebase zaten başlatılmış durumda');
    return;
  }

  try {
    // Firebase'i başlat
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
    logger.i('Firebase başarıyla başlatıldı');
  } catch (e) {
    logger.e('Firebase başlatılamadı: $e');
    _isFirebaseInitialized = false;
    // Hata durumunda tekrar deneme mekanizması eklenebilir
  }
}

// Firebase'i başlatma yardımcı fonksiyonu - bu diğer sınıflardan çağrılabilir
Future<bool> ensureFirebaseInitialized() async {
  if (_isFirebaseInitialized) return true;
  
  final logger = AppLogger();
  await _initializeFirebase(logger);
  return _isFirebaseInitialized;
}

Future<bool> _checkIfLoggedIn(AuthService authService) async {
  final logger = AppLogger();
  logger.d('Oturum durumu kontrol ediliyor');
  return await authService.isLoggedIn();
}
