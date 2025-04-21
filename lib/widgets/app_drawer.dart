import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/views/login_view.dart';
import 'package:pos701/constants/app_constants.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Color(AppConstants.primaryColorValue),
            ),
            accountName: Text(
              userViewModel.userInfo?.userFullname ?? 'Kullanıcı',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              userViewModel.userInfo?.userEmail ?? 'E-posta yok',
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userViewModel.userInfo?.userFirstname?.substring(0, 1) ?? 'K',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColorValue),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Ana Sayfa'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Siparişler'),
            onTap: () {
              Navigator.pop(context);
              // Siparişler sayfasına yönlendirme
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Müşteriler'),
            onTap: () {
              Navigator.pop(context);
              // Müşteriler sayfasına yönlendirme
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Ödemeler'),
            onTap: () {
              Navigator.pop(context);
              // Ödemeler sayfasına yönlendirme
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            onTap: () {
              Navigator.pop(context);
              // Ayarlar sayfasına yönlendirme
            },
          ),
          const Spacer(),
          Divider(height: 1, color: Colors.grey.shade300),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginView()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
} 