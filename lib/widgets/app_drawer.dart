import 'package:flutter/material.dart';
import 'package:pos701/views/home_view.dart';
import 'package:pos701/views/tables_view.dart';
import 'package:pos701/views/kitchen_view.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/views/login_view.dart';
import 'package:pos701/constants/app_constants.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _tanimlamalarExpanded = false;

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    
    return Drawer(
      child: Column(
        children: [
          Container(
            color: primaryColor,
            height: 110,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Menü',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.home, size: 26),
                    title: const Text('Anasayfa', style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeView(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.shopping_basket, size: 26),
                    title: const Text('Siparişler', style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TablesView(
                            userToken: userViewModel.userInfo?.userToken ?? '',
                            compID: userViewModel.userInfo?.compID ?? 0,
                            title: 'Siparişler',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tv, size: 26),
                    title: const Text('Mutfak', style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KitchenView(
                            userToken: userViewModel.userInfo?.userToken ?? '',
                            compID: userViewModel.userInfo?.compID ?? 0,
                            title: 'Mutfak',
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.layers, size: 26),
                    title: const Text('Tanımlamalar', style: TextStyle(fontSize: 16)),
                    trailing: Icon(
                      _tanimlamalarExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 26,
                    ),
                    onTap: () {
                      setState(() {
                        _tanimlamalarExpanded = !_tanimlamalarExpanded;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  if (_tanimlamalarExpanded)
                    Column(
                      children: [
                        ListTile(
                          leading: const SizedBox(width: 26),
                          title: const Text('Menü Tanımlama', style: TextStyle(fontSize: 16)),
                          onTap: () {
                            Navigator.pop(context);
                            // Menü Tanımlama sayfasına yönlendirme
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const SizedBox(width: 26),
                          title: const Text('Masa Tanımlama', style: TextStyle(fontSize: 16)),
                          onTap: () {
                            Navigator.pop(context);
                            // Masa Tanımlama sayfasına yönlendirme
                          },
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ListTile(
                    leading: const Icon(Icons.print, size: 26),
                    title: const Text('Yazıcı Tanımlama', style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      // Yazıcı Tanımlama sayfasına yönlendirme
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.ondemand_video, size: 26),
                    title: const Text('Kullanım Kılavuzu', style: TextStyle(fontSize: 16)),
                    onTap: () {
                      Navigator.pop(context);
                      // Kullanım Kılavuzu sayfasına yönlendirme
                    },
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await authService.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginView()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Çıkış Yap'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 