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
import 'package:pos701/models/customer_model.dart';
import 'package:pos701/models/order_model.dart' as order_model;
import 'package:pos701/views/tables_view.dart';

class BasketView extends StatefulWidget {
  final String tableName;
  final int? orderID;
  final String orderDesc;
  final int orderGuest;
  final Customer? selectedCustomer;
  final List<order_model.CustomerAddress>? customerAddresses;
  final int? tableID; // Masa ID
  final int orderType; // Sipariş türü: 1-Masa, 2-Paket, 3-Gel-Al
  
  const BasketView({
    Key? key,
    required this.tableName,
    this.orderID,
    this.orderDesc = '',
    this.orderGuest = 1,
    this.selectedCustomer,
    this.customerAddresses,
    this.tableID,
    this.orderType = 1, // Varsayılan değer: Masa siparişi
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
  bool _isProcessing = false; // İşlem yapılıp yapılmadığını takip etmek için flag
  bool _isSiparisOlusturuldu = false; // Sipariş oluşturuldu mu flag'i
  BasketViewModel? _basketViewModel; // BasketViewModel referansı
  String _orderDesc = ''; // Sipariş açıklaması
  int _orderGuest = 1; // Misafir sayısı

  @override
  void initState() {
    super.initState();
    _orderDesc = widget.orderDesc; // Sipariş açıklamasını başlangıçta al
    _orderGuest = widget.orderGuest; // Misafir sayısını başlangıçta al
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Erken aşamada BasketViewModel referansını al
    _basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
    
    // Başka masaya geçişlerde karışmaması için sepeti temizle
    // Artık bu işlemi burada değil, sadece _initializeData içinde yapacağız
    // _clearBasketOnNewTable();
  }
  
  // Bu metodu kaldırıyorum çünkü _initializeData içinde yapacağız
  // void _clearBasketOnNewTable() {
  //   if (_basketViewModel != null && !_basketViewModel!.isEmpty) {
  //     // Sadece yeni sipariş oluşturuyorsak sepeti temizle (orderID null ise)
  //     if (widget.orderID == null) {
  //       debugPrint('🧹 Yeni masa açıldı, önceki sepet temizleniyor...');
  //       // Future.microtask ile UI thread'inden çıkıp sepeti temizle
  //       Future.microtask(() {
  //         if (_basketViewModel != null && mounted) {
  //           _basketViewModel!.clearBasket();
  //           debugPrint('✅ Sepet temizlendi, yeni sipariş için hazır');
  //         }
  //       });
  //     }
  //   }
  // }

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
      
      // ÖNEMLİ: Sepet temizleme mantığını değiştiriyoruz
      // Artık otomatik temizleme yapmıyoruz. Sepete eklenen ürünleri koruyoruz.
      // Sadece mevcut bir siparişi görüntülüyorsak yeni sepet oluşturuyoruz
      
      if (args != null) {
        if (args.containsKey('tableID')) {
          _tableID = args['tableID'];
        }
        
        if (args.containsKey('orderID') && args['orderID'] != null) {
          _getSiparisDetayi(args['orderID']);
        } else if (widget.orderID != null) {
          _getSiparisDetayi(widget.orderID!);
        } else {
          // Sepeti koruyoruz! Temizlemiyoruz!
          debugPrint('📦 Sepet korunuyor. Sepetteki ürün sayısı: ${_basketViewModel?.totalQuantity ?? 0}');
          setState(() => _isLoading = false);
        }
      } else if (widget.orderID != null) {
        _getSiparisDetayi(widget.orderID!);
      } else {
        // Sepeti koruyoruz! Temizlemiyoruz!
        debugPrint('📦 Sepet korunuyor. Sepetteki ürün sayısı: ${_basketViewModel?.totalQuantity ?? 0}');
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
      
      // Sepeti temizle - çift eklemeyi önlemek için
      basketViewModel.clearBasket();
      debugPrint('🧹 Sepet temizlendi, yeni ürünler yüklenecek');
      
      final success = await orderViewModel.getSiparisDetayi(
        userToken: _userToken!,
        compID: _compID!,
        orderID: orderID,
      );
      
      if (success && orderViewModel.orderDetail != null) {
        // Sipariş detayları başarıyla alındı
        final orderDetail = orderViewModel.orderDetail!;
        debugPrint('✅ Sipariş detayları alındı. Ürün sayısı: ${orderDetail.products.length}');
        
        // API'den gelen sipariş tutarını güncelle
        debugPrint('💰 API sipariş tutarı: ${orderDetail.orderAmount}');
        basketViewModel.setOrderAmount(orderDetail.orderAmount);
        
        // Tahsil edilen tutar bilgilerini güncelle
        debugPrint('💰 Tahsil edilen tutar güncelleniyor: ${orderDetail.orderPayAmount}');
        basketViewModel.updateOrderPayAmount(orderDetail.orderPayAmount);
        
        // Kalan tutar hesaplaması
        final double kalanTutar = orderDetail.orderAmount - orderDetail.orderPayAmount - orderDetail.orderDiscount;
        debugPrint('💸 API değerlerinden kalan tutar hesaplandı: orderAmount(${orderDetail.orderAmount}) - orderPayAmount(${orderDetail.orderPayAmount}) - orderDiscount(${orderDetail.orderDiscount}) = $kalanTutar');
        
        // İndirim bilgisini güncelle
        if (orderDetail.orderDiscount > 0) {
          debugPrint('🔖 İndirim tutarı güncelleniyor: ${orderDetail.orderDiscount}');
          basketViewModel.applyDiscount(orderDetail.orderDiscount);
        }
        
        // Sipariş ürünlerini sepete ekle
        final sepetItems = orderViewModel.siparisUrunleriniSepeteAktar();
        
        // Sepeti doldur - Artık her ürün için ayrı eklemeler yapmıyoruz
        // Bunun yerine ürünleri doğrudan kendi miktarı ve opID'si ile ekliyoruz
        for (var item in sepetItems) {
          basketViewModel.addProductWithOpID(
            item.product, 
            item.proQty,
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

  Future<void> _createOrder(BasketViewModel basketViewModel) async {
    if (_userToken == null || _compID == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Kullanıcı bilgileri alınamadı';
      });
      return;
    }
    
    if (basketViewModel.isEmpty) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Sepet boş';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş oluşturmak için sepete ürün ekleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    debugPrint('🛒 Sipariş oluşturuluyor...');
    debugPrint('🛒 Sipariş tipi: ${widget.orderType}, Masa ID: ${widget.tableID}');
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // OrderViewModel oluştur
      final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
      
      // Müşteri bilgilerini kontrol et
      int custID = 0;
      String custName = '';
      String custPhone = '';
      List<dynamic> custAdrs = [];
      
      // Siparişte zaten müşteri bilgisi varsa veya eklenmişse
      if (widget.selectedCustomer != null) {
        custID = widget.selectedCustomer!.custID;
        custName = widget.selectedCustomer!.custName;
        custPhone = widget.selectedCustomer!.custPhone;
        
        if (widget.customerAddresses != null && widget.customerAddresses!.isNotEmpty) {
          custAdrs = widget.customerAddresses!;
        }
        
        debugPrint('👤 Müşteri bilgisi: ID: $custID, Ad: $custName, Tel: $custPhone, Adres sayısı: ${custAdrs.length}');
      } else {
        debugPrint('👤 Müşteri bilgisi yok');
      }
      
      // Sipariş oluştur
      final bool success = await orderViewModel.siparisSunucuyaGonder(
        userToken: _userToken!,
        compID: _compID!,
        tableID: widget.tableID ?? 0, // tableID null ise 0 gönder
        tableName: widget.tableName,
        sepetUrunleri: basketViewModel.items,
        orderType: widget.orderType, // Sipariş tipini ekle
        orderGuest: _orderGuest,
        orderDesc: _orderDesc,
        custID: custID,
        custName: custName,
        custPhone: custPhone,
        custAdrs: custAdrs,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _isSiparisOlusturuldu = success;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş başarıyla oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Sepeti temizle
        basketViewModel.clearBasket();
        
        // Ana sayfaya dönmek yerine, TablesView'a yönlendir
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TablesView(
              userToken: _userToken!,
              compID: _compID!,
              title: 'Masalar',
            ),
          ),
          (route) => false, // Tüm geçmiş sayfaları temizle
        );
      } else {
        setState(() {
          _errorMessage = orderViewModel.errorMessage ?? 'Sipariş oluşturulamadı';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Hata: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Aktif olmayan masa kontrolü
  bool _isInactiveTable() {
    // orderID null ise, bu aktif olmayan bir masa demektir
    return widget.orderID == null;
  }

  // Geri dönüş kontrolü - Kullanıcı geri tuşuna bastığında çalışır
  Future<bool> _onWillPop() async {
    // Sepeti temizlemiyoruz, sepetteki ürünleri koruyoruz
    // Kullanıcı ürün ekleyip sonra geri döndüğünde ürünlerin korunması gerekiyor
    debugPrint('⬅️ Sepetten çıkılıyor. Sepet korunacak. Ürün sayısı: ${_basketViewModel?.totalQuantity ?? 0}');
    return true; // Geri dönüşe izin ver
  }

  // Sayfadan çıkış durumunda sepeti temizleme kontrolü
  @override
  void dispose() {
    // Sepeti temizlemiyoruz, sepetteki ürünleri koruyoruz
    // Kullanıcı ürün ekleyip sonra geri döndüğünde ürünlerin korunması gerekiyor
    debugPrint('🔚 Sepet sayfası kapanıyor. Sepet korunacak. Ürün sayısı: ${_basketViewModel?.totalQuantity ?? 0}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(AppConstants.primaryColorValue),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.tableName.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (widget.orderID != null)
                Text("Sipariş #${widget.orderID}", style: const TextStyle(fontSize: 12)),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              // Sepeti temizlemiyoruz, sepetteki ürünleri koruyoruz
              // Kullanıcı ürün ekleyip sonra geri döndüğünde ürünlerin korunması gerekiyor
              debugPrint('❌ Sepet kapatılıyor. Sepet korunacak. Ürün sayısı: ${_basketViewModel?.totalQuantity ?? 0}');
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _showMenuDialog();
              }
            ),
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
                            fontSize: 20,
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
                                    fontSize: 12,
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
                                fontSize: 10,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // İnaktif masa uyarısı
                  if (_isInactiveTable())
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.blue.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Aktif olmayan bir masa için sipariş oluşturuyorsunuz. Sayfadan çıktığınızda sepet temizlenecektir.",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Sipariş Açıklaması (varsa göster)
                  if (_orderDesc.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.description, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sipariş Notu:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _orderDesc,
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Misafir Sayısı Bilgisi
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Misafir Sayısı:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_orderGuest',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                              style: TextStyle(fontSize: 16, color: Colors.grey),
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
                  Consumer<BasketViewModel>(
                    builder: (context, basketViewModel, child) {
                      // Sepet boşsa, toplam bilgileri gösterme
                      if (basketViewModel.isEmpty) {
                        return const SizedBox.shrink(); // Boş widget
                      }
                      
                      // Sepet içeriğini logla
                      double manuelToplam = 0;
                      for (var item in basketViewModel.items) {
                        debugPrint('🧮 [BASKET_VIEW] Ürün: ${item.product.proName}, Miktar: ${item.proQty}, Birim: ${item.birimFiyat}, Toplam: ${item.totalPrice}');
                        manuelToplam += item.totalPrice;
                      }
                      debugPrint('💲 [BASKET_VIEW] Manuel hesaplanan toplam: $manuelToplam');
                      debugPrint('💲 [BASKET_VIEW] ViewModel toplam: ${basketViewModel.totalAmount}');
                      debugPrint('💲 [BASKET_VIEW] API sipariş tutarı: ${basketViewModel.orderAmount}');
                      debugPrint('💰 [BASKET_VIEW] Tahsil edilen tutar: ${basketViewModel.orderPayAmount}');
                      debugPrint('💳 [BASKET_VIEW] İndirim tutarı: ${basketViewModel.discount}');
                      
                      // Manuel kalan hesapla
                      final manuelKalan = basketViewModel.orderAmount - basketViewModel.discount - basketViewModel.orderPayAmount;
                      debugPrint('💸 [BASKET_VIEW] Manuel kalan: $manuelKalan');
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              "Toplam Tutar",
                              "₺${basketViewModel.orderAmount.toStringAsFixed(2)}",
                            ),
                            _buildInfoRow(
                              "İndirim",
                              "₺${basketViewModel.discount.toStringAsFixed(2)}",
                            ),
                            _buildInfoRow(
                              "Tahsil Edilen",
                              "₺${basketViewModel.orderPayAmount.toStringAsFixed(2)}",
                            ),
                            _buildInfoRow(
                              "Kalan",
                              "₺${manuelKalan.toStringAsFixed(2)}",
                              isBold: true,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Alt Butonlar
                  SizedBox(
                    height: 90,
                    child: Row(
                      children: [
                        // Kaydet Butonu
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _createOrder(_basketViewModel!),
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
                                  style: const TextStyle(color: Colors.white, fontSize: 12)
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
                              
                              setState(() {
                                _isProcessing = true; // İşlem başladı
                              });
                              
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
                                      setState(() => _isSiparisOlusturuldu = true); // Ödeme yapıldı, sepeti temizleme
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
                                Text("Ödeme Al", style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        
                        // Yazdır Butonu
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isProcessing = true; // İşlem başladı
                              });
                            },
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
                                Text("Yazdır", style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBasketItem(BuildContext context, BasketItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () {
          if (_userToken != null && _compID != null) {
            setState(() {
              _isProcessing = true; // İşlem başladı
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailView(
                  userToken: _userToken!,
                  compID: _compID!,
                  postID: item.product.postID,
                  tableName: widget.tableName,
                  selectedProID: item.product.proID,
                  initialNote: item.proNote,
                  initialIsGift: item.isGift,
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
                setState(() => _isProcessing = true); // İşlem başladı
                Provider.of<BasketViewModel>(context, listen: false)
                    .decrementQuantity(item.product.proID);
              },
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.proQty.toString(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            
            _buildQuantityButton(
              icon: Icons.add,
              onPressed: () {
                setState(() => _isProcessing = true); // İşlem başladı
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.product.proName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (item.isGift)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.card_giftcard, color: Colors.red.shade700, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  'İkram',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Text(
                      "Birim Fiyat: ₺${item.product.proPrice}",
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    if (item.proNote.isNotEmpty)
                      Text(
                        "Not: ${item.proNote}",
                        style: TextStyle(fontSize: 10, color: Colors.blue.shade600, fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.isGift ? "₺0.00" : "₺${item.totalPrice.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: item.isGift ? Colors.red.shade700 : Colors.black,
                  ),
                ),
                  if (item.proQty > 1 && !item.isGift)
                  Text(
                    "${item.proQty} x ₺${(item.totalPrice / item.proQty).toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
              ],
            ),
            
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() => _isProcessing = true); // İşlem başladı
                Provider.of<BasketViewModel>(context, listen: false)
                    .removeProduct(item.product.proID, opID: item.opID);
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
    // Debug için sepet durumunu logla
    if (label == "Toplam Tutar") {
      debugPrint('🛒 [BASKET] Sepet _buildInfoRow: $label = $value');
      final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
      if (basketViewModel.items.isNotEmpty) {
        for (var item in basketViewModel.items) {
          debugPrint('📊 [BASKET] Item: ${item.product.proName}, Qty: ${item.proQty}, Birim: ${item.birimFiyat}, Toplam: ${item.totalPrice}');
        }
        debugPrint('💰 [BASKET] Toplam sepet tutarı: ${basketViewModel.totalAmount}');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
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
    
    setState(() {
      _isProcessing = true; // İşlem başladı
    });
    
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
            // Parçalı ödeme yapıldıysa, ödenmiş ürünleri sepetten çıkar
            // Not: Tam ödeme yapıldıysa tüm sepet temizlenir
            _refreshSiparisDetayi();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ödeme başarıyla alındı. Ödenen ürünler sepetten kaldırıldı.'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  // Sipariş detaylarını yeniden yükle (Ödeme sonrası)
  Future<void> _refreshSiparisDetayi() async {
    if (_userToken == null || _compID == null || widget.orderID == null) {
      debugPrint('⛔️ Ürün yenilemesi yapılamıyor: Kullanıcı bilgileri veya sipariş ID eksik');
      return;
    }
    
    setState(() => _isLoading = true);
    debugPrint('🔄 Ödeme sonrası sepet yenileniyor. OrderID: ${widget.orderID}');
    
    try {
      final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
      final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
      
      // Mevcut sepeti temizle
      basketViewModel.clearBasket();
      debugPrint('🧹 Sepet temizlendi, yeni ürünler yüklenecek');
      
      // Sipariş detaylarını yeniden yükle
      final success = await orderViewModel.getSiparisDetayi(
        userToken: _userToken!,
        compID: _compID!,
        orderID: widget.orderID!,
      );
      
      if (success && orderViewModel.orderDetail != null) {
        // Sipariş ürünlerini sepete ekle
        final sepetItems = orderViewModel.siparisUrunleriniSepeteAktar();
        debugPrint('📦 API\'den ${sepetItems.length} adet ürün alındı');
        
        if (sepetItems.isEmpty) {
          debugPrint('✅ Tüm ürünler ödenmiş, sepet boş kalacak');
        } else {
          // Sepeti doldur - Burada sadece ödenmemiş ürünler olmalı
          for (var item in sepetItems) {
            debugPrint('➕ Sepete ekleniyor: ${item.product.proName}, Miktar: ${item.proQty}, OpID: ${item.opID}');
            basketViewModel.addProductWithOpID(
              item.product, 
              item.proQty,
              item.opID
            );
          }
          debugPrint('✅ Sepet güncellendi. Yeni ürün sayısı: ${basketViewModel.items.length}');
        }
      } else {
        debugPrint('❌ Sipariş detayları alınamadı: ${orderViewModel.errorMessage}');
      }
    } catch (e) {
      debugPrint('🔴 Sipariş detayları yenilenemedi: $e');
    } finally {
      // İşlem tamamlandı, yükleme durumunu kapat
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Menü dialogu
  void _showMenuDialog() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final bool showKuverGarsoniye = userViewModel.userInfo?.company?.compKuverWaiter ?? false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        insetPadding: EdgeInsets.zero,
        alignment: Alignment.topRight,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Color(AppConstants.primaryColorValue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Menü',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  children: [
                    _buildMenuItem(
                      icon: Icons.description,
                      title: 'NOT',
                      onTap: () {
                        Navigator.of(context).pop();
                        _showOrderDescDialog();
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.people,
                      title: 'Misafir Sayısı',
                      onTap: () {
                        Navigator.of(context).pop();
                        _showGuestCountDialog();
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Müşteri',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Müşteri işlemi - Sepette müşteri ekleme özelliği yoksa burada uyarı gösterilebilir
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Müşteri ekleme işlemi bu ekrandan yapılamaz'))
                        );
                      },
                    ),
                    
                    if (showKuverGarsoniye) const Divider(height: 1),
                    
                    if (showKuverGarsoniye)
                      _buildMenuItem(
                        icon: Icons.attach_money,
                        title: 'Kuver Ücreti Ekle',
                        onTap: () {
                          Navigator.of(context).pop();
                          // Kuver ücreti işlemi
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kuver ücreti ekleme özelliği henüz aktif değil'))
                          );
                        },
                      ),
                    
                    if (showKuverGarsoniye) const Divider(height: 1),
                    
                    if (showKuverGarsoniye)
                      _buildMenuItem(
                        icon: Icons.monetization_on,
                        title: 'Garsoniye Ücreti Ekle',
                        onTap: () {
                          Navigator.of(context).pop();
                          // Garsoniye ücreti işlemi
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Garsoniye ücreti ekleme özelliği henüz aktif değil'))
                          );
                        },
                      ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.print,
                      title: 'Yazdır',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Yazdır işlemi
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yazdırma işlemi başlatılıyor...'))
                        );
                      },
                    ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.qr_code,
                      title: 'Barkod',
                      onTap: () {
                        Navigator.of(context).pop();
                        // Barkod işlemi
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Barkod görüntüleme özelliği henüz aktif değil'))
                        );
                      },
                    ),
                    
                    if (widget.orderID != null) ...[
                      const Divider(height: 1),
                      _buildMenuItem(
                        icon: Icons.close,
                        title: 'Sipariş İptal',
                        onTap: () {
                          Navigator.of(context).pop();
                          _showCancelOrderDialog();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }

  // Sipariş açıklaması ekleme diyaloğu
  void _showOrderDescDialog() {
    final TextEditingController noteController = TextEditingController(text: _orderDesc);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sipariş Notu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Sipariş için not ekleyin',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu not sipariş ile ilişkilendirilecek ve mutfağa iletilecektir.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _orderDesc = noteController.text.trim();
              });
              Navigator.of(context).pop();
              
              if (_orderDesc.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sipariş notu kaydedildi'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConstants.primaryColorValue),
            ),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Misafir sayısı seçme diyaloğu
  void _showGuestCountDialog() {
    int tempGuestCount = _orderGuest;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Misafir Sayısı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Color(AppConstants.primaryColorValue)),
                    onPressed: () {
                      if (tempGuestCount > 1) {
                        setState(() {
                          tempGuestCount--;
                        });
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$tempGuestCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Color(AppConstants.primaryColorValue)),
                    onPressed: () {
                      setState(() {
                        tempGuestCount++;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Masadaki misafir sayısını belirleyin',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _orderGuest = tempGuestCount;
                });
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Misafir sayısı: $_orderGuest'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConstants.primaryColorValue),
              ),
              child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Sipariş iptali için onay diyaloğu
  void _showCancelOrderDialog() {
    final TextEditingController cancelDescController = TextEditingController();
    
    // Sipariş ID kontrolü
    if (widget.orderID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İptal edilecek aktif bir sipariş bulunmuyor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siparişi İptal Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu işlem mevcut siparişi iptal edecektir. Devam etmek istiyor musunuz?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cancelDescController,
              decoration: const InputDecoration(
                hintText: 'İptal nedeni (opsiyonel)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // İptal işlemi gerçeği burada yapılabilir veya sadece bildirim gösterilebilir
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sipariş iptal edildi: ${cancelDescController.text}'),
                  backgroundColor: Colors.red,
                )
              );
              
              // Ana sayfaya dön
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Siparişi İptal Et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 