import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/views/login_view.dart';
import 'package:pos701/services/api_service.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/viewmodels/login_viewmodel.dart';
import 'package:pos701/constants/app_constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        ProxyProvider<ApiService, AuthService>(
          update: (_, apiService, __) => AuthService(apiService),
        ),
        ChangeNotifierProxyProvider<AuthService, LoginViewModel>(
          create: (_) => LoginViewModel(AuthService(ApiService())),
          update: (_, authService, __) => LoginViewModel(authService),
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
        home: const LoginView(),
      ),
    );
  }
}
