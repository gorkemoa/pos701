import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/basket_viewmodel.dart';
import 'package:pos701/models/basket_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/views/product_detail_view.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/viewmodels/order_viewmodel.dart';
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
  final int? tableID;
  final int orderType;
  final int isKuver;
  final int isWaiter;
  
  const BasketView({
    super.key,
    required this.tableName,
    this.orderID,
    this.orderDesc = '',
    this.orderGuest = 1,
    this.selectedCustomer,
    this.customerAddresses,
    this.tableID,
    this.orderType = 1,
    this.isKuver = 0,
    this.isWaiter = 0,
  });

  @override
  State<BasketView> createState() => _BasketViewState();
}

class _BasketViewState extends State<BasketView> {
  String? _userToken;
  int? _compID;
  int? _tableID;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isProcessing = false;
  bool _isSiparisOlusturuldu = false;
  BasketViewModel? _basketViewModel;
  String _orderDesc = '';
  int _orderGuest = 1;
  int _isKuver = 0;
  int _isWaiter = 0;

  @override
  void initState() {
    super.initState();
    _orderDesc = widget.orderDesc;
    _orderGuest = widget.orderGuest;
    _isKuver = widget.isKuver;
    _isWaiter = widget.isWaiter;
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
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
    
    _isKuver = widget.isKuver;
    _isWaiter = widget.isWaiter;
    
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
      
      final success = await orderViewModel.getSiparisDetayi(
        userToken: _userToken!,
        compID: _compID!,
        orderID: orderID,
      );
      
      if (success && orderViewModel.orderDetail != null) {
        final orderDetail = orderViewModel.orderDetail!;
        
        setState(() {
          _isKuver = orderDetail.isKuver;
          _isWaiter = orderDetail.isWaiter;
        });
        
        basketViewModel.setOrderAmount(orderDetail.orderAmount);
        basketViewModel.updateOrderPayAmount(orderDetail.orderPayAmount);
        
        if (orderDetail.orderDiscount > 0) {
          basketViewModel.applyDiscount(orderDetail.orderDiscount);
        }
        
        final sepetItems = orderViewModel.siparisUrunleriniSepeteAktar();
        
        for (var item in sepetItems) {
          if (item.opID > 0) {
            basketViewModel.addProductWithOpID(
              item.product, 
              item.proQty,
              item.opID,
              proNote: item.proNote,
              isGift: item.isGift
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = orderViewModel.errorMessage ?? 'Sipariş detayları alınamadı.';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Sipariş detayları alınırken hata oluştu: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final orderViewModel = Provider.of<OrderViewModel>(context, listen: false);
      
      int custID = 0;
      String custName = '';
      String custPhone = '';
      List<dynamic> custAdrs = [];
      
      if (widget.selectedCustomer != null) {
        custID = widget.selectedCustomer!.custID;
        custName = widget.selectedCustomer!.custName;
        custPhone = widget.selectedCustomer!.custPhone;
        
        if (widget.customerAddresses != null && widget.customerAddresses!.isNotEmpty) {
          custAdrs = widget.customerAddresses!;
        }
      }
      
      int tableID = widget.tableID ?? 0;
      int kuverDurumu = _isKuver;
      int garsoniyeDurumu = _isWaiter;
      
      if (widget.orderID != null) {
        final success = await orderViewModel.siparisGuncelle(
          userToken: _userToken!,
          compID: _compID!,
          orderID: widget.orderID!,
          sepetUrunleri: basketViewModel.items,
          orderDesc: _orderDesc,
          orderGuest: _orderGuest,
          custID: custID,
          custName: custName,
          custPhone: custPhone,
          custAdrs: custAdrs,
          isKuver: kuverDurumu,
          isWaiter: garsoniyeDurumu,
        );
        
        _handleOrderResult(success, orderViewModel, true);
      } else {
        final success = await orderViewModel.siparisSunucuyaGonder(
          userToken: _userToken!,
          compID: _compID!,
          tableID: tableID,
          tableName: widget.tableName,
          sepetUrunleri: basketViewModel.items,
          orderType: widget.orderType,
          orderDesc: _orderDesc,
          orderGuest: _orderGuest,
          custID: custID,
          custName: custName,
          custPhone: custPhone,
          custAdrs: custAdrs,
          isKuver: kuverDurumu,
          isWaiter: garsoniyeDurumu,
        );
        
        _handleOrderResult(success, orderViewModel, false);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isLoading = false;
        _errorMessage = 'Sipariş gönderilirken hata oluştu: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleOrderResult(bool success, OrderViewModel orderViewModel, bool isUpdate) {
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
      
      _basketViewModel!.clearBasket();
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => TablesView(
            userToken: _userToken!,
            compID: _compID!,
            title: 'Masalar',
          ),
        ),
        (route) => false,
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
  }

  bool _isInactiveTable() {
    return widget.orderID == null;
  }

  Future<bool> _onWillPop() async {
    if (_isSiparisOlusturuldu) {
      final basketViewModel = Provider.of<BasketViewModel>(context, listen: false);
      basketViewModel.clearBasket();
    }
    return true;
  }

  @override
  void dispose() {
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              if (widget.orderID != null)
                Text("Sipariş #${widget.orderID}", style: const TextStyle(fontSize: 13)),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
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
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${widget.tableName} Siparişi",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
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
                                    fontSize: 10,
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
                  
                  if (widget.orderID != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: Colors.amber.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Mevcut siparişi düzenliyorsunuz. Güncellemek için tüm ürünleri ekleyin ve Güncelle butonuna basın.",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_isInactiveTable())
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: Colors.blue.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Aktif olmayan bir masa için sipariş oluşturuyorsunuz. Sayfadan çıktığınızda sepet temizlenecektir.",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_orderDesc.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sipariş Notu:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _orderDesc,
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Misafir Sayısı:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_orderGuest',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: Consumer<BasketViewModel>(
                      builder: (context, basketViewModel, child) {
                        if (basketViewModel.isEmpty) {
                          return const Center(
                            child: Text(
                              "Sepetiniz boş",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          );
                        }
                        
                        // Sepet öğelerini mevcut ve yeni eklenmiş olarak ayır
                        final existingItems = basketViewModel.items
                            .where((item) => !basketViewModel.newlyAddedProductIds.contains(item.product.proID))
                            .toList();
                            
                        final newItems = basketViewModel.items
                            .where((item) => basketViewModel.newlyAddedProductIds.contains(item.product.proID))
                            .toList();
                        
                        return ListView(
                          children: [
                            if (existingItems.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Text(
                                  "Mevcut Sipariş",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(AppConstants.primaryColorValue),
                                  ),
                                ),
                              ),
                              ...existingItems.map((item) => _buildBasketItem(context, item)),
                            ],
                            
                            if (existingItems.isNotEmpty && newItems.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 12.0),
                                  height: 1,
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            
                            if (newItems.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle, size: 16, color: Colors.green.shade700),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Yeni Eklenenler",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...newItems.map((item) => _buildBasketItem(context, item, isNewItem: true)),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                  
                  Consumer<BasketViewModel>(
                    builder: (context, basketViewModel, child) {
                      if (basketViewModel.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      double manuelToplam = 0;
                      for (var item in basketViewModel.items) {
                        manuelToplam += item.totalPrice;
                      }
                      
                      final manuelKalan = basketViewModel.orderAmount - basketViewModel.discount - basketViewModel.orderPayAmount;
                      
                      return Column(
                        children: [
                          if (_isKuver == 1 || _isWaiter == 1)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Column(
                                children: [
                                  if (_isKuver == 1)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.attach_money, color: Colors.amber.shade800, size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Kuver Ücreti:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9,
                                              color: Colors.amber.shade800,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'AKTİF',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_isWaiter == 1)
                                    Row(
                                      children: [
                                        Icon(Icons.monetization_on, color: Colors.amber.shade800, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Garsoniye Ücreti:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'AKTİF',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          
                          Container(
                        padding: const EdgeInsets.all(10),
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
                          ),
                        ],
                      );
                    },
                  ),
                  
                  SizedBox(
                    height: 70,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _createOrder(_basketViewModel!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(AppConstants.primaryColorValue),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  widget.orderID != null ? "Güncelle" : "Kaydet", 
                                  style: const TextStyle(color: Colors.white, fontSize: 11)
                                ),
                              ],
                            ),
                          ),
                        ),
                        
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
                                _isProcessing = true;
                              });
                              
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PaymentView(
                                    userToken: _userToken!,
                                    compID: _compID!,
                                    orderID: widget.orderID!,
                                    totalAmount: basketViewModel.totalAmount,
                                    basketItems: basketViewModel.items,
                                    onPaymentSuccess: () {
                                      setState(() => _isSiparisOlusturuldu = true);
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
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.payment, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text("Ödeme Al", style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                        
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isProcessing = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(AppConstants.primaryColorValue),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.print, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text("Yazdır", style: TextStyle(color: Colors.white, fontSize: 11)),
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

  Widget _buildBasketItem(BuildContext context, BasketItem item, {bool isNewItem = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        onTap: () {
          if (_userToken != null && _compID != null) {
            setState(() {
              _isProcessing = true;
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
        child: Container(
          decoration: BoxDecoration(
            color: isNewItem ? Colors.green.shade50 : null,
            border: isNewItem 
                ? Border.all(color: Colors.green.shade200, width: 1)
                : null,
            borderRadius: isNewItem ? BorderRadius.circular(8) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                _buildQuantityButton(
                  icon: Icons.remove,
                  onPressed: () {
                    setState(() => _isProcessing = true);
                    Provider.of<BasketViewModel>(context, listen: false)
                        .decrementQuantity(item.product.proID);
                  },
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    item.proQty.toString(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                
                _buildQuantityButton(
                  icon: Icons.add,
                  onPressed: () {
                    setState(() => _isProcessing = true);
                    Provider.of<BasketViewModel>(context, listen: false)
                        .incrementQuantity(item.product.proID);
                  },
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.product.proName,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (item.isGift)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (isNewItem)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Yeni',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          "Birim Fiyat: ₺${item.product.proPrice}",
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                        ),
                        if (item.proNote.isNotEmpty)
                          Text(
                            "Not: ${item.proNote}",
                            style: TextStyle(fontSize: 9, color: Colors.blue.shade600, fontStyle: FontStyle.italic),
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
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: item.isGift ? Colors.red.shade700 : Colors.black,
                      ),
                    ),
                      if (item.proQty > 1 && !item.isGift)
                      Text(
                        "${item.proQty} x ₺${(item.totalPrice / item.proQty).toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      ),
                  ],
                ),
                
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _isProcessing = true);
                    Provider.of<BasketViewModel>(context, listen: false)
                        .removeProduct(item.product.proID, opID: item.opID);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleKuverDurumu() {
    setState(() {
      _isKuver = _isKuver == 0 ? 1 : 0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isKuver == 1 ? 'Kuver ücreti eklendi' : 'Kuver ücreti kaldırıldı'),
        backgroundColor: _isKuver == 1 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _toggleGarsoniyeDurumu() {
    setState(() {
      _isWaiter = _isWaiter == 0 ? 1 : 0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isWaiter == 1 ? 'Garsoniye ücreti eklendi' : 'Garsoniye ücreti kaldırıldı'),
        backgroundColor: _isWaiter == 1 ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
                        fontSize: 16,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Müşteri ekleme işlemi bu ekrandan yapılamaz'))
                        );
                      },
                    ),
                    
                    if (showKuverGarsoniye) const Divider(height: 1),
                    
                    if (showKuverGarsoniye)
                      _buildMenuItem(
                        icon: _isKuver == 0 ? Icons.attach_money : Icons.money_off,
                        title: _isKuver == 0 ? 'Kuver Ücreti Ekle' : 'Kuver Ücretini Kaldır',
                        onTap: () {
                          Navigator.of(context).pop();
                          _toggleKuverDurumu();
                        },
                      ),
                    
                    if (showKuverGarsoniye) const Divider(height: 1),
                    
                    if (showKuverGarsoniye)
                      _buildMenuItem(
                        icon: _isWaiter == 0 ? Icons.monetization_on : Icons.money_off_csred,
                        title: _isWaiter == 0 ? 'Garsoniye Ücreti Ekle' : 'Garsoniye Ücretini Kaldır',
                        onTap: () {
                          Navigator.of(context).pop();
                          _toggleGarsoniyeDurumu();
                        },
                      ),
                    
                    const Divider(height: 1),
                    
                    _buildMenuItem(
                      icon: Icons.print,
                      title: 'Yazdır',
                      onTap: () {
                        Navigator.of(context).pop();
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
      title: Text(title, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  void _showOrderDescDialog() {
    final TextEditingController noteController = TextEditingController(text: _orderDesc);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sipariş Notu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                fontSize: 9,
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

  void _showGuestCountDialog() {
    int tempGuestCount = _orderGuest;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Misafir Sayısı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                        fontSize: 18,
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
                  fontSize: 10,
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

  void _showCancelOrderDialog() {
    final TextEditingController cancelDescController = TextEditingController();
    
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
        title: const Text('Siparişi İptal Et', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu işlem mevcut siparişi iptal edecektir. Devam etmek istiyor musunuz?',
              style: TextStyle(fontSize: 12),
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
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sipariş iptal edildi: ${cancelDescController.text}'),
                  backgroundColor: Colors.red,
                )
              );
              
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