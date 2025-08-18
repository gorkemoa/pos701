import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/kitchen_order_model.dart';
import 'package:pos701/viewmodels/kitchen_viewmodel.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/widgets/app_drawer.dart';
import 'dart:async';

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
  Timer? _uiUpdateTimer;
  late KitchenViewModel _kitchenViewModel;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _kitchenViewModel = Provider.of<KitchenViewModel>(context, listen: false);
      _initialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Sayfada ilk kez olduğumuzda, ViewModel'i oluştur ve otomatik yenilemeyi başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      
      // Sunucu saatini UserViewModel'den al ve KitchenViewModel'e aktar
      final serverDate = userViewModel.userInfo?.serverDate ?? '';
      final serverTime = userViewModel.userInfo?.serverTime ?? '';
      
      if (serverDate.isNotEmpty && serverTime.isNotEmpty) {
        debugPrint('🔵 [Mutfak] Sunucu saati alındı: serverDate=$serverDate, serverTime=$serverTime');
        _kitchenViewModel.updateServerTime(serverTime, serverDate);
      }
      
      // Token boş değilse ve compID 0 değilse devam et
      if (widget.userToken.isNotEmpty && widget.compID > 0) {
        debugPrint('🔵 [Mutfak] Parametre kontrolü: userToken=${widget.userToken}, compID=${widget.compID}');
        _kitchenViewModel.startAutoRefresh(widget.userToken, widget.compID);
      } else {
        // Kullanıcı bilgileri yeterli değilse, UserViewModel'den alabiliriz
        final token = userViewModel.userInfo?.userToken ?? '';
        final companyId = userViewModel.userInfo?.compID ?? 0;
        
        if (token.isNotEmpty && companyId > 0) {
          debugPrint('🔵 [Mutfak] UserViewModel parametreleri: userToken=$token, compID=$companyId');
          _kitchenViewModel.startAutoRefresh(token, companyId);
        } else {
          debugPrint('🔴 [Mutfak] Geçerli token veya şirket ID bulunamadı');
          // Hata durumunu göster
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı bilgileri alınamadı. Lütfen yeniden giriş yapın.'))
          );
        }
      }
      
      // UI güncellemesi için timer başlat (her saniye)
      _uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {}); // UI'ı yenile
      });
    });
  }

  @override
  void dispose() {
    // Sayfadan çıkıldığında otomatik yenilemeyi durdur
    _kitchenViewModel.stopAutoRefresh();
    _uiUpdateTimer?.cancel();
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
  
  // Geçen süreyi formatlı olarak döndür
  String formatElapsedTime(String timestamp) {
    if (timestamp.isEmpty) return '00:00';
    
    try {
      final int elapsedSeconds = _kitchenViewModel.getElapsedTime(timestamp);
      
      // Negatif değerlere karşı koruma
      final int positiveElapsedSeconds = elapsedSeconds < 0 ? 0 : elapsedSeconds;
      
      // Saniyeyi dakika:saniye formatına dönüştür
      final int minutes = (positiveElapsedSeconds ~/ 60);
      final int seconds = positiveElapsedSeconds % 60;
      
      // İki basamaklı olarak göster
      final String minutesStr = minutes.toString().padLeft(2, '0');
      final String secondsStr = seconds.toString().padLeft(2, '0');
      
      return '$minutesStr:$secondsStr';
    } catch (e) {
      debugPrint('🔴 [Mutfak] Süre formatı hatası: $e');
      return '00:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;
    final bool isLargeTablet = screenWidth > 900;
    final double appBarTitleSize = isLargeTablet ? 20 : (isTablet ? 18 : 16);
    final EdgeInsets listPadding = EdgeInsets.all(isTablet ? 12 : 8);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: appBarTitleSize,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                    style: const TextStyle(fontSize: 14),
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
                style: TextStyle(fontSize: 14),
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
              padding: listPadding,
              itemCount: kitchenViewModel.orders.length,
              itemBuilder: (context, index) {
                final order = kitchenViewModel.orders[index];
                return _buildOrderCard(context, order, isTablet, isLargeTablet);
              },
            ),
          );
        }
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, KitchenOrder order, bool isTablet, bool isLargeTablet) {
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    final double headerIconSize = isLargeTablet ? 24 : (isTablet ? 22 : 20);
    final double userFontSize = isLargeTablet ? 17 : (isTablet ? 16 : 15);
    final double tableFontSize = isLargeTablet ? 15 : (isTablet ? 14 : 13);
    final double orderInfoFont = isLargeTablet ? 17 : (isTablet ? 16 : 15);
    final double buttonVPad = isLargeTablet ? 16 : (isTablet ? 14 : 12);
    final double cardMargin = isTablet ? 18 : 16;
    
    return Card(
      margin: EdgeInsets.only(bottom: cardMargin),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 16, vertical: isTablet ? 14 : 12),
            color: primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.white, size: headerIconSize),
                    SizedBox(width: isTablet ? 10 : 8),
                    Text(
                      order.userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: userFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Row(
                  children: [
                    Icon(Icons.table_bar, color: Colors.white, size: headerIconSize),
                    SizedBox(width: isTablet ? 10 : 8),
                    Text(
                      order.tableName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: tableFontSize,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderInfo,
                  style: TextStyle(
                    fontSize: orderInfoFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isTablet ? 10 : 8),
                const Divider(),
                ...order.products.map((product) => _buildProductItem(context, product, order, isTablet, isLargeTablet)).toList(),
                SizedBox(height: isTablet ? 10 : 8),
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
                          padding: EdgeInsets.symmetric(vertical: buttonVPad),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
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
                          padding: EdgeInsets.symmetric(vertical: buttonVPad),
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

  Widget _buildProductItem(BuildContext context, KitchenProduct product, KitchenOrder order, bool isTablet, bool isLargeTablet) {
    // Ürün hazırlanma süresini al
    String elapsedTimeStr = formatElapsedTime(product.proTime);
    
    // Süreye göre renk belirle
    Color timeColor = Colors.green;
    try {
      final int elapsedSeconds = _kitchenViewModel.getElapsedTime(product.proTime);
      
      // Negatif değerlere karşı koruma
      final int positiveElapsedSeconds = elapsedSeconds < 0 ? 0 : elapsedSeconds;
      
      if (positiveElapsedSeconds >= 300) { // 5 dakika ve üzeri
        timeColor = Colors.red;
      } else if (positiveElapsedSeconds >= 180) { // 3 dakika ve üzeri
        timeColor = Colors.orange;
      } else if (positiveElapsedSeconds >= 60) { // 1 dakika ve üzeri
        timeColor = Colors.yellow.shade700;
      }
    } catch (e) {
      // Hata durumunda varsayılan renk
    }
    
    final double timeFont = isLargeTablet ? 15 : (isTablet ? 14 : 13);
    final double rowVPad = isTablet ? 10 : 8;
    final double productFont = isLargeTablet ? 14 : (isTablet ? 13 : 13);
    final double actionIconSize = isLargeTablet ? 22 : (isTablet ? 20 : 18);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowVPad),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: timeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 10 : 8, vertical: isTablet ? 6 : 4),
            child: Text(
              elapsedTimeStr,
              style: TextStyle(
                fontSize: timeFont,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Text(
              '${product.proQty} ${product.proUnit} - ${product.proName}',
              style: TextStyle(fontSize: productFont),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red[400],
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: Icon(Icons.check, color: Colors.white, size: actionIconSize),
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