import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/login_viewmodel.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/views/home_view.dart';
import 'package:pos701/views/tables_view.dart';
import 'package:pos701/services/firebase_messaging_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = Provider.of<LoginViewModel>(context, listen: false);
    if (viewModel.savedUsername != null) {
      _usernameController.text = viewModel.savedUsername!;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Kullanıcı Giriş Ekranı',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 24 : 20,
          ),
        ),
        backgroundColor: Color(AppConstants.primaryColorValue),
        toolbarHeight: isTablet ? 80 : null,
      ),
      body: Consumer<LoginViewModel>(
        builder: (context, viewModel, child) {
          if (isTablet && isLandscape) {
            // Tablet yatay yönlendirme
            return _buildLandscapeTabletLayout(viewModel);
          } else if (isTablet) {
            // Tablet dikey yönlendirme
            return _buildPortraitTabletLayout(viewModel);
          } else {
            // Telefon layout'u
            return _buildPhoneLayout(viewModel);
          }
        },
      ),
    );
  }

  Widget _buildLandscapeTabletLayout(LoginViewModel viewModel) {
    return Row(
      children: [
        // Sol taraf - Logo ve başlık
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              
              children: [
                Image.asset(
                  'assets/images/image.png',
                  width: 200,
                  height: 200,
                ),
              ],
            ),
          ),
        ),
        // Sağ taraf - Form
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(48.0),
            child: _buildForm(viewModel, isTablet: true),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitTabletLayout(LoginViewModel viewModel) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 100.0),
        child: Column(
          children: [
            const SizedBox(height: 0),
            // Logo ve başlık
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/image.png',
                    width: 200,
                    height: 200,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 0),
            // Form
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: _buildForm(viewModel, isTablet: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneLayout(LoginViewModel viewModel) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50),
            Center(
              child: Image.asset(
                'assets/images/image.png',
                width: 160,
                height: 160,
              ),
            ),
            const SizedBox(height: 50),
            _buildForm(viewModel, isTablet: false),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(LoginViewModel viewModel, {required bool isTablet}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 100),
          Text(
            'Kullanıcı adı',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'E-posta veya kullanıcı adı',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isTablet ? 20 : 16,
              ),
            ),
            style: TextStyle(fontSize: isTablet ? 18 : 16),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen kullanıcı adınızı giriniz';
              }
              return null;
            },
          ),
          SizedBox(height: isTablet ? 32 : 20),
          Text(
            'Şifre',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !viewModel.isPasswordVisible,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Şifreniz',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isTablet ? 20 : 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  viewModel.isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  size: isTablet ? 28 : 24,
                ),
                onPressed: () {
                  viewModel.togglePasswordVisibility();
                },
              ),
            ),
            style: TextStyle(fontSize: isTablet ? 18 : 16),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen şifrenizi giriniz';
              }
              return null;
            },
          ),
          SizedBox(height: isTablet ? 24 : 16),
          Row(
            children: [
              SizedBox(
                height: isTablet ? 32 : 24,
                width: isTablet ? 32 : 24,
                child: Checkbox(
                  value: viewModel.rememberMe,
                  onChanged: (value) {
                    viewModel.setRememberMe(value ?? false);
                  },
                  activeColor: Color(AppConstants.primaryColorValue),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Beni Hatırla',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (viewModel.errorMessage != null)
            Padding(
              padding: EdgeInsets.only(top: isTablet ? 24 : 16),
              child: Text(
                viewModel.errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          SizedBox(height: isTablet ? 60 : 40),
          SizedBox(
            height: isTablet ? 60 : 50,
            child: ElevatedButton(
              onPressed: viewModel.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        if (viewModel.isLoading) return;
                        final success = await viewModel.login(
                          _usernameController.text,
                          _passwordController.text,
                        );
                        if (success) {
                          if (viewModel.rememberMe) {
                            // Kullanıcı adı kaydedildi
                          } else {
                            await viewModel.clearSavedUsername();
                          }
                          final userViewModel = Provider.of<UserViewModel>(
                            context,
                            listen: false,
                          );
                          final bool userInfoLoaded = await userViewModel.loadUserInfo();
                          if (!userInfoLoaded || userViewModel.userInfo == null || userViewModel.userInfo!.compID == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kullanıcı bilgileri alınamadı. Lütfen tekrar deneyin.')),
                              );
                            }
                            return;
                          }
                          final messagingService = Provider.of<FirebaseMessagingService>(
                            context,
                            listen: false,
                          );
                          await viewModel.subscribeToUserTopic(messagingService);
                          final String? userRank = userViewModel.userInfo?.userRank;
                          final int compID = userViewModel.userInfo!.compID!;
                          final String token = userViewModel.userInfo!.token;
                          if (mounted) {
                            if (userRank == '30') {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => TablesView(
                                    userToken: token,
                                    compID: compID,
                                    title: 'Masalar',
                                  ),
                                ),
                              );
                            } else if (userRank == '50') {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomeView(),
                                ),
                              );
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomeView(),
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConstants.primaryColorValue),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 8 : 4),
                ),
              ),
              child: viewModel.isLoading
                  ? SizedBox(
                      width: isTablet ? 32 : 24,
                      height: isTablet ? 32 : 24,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Giriş Yap',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: isTablet ? 60 : 40),
            child: Center(
              child: Text(
                'Versiyon ${AppConstants.appVersion}',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 