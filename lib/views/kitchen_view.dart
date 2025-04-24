import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/kitchen_order_model.dart';
import 'package:pos701/viewmodels/kitchen_viewmodel.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/widgets/app_drawer.dart';

class KitchenView extends StatefulWidget {
  final String userToken;
  final int compID;
  final String title;

  const KitchenView({
    Key? key,
    required this.userToken,
    required this.compID,
    this.title = 'Mutfak',
  }) : super(key: key);

  @override
  State<KitchenView> createState() => _KitchenViewState();
}

class _KitchenViewState extends State<KitchenView> {
  @override
  void initState() {
    super.initState();
    // Sayfada ilk kez olduğumuzda, ViewModel'i oluştur ve otomatik yenilemeyi başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kitchenViewModel = Provider.of<KitchenViewModel>(context, listen: false);
      // Token boş değilse ve compID 0 değilse devam et
      if (widget.userToken.isNotEmpty && widget.compID > 0) {
        debugPrint('🔵 [Mutfak] Parametre kontrolü: userToken=${widget.userToken}, compID=${widget.compID}');
        kitchenViewModel.startAutoRefresh(widget.userToken, widget.compID);
      } else {
        // Kullanıcı bilgileri yeterli değilse, UserViewModel'den alabiliriz
        final userViewModel = Provider.of<UserViewModel>(context, listen: false);
        final token = userViewModel.userInfo?.userToken ?? '';
        final companyId = userViewModel.userInfo?.compID ?? 0;
        
        if (token.isNotEmpty && companyId > 0) {
          debugPrint('🔵 [Mutfak] UserViewModel parametreleri: userToken=$token, compID=$companyId');
          kitchenViewModel.startAutoRefresh(token, companyId);
        } else {
          debugPrint('🔴 [Mutfak] Geçerli token veya şirket ID bulunamadı');
          // Hata durumunu göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı bilgileri alınamadı. Lütfen yeniden giriş yapın.'))
          );
        }
      }
    });
  }

  @override
  void dispose() {
    // Sayfadan çıkıldığında otomatik yenilemeyi durdur
    final kitchenViewModel = Provider.of<KitchenViewModel>(context, listen: false);
    kitchenViewModel.stopAutoRefresh();
    super.dispose();
  }

  // Unix timestamp'ı tarih saat formatına dönüştür
  String formatTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    
    try {
      final int timestampInt = int.parse(timestamp);
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
      // HH:mm formatında göster
      final String hour = dateTime.hour.toString().padLeft(2, '0');
      final String minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: Consumer<KitchenViewModel>(
        builder: (context, kitchenViewModel, child) {
          if (kitchenViewModel.isLoading && kitchenViewModel.orders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (kitchenViewModel.state == KitchenViewState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${kitchenViewModel.errorMessage}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Kullanıcı bilgilerini kontrol et
                      if (widget.userToken.isNotEmpty && widget.compID > 0) {
                        kitchenViewModel.getKitchenOrders(widget.userToken, widget.compID);
                      } else {
                        final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                        final token = userViewModel.userInfo?.userToken ?? '';
                        final companyId = userViewModel.userInfo?.compID ?? 0;
                        
                        if (token.isNotEmpty && companyId > 0) {
                          kitchenViewModel.getKitchenOrders(token, companyId);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kullanıcı bilgileri alınamadı. Lütfen yeniden giriş yapın.'))
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Yeniden Dene'),
                  ),
                ],
              ),
            );
          }
          
          if (kitchenViewModel.orders.isEmpty) {
            return const Center(
              child: Text(
                'Bekleyen sipariş bulunmuyor',
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () {
              // Kullanıcı bilgilerini kontrol et
              if (widget.userToken.isNotEmpty && widget.compID > 0) {
                return kitchenViewModel.getKitchenOrders(widget.userToken, widget.compID);
              } else {
                final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                final token = userViewModel.userInfo?.userToken ?? '';
                final companyId = userViewModel.userInfo?.compID ?? 0;
                
                if (token.isNotEmpty && companyId > 0) {
                  return kitchenViewModel.getKitchenOrders(token, companyId);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kullanıcı bilgileri alınamadı. Lütfen yeniden giriş yapın.'))
                  );
                  return Future.value();
                }
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: kitchenViewModel.orders.length,
              itemBuilder: (context, index) {
                final order = kitchenViewModel.orders[index];
                return _buildOrderCard(context, order);
              },
            ),
          );
        }
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, KitchenOrder order) {
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      order.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.table_bar, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      order.tableName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderInfo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                ...order.products.map((product) => _buildProductItem(context, product, order)).toList(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Kullanıcı bilgilerini kontrol et
                          String token = widget.userToken;
                          int companyId = widget.compID;
                          
                          if (token.isEmpty || companyId <= 0) {
                            final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                            token = userViewModel.userInfo?.userToken ?? '';
                            companyId = userViewModel.userInfo?.compID ?? 0;
                          }
                          
                          if (token.isEmpty || companyId <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kullanıcı bilgileri alınamadı. Lütfen yeniden giriş yapın.'))
                            );
                            return;
                          }
                          
                          final kitchenViewModel = Provider.of<KitchenViewModel>(context, listen: false);
                          
                          // İşlem başladığında bildirim göster
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sipariş hazır olarak işaretleniyor...'))
                          );
                          
                          kitchenViewModel.markOrderReady(token, companyId, order.orderID).then((success) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sipariş hazır olarak işaretlendi!'))
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: ${kitchenViewModel.errorMessage}'))
                              );
                            }
                          });
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Tümü Hazır'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Yazdır işlevselliği burada eklenir
                        },
                        icon: const Icon(Icons.print),
                        label: const Text('Yazdır'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, KitchenProduct product, KitchenOrder order) {
    String timeString = formatTime(product.proTime);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              timeString.isNotEmpty ? timeString : '00:13',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${product.proQty} ${product.proUnit} - ${product.proName}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red[400],
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: () {
                // Kullanıcı bilgilerini kontrol et
                String token = widget.userToken;
                int companyId = widget.compID;
                
                if (token.isEmpty || companyId <= 0) {
                  final userViewModel = Provider.of<UserViewModel>(context, listen: false);
                  token = userViewModel.userInfo?.userToken ?? '';
                  companyId = userViewModel.userInfo?.compID ?? 0;
                }
                
                if (token.isEmpty || companyId <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kullanıcı bilgileri alınamadı. Lütfen yeniden giriş yapın.'))
                  );
                  return;
                }
                
                final kitchenViewModel = Provider.of<KitchenViewModel>(context, listen: false);
                
                // İşlem başladığında bildirim göster
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ürün hazır olarak işaretleniyor...'))
                );
                
                kitchenViewModel.markProductReady(token, companyId, order.orderID, product.opID).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ürün hazır olarak işaretlendi!'))
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: ${kitchenViewModel.errorMessage}'))
                    );
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
} 