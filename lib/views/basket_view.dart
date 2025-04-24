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
import 'package:pos701/models/user_model.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/views/payment_view.dart';

class BasketView extends StatefulWidget {
  final String tableName;
  final int? orderID;
  
  const BasketView({
    Key? key,
    required this.tableName,
    this.orderID,
  }) : super(key: key);

  @override
  State<BasketView> createState() => _BasketViewState();
}

class _BasketViewState extends State<BasketView> {
  String? _userToken;
  int? _compID;
  int? _tableID;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    if (userViewModel.userInfo != null) {
      _userToken = userViewModel.userInfo?.userToken;
      _compID = userViewModel.userInfo?.compID;
    } else {
      await userViewModel.loadUserInfo();
      if (userViewModel.userInfo != null) {
        _userToken = userViewModel.userInfo?.userToken;
        _compID = userViewModel.userInfo?.compID;
      }
    }
    
    // TableView'den gelen bilgileri al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args.containsKey('tableID')) {
          _tableID = args['tableID'];
        }
        
        if (args.containsKey('orderID') && args['orderID'] != null) {
          _getSiparisDetayi(args['orderID']);
        } else if (widget.orderID != null) {
          _getSiparisDetayi(widget.orderID!);
        } else {
          setState(() => _isLoading = false);
        }
      } else if (widget.orderID != null) {
        _getSiparisDetayi(widget.orderID!);
      } else {
        setState(() => _isLoading = false);
      }
    });
  }
  
  Future<void> _getSiparisDetayi(int orderID) async {
    if (_userToken == null || _compID == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kullanıcı bilgileri alınamadı.';
      });
      return;
    }
    
    try {
      final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
      final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
      
      debugPrint('🔄 Sipariş detayları getiriliyor. OrderID: $orderID');
      
      // Sepeti temizleme kaldırıldı - mevcut eklenen ürünlerin korunması için
      
      final success = await orderViewModel.getSiparisDetayi(
        userToken: _userToken!,
        compID: _compID!,
        orderID: orderID,
      );
      
      if (success && orderViewModel.orderDetail != null) {
        // Sipariş detayları başarıyla alındı
        debugPrint('✅ Sipariş detayları alındı. Ürün sayısı: ${orderViewModel.orderDetail!.products.length}');
        
        // Sipariş ürünlerini sepete ekle
        final sepetItems = orderViewModel.siparisUrunleriniSepeteAktar();
        
        // Sepeti doldur - Artık her ürün için ayrı eklemeler yapmıyoruz
        // Bunun yerine ürünleri doğrudan kendi miktarı ve opID'si ile ekliyoruz
        for (var item in sepetItems) {
          basketViewModel.addProductWithOpID(
            item.product, 
            item.quantity,
            item.opID
          );
        }
        
        debugPrint('✅ Sepete ${basketViewModel.totalQuantity} adet ürün eklendi.');
      } else {
        // Hata mesajını göster
        setState(() {
          _errorMessage = orderViewModel.errorMessage ?? 'Sipariş detayları alınamadı.';
        });
        
        // Kullanıcıya hata mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        debugPrint('⛔️ Sipariş detayları alınamadı: $_errorMessage');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Sipariş detayları alınırken hata oluştu: $e';
      });
      
      // Kullanıcıya hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      debugPrint('🔴 Sipariş detayları alınırken hata: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _siparisGonder() async {
    if (_userToken == null || _compID == null || _tableID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı veya masa bilgileri alınamadı.'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
    
    if (basketViewModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sepette ürün bulunmamaktadır.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
    
    // Mevcut sipariş mi yoksa yeni sipariş mi olduğunu kontrol et
    final bool success = widget.orderID != null 
        ? await _siparisGuncelle(orderViewModel, basketViewModel)
        : await _yeniSiparisOlustur(orderViewModel, basketViewModel);
    
    setState(() => _isLoading = false);
    
    if (success) {
      basketViewModel.clearBasket();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.orderID != null ? 'Sipariş başarıyla güncellendi.' : 'Sipariş başarıyla oluşturuldu.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.orderID != null 
              ? 'Sipariş güncellenemedi: ${orderViewModel.errorMessage ?? "Bilinmeyen hata"}'
              : 'Sipariş oluşturulamadı: ${orderViewModel.errorMessage ?? "Bilinmeyen hata"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Yeni sipariş oluşturma işlemi
  Future<bool> _yeniSiparisOlustur(OrderViewModel orderViewModel, BasketViewModel basketViewModel) async {
    return await orderViewModel.siparisSunucuyaGonder(
      userToken: _userToken!,
      compID: _compID!,
      tableID: _tableID!,
      tableName: widget.tableName,
      sepetUrunleri: basketViewModel.items,
      orderGuest: 1,
      kuverQty: 1,
    );
  }
  
  /// Mevcut siparişi güncelleme işlemi
  Future<bool> _siparisGuncelle(OrderViewModel orderViewModel, BasketViewModel basketViewModel) async {
    debugPrint('🔄 Sipariş güncelleniyor. OrderID: ${widget.orderID}');
    
    return await orderViewModel.siparisGuncelle(
      userToken: _userToken!,
      compID: _compID!,
      orderID: widget.orderID!,
      sepetUrunleri: basketViewModel.items,
      orderGuest: 1,
      kuverQty: 1,
    );
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.orderID != null)
              Text("Sipariş #${widget.orderID}", style: const TextStyle(fontSize: 14)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${widget.tableName} Siparişi",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      // Sipariş ID varsa sipariş detaylarını göster
                      if (widget.orderID != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Color(AppConstants.primaryColorValue).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_note, 
                                size: 18, 
                                color: Color(AppConstants.primaryColorValue),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "#${widget.orderID}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(AppConstants.primaryColorValue),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Sipariş güncelleme bilgi mesajı
                if (widget.orderID != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.amber.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Mevcut siparişi düzenliyorsunuz. Güncellemek için tüm ürünleri ekleyin ve Güncelle butonuna basın.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
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
                            style: TextStyle(fontSize: 18, color: Colors.grey),
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
                          _buildInfoRow(
                            "Toplam Tutar",
                            "₺${basketViewModel.totalAmount.toStringAsFixed(2)}",
                          ),
                          _buildInfoRow(
                            "İndirim",
                            "₺${basketViewModel.discount.toStringAsFixed(2)}",
                          ),
                          _buildInfoRow(
                            "Tahsil Edilen",
                            "₺${basketViewModel.collectedAmount.toStringAsFixed(2)}",
                          ),
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
                SizedBox(
                  height: 90,
                  child: Row(
                    children: [
                      // Kaydet Butonu
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _siparisGonder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(AppConstants.primaryColorValue),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                widget.orderID != null ? "Güncelle" : "Kaydet", 
                                style: const TextStyle(color: Colors.white, fontSize: 14)
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Ödeme Al Butonu
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.orderID != null ? () {
                            if (_userToken == null || _compID == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ödeme işlemi için gerekli bilgiler eksik.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
                            
                            if (basketViewModel.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sepette ürün bulunmamaktadır.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            // Doğrudan ödeme sayfasına git
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PaymentView(
                                  userToken: _userToken!,
                                  compID: _compID!,
                                  orderID: widget.orderID!,
                                  totalAmount: basketViewModel.totalAmount,
                                  basketItems: basketViewModel.items,
                                  onPaymentSuccess: () {
                                    basketViewModel.clearBasket();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ödeme başarıyla alındı.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.orderID != null 
                                ? Color(AppConstants.primaryColorValue)
                                : Colors.grey,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payment, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text("Ödeme Al", style: TextStyle(color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      
                      // Yazdır Butonu
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(AppConstants.primaryColorValue),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.print, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text("Yazdır", style: TextStyle(color: Colors.white, fontSize: 14)),
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
          }
        },
        child: Row(
          children: [
            _buildQuantityButton(
              icon: Icons.remove,
              onPressed: () {
                Provider.of<BasketViewModel>(context, listen: false)
                    .decrementQuantity(item.product.proID);
              },
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.quantity.toString(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            _buildQuantityButton(
              icon: Icons.add,
              onPressed: () {
                Provider.of<BasketViewModel>(context, listen: false)
                    .incrementQuantity(item.product.proID);
              },
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.proName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Birim Fiyat: ₺${item.product.proPrice}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₺${item.totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (item.quantity > 1)
                  Text(
                    "${item.quantity} x ₺${(item.totalPrice / item.quantity).toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            
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

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
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


  /// Seçilen ödeme tipi ile ödeme işlemini gerçekleştir
  Future<void> _processPayment(PaymentType paymentType) async {
    if (_userToken == null || _compID == null || widget.orderID == null) {
      return;
    }
    
    // Ödeme sayfasını göster
    final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentView(
          userToken: _userToken!,
          compID: _compID!,
          orderID: widget.orderID!,
          totalAmount: basketViewModel.totalAmount,
          basketItems: basketViewModel.items,
          onPaymentSuccess: () {
            // Ödeme başarılı olduğunda çağrılacak
            basketViewModel.clearBasket();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ödeme başarıyla alındı.'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }
} 