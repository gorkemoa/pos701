import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/views/login_view.dart';
import 'package:pos701/services/api_service.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/viewmodels/login_viewmodel.dart';

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
        title: 'POS701',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFFD74B4B),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD74B4B),
            primary: const Color(0xFFD74B4B),
          ),
        ),
        home: const LoginView(),
      ),
    );
  }
}
