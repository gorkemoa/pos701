import 'package:flutter/material.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:pos701/views/home_view.dart';
import 'package:pos701/views/tables_view.dart';
import 'package:pos701/views/kitchen_view.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/views/login_view.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/services/firebase_messaging_service.dart';

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
            height: 190,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Menü | ${userViewModel.userInfo?.company?.compName ?? ''}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child:               Column(
                children: [
                  // Anasayfa sadece userRank 50 olan kullanıcılara göster
                  if (userViewModel.userInfo?.userRank == '50')
                    _buildDrawerItem(
                      icon: Icons.home,
                      title: 'Anasayfa',
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
                  _buildDrawerItem(
                    icon: Icons.shopping_basket,
                    title: 'Siparişler',
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
                  _buildDrawerItem(
                    icon: Icons.tv,
                    title: 'Mutfak',
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
                  _buildExpandableItem(
                    icon: Icons.layers,
                    title: 'Tanımlamalar',
                    isExpanded: _tanimlamalarExpanded,
                    onTap: () {
                      setState(() {
                        _tanimlamalarExpanded = !_tanimlamalarExpanded;
                      });
                    },
                  ),
                  if (_tanimlamalarExpanded)
                    Column(
                      children: [
                        _buildSubDrawerItem(
                          title: 'Menü Tanımlama',
                          onTap: () {
                            Navigator.pop(context);
                            // Menü Tanımlama sayfasına yönlendirme
                          },
                        ),
                        _buildSubDrawerItem(
                          title: 'Masa Tanımlama',
                          onTap: () {
                            Navigator.pop(context);
                            // Masa Tanımlama sayfasına yönlendirme
                          },
                        ),
                      ],
                    ),
                  _buildDrawerItem(
                    icon: Icons.print,
                    title: 'Yazıcı Tanımlama',
                    onTap: () {
                      Navigator.pop(context);
                      // Yazıcı Tanımlama sayfasına yönlendirme
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.ondemand_video,
                    title: 'Kullanım Kılavuzu',
                    onTap: () {
                      Navigator.pop(context);
                      // Kullanım Kılavuzu sayfasına yönlendirme
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final userViewModel = Provider.of<UserViewModel>(
                        context, 
                        listen: false
                      );
                      
                      // Topic aboneliğinden çık
                      try {
                        final messagingService = Provider.of<FirebaseMessagingService>(
                          context,
                          listen: false,
                        );
                        await userViewModel.unsubscribeFromUserTopic(messagingService);
                      } catch (e) {
                        // Hata durumunda işlemi engellemeyin, sadece loglayın
                        debugPrint('Topic aboneliğinden çıkarken hata: $e');
                      }
                      
                      // Oturumu kapat
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Çıkış Yap',
                      style: TextStyle(fontSize: 14),
                    ),
                  
                  ),
                ),
              SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: Icon(icon, size: 20, color: Colors.black87),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.5),
      ],
    );
  }

  Widget _buildSubDrawerItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 56, right: 16),
          title: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.5),
      ],
    );
  }

  Widget _buildExpandableItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          leading: Icon(icon, size: 20, color: Colors.black87),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: Colors.black54,
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.5),
      ],
    );
  }
} 