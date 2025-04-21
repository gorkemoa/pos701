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
          primaryColor: const Color(0xFF77c178),
          scaffoldBackgroundColor: const Color(0xFFf5f5f5),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFF333333)),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF77c178),
            primary: const Color(0xFF77c178),
            secondary: const Color.fromARGB(255, 255, 255, 255),
            tertiary: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        home: const LoginView(),
      ),
    );
  }
}
