import 'package:flutter/material.dart';
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
import 'package:pos701/views/tables_view.dart';
import 'package:pos701/views/basket_view.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = AppLogger();
  logger.i('Uygulama başlatılıyor');
  logger.i('API Base URL: ${AppConstants.baseUrl}');
  
  runApp(
    MultiProvider(
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
        ChangeNotifierProxyProvider<AuthService, UserViewModel>(
          create: (_) => UserViewModel(AuthService(ApiService())),
          update: (_, authService, __) => UserViewModel(authService),
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
        ChangeNotifierProvider<TablesViewModel>(
          create: (_) => TablesViewModel(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
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
        home: FutureBuilder<bool>(
          future: _checkIfLoggedIn(AuthService(ApiService())),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              logger.d('Oturum durumu kontrol ediliyor...');
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              final isLoggedIn = snapshot.data ?? false;
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

Future<bool> _checkIfLoggedIn(AuthService authService) async {
  final logger = AppLogger();
  logger.d('Oturum durumu kontrol ediliyor');
  return await authService.isLoggedIn();
}

