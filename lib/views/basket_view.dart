import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/basket_viewmodel.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/views/product_detail_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/viewmodels/order_viewmodel.dart';

class BasketView extends StatefulWidget {
  final String tableName;
  
  const BasketView({
    Key? key,
    required this.tableName,
  }) : super(key: key);

  @override
  State<BasketView> createState() => _BasketViewState();
}

class _BasketViewState extends State<BasketView> {
  String? _userToken;
  int? _compID;
  bool _isUserDataLoaded = false;
  int? _tableID;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // TableView'den gelen tableID'yi alıyorum
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('tableID')) {
      setState(() {
        _tableID = args['tableID'];
      });
      debugPrint('🔵 Alınan tableID: $_tableID');
    }
  }

  Future<void> _loadUserData() async {
    try {
      // UserViewModel'den kullanıcı bilgilerini al
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      
      if (userViewModel.userInfo != null) {
        setState(() {
          _userToken = userViewModel.userInfo?.userToken;
          _compID = userViewModel.userInfo?.compID;
          _isUserDataLoaded = true;
        });
        
        // Kontrol için log yazalım
        debugPrint('UserVM\'den: userToken: $_userToken, compID: $_compID');
      } else {
        // Eğer UserViewModel'de bilgi yoksa yüklemeyi deneyelim
        final loadSuccess = await userViewModel.loadUserInfo();
        if (loadSuccess && userViewModel.userInfo != null) {
          setState(() {
            _userToken = userViewModel.userInfo?.userToken;
            _compID = userViewModel.userInfo?.compID;
            _isUserDataLoaded = true;
          });
          debugPrint('UserVM yüklendikten sonra: userToken: $_userToken, compID: $_compID');
        } else {
          debugPrint('UserViewModel\'den kullanıcı bilgileri yüklenemedi');
          // UserViewModel başarısız olursa SharedPreferences'a bakalım
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            _userToken = prefs.getString(AppConstants.tokenKey);
            _compID = prefs.getInt(AppConstants.companyIdKey);
            _isUserDataLoaded = true;
          });
          debugPrint('SharedPreferences\'dan: userToken: $_userToken, compID: $_compID');
        }
      }
      
      if (_userToken == null || _compID == null) {
        debugPrint('Kullanıcı bilgileri bulunamadı');
        // Hemen gösterme, kullanıcı gerçekten bir işlem yapmaya çalıştığında göster
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgileri yüklenirken hata oluştu: $e');
      setState(() {
        _isUserDataLoaded = true;
      });
    }
  }

  Future<void> _siparisGonder() async {
    if (_userToken == null || _compID == null || _tableID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı veya masa bilgileri alınamadı.')),
      );
      return;
    }
    
    final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
    
    if (basketViewModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sepette ürün bulunmamaktadır.')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
    
    final success = await orderViewModel.siparisSunucuyaGonder(
      userToken: _userToken!,
      compID: _compID!,
      tableID: _tableID!,
      tableName: widget.tableName,
      sepetUrunleri: basketViewModel.items,
      orderGuest: 1, // Varsayılan değer
      kuverQty: 1, // Varsayılan değer
    );
    
    setState(() {
      _isLoading = false;
    });
    
    if (success) {
      // Sepeti temizle
      basketViewModel.clearBasket();
      
      // Başarılı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş başarıyla oluşturuldu.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Ana sayfaya dön
      Navigator.of(context).pop();
    } else {
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş oluşturulamadı: ${orderViewModel.errorMessage ?? "Bilinmeyen hata"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(AppConstants.primaryColorValue),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tableName.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Başlık
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.tableName + " Siparişi",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                
                // Sepet Öğeleri Listesi
                Expanded(
                  child: Consumer<BasketViewModel>(
                    builder: (context, basketViewModel, child) {
                      if (basketViewModel.isEmpty) {
                        return const Center(
                          child: Text(
                            "Sepetiniz boş",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      
                      return ListView.separated(
                        itemCount: basketViewModel.items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = basketViewModel.items[index];
                          return _buildBasketItem(context, item);
                        },
                      );
                    },
                  ),
                ),
                
                // Toplam Bilgileri
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Consumer<BasketViewModel>(
                    builder: (context, basketViewModel, child) {
                      return Column(
                        children: [
                          // Toplam Tutar Satırı
                          _buildInfoRow(
                            "Toplam Tutar",
                            "₺${basketViewModel.totalAmount.toStringAsFixed(2)}",
                          ),
                          
                          // İndirim Satırı
                          _buildInfoRow(
                            "İndirim",
                            "₺${basketViewModel.discount.toStringAsFixed(2)}",
                          ),
                          
                          // Tahsil Edilen Satırı
                          _buildInfoRow(
                            "Tahsil Edilen",
                            "₺${basketViewModel.collectedAmount.toStringAsFixed(2)}",
                          ),
                          
                          // Kalan Satırı
                          _buildInfoRow(
                            "Kalan",
                            "₺${basketViewModel.remainingAmount.toStringAsFixed(2)}",
                            isBold: true,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                // Alt Butonlar
                Container(
                  height: 90,
                  child: Row(
                    children: [
                      // Kaydet Butonu
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _siparisGonder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(AppConstants.primaryColorValue),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Kaydet",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Ödeme Al Butonu
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                           
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(AppConstants.primaryColorValue),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payment, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                "Ödeme Al",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Yazdır Butonu
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                         
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(AppConstants.primaryColorValue),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.print, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                "Yazdır",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBasketItem(BuildContext context, BasketItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () {
          if (_userToken != null && _compID != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailView(
                  userToken: _userToken!,
                  compID: _compID!,
                  postID: item.product.postID,
                  tableName: widget.tableName,
                  selectedProID: item.product.proID,
                ),
              ),
            );
          } else {
          }
        },
        child: Row(
          children: [
            // Azaltma Butonu
            _buildQuantityButton(
              icon: Icons.remove,
              onPressed: () {
                Provider.of<BasketViewModel>(context, listen: false)
                    .decrementQuantity(item.product.proID);
              },
            ),
            
            // Miktar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.quantity.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Arttırma Butonu
            _buildQuantityButton(
              icon: Icons.add,
              onPressed: () {
                Provider.of<BasketViewModel>(context, listen: false)
                    .incrementQuantity(item.product.proID);
              },
            ),
            
            // Ürün Adı
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.proName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Birim Fiyat: ₺${item.product.proPrice}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Ürün Fiyatı
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₺${item.totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.quantity > 1)
                  Text(
                    "${item.quantity} x ₺${(item.totalPrice / item.quantity).toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            
            // Silme Butonu
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Provider.of<BasketViewModel>(context, listen: false)
                    .removeProduct(item.product.proID);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 