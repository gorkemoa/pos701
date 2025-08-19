import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/order_list_viewmodel.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/order_model.dart';
import 'package:pos701/widgets/app_drawer.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:pos701/main.dart' as app;
import 'package:pos701/views/payment_view.dart';
import 'package:pos701/viewmodels/order_viewmodel.dart';

class OrderListView extends StatefulWidget {
  final String userToken;
  final int compID;

  const OrderListView({
    Key? key,
    required this.userToken,
    required this.compID,
  }) : super(key: key);

  @override
  State<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends State<OrderListView> with SingleTickerProviderStateMixin {
  late OrderListViewModel _viewModel = OrderListViewModel();
  final AppLogger _logger = AppLogger();
  late TabController _tabController;
  final List<Tab> _tabs = [
    const Tab(text: 'Tümü'),
    const Tab(text: 'Hazır'),
    const Tab(text: 'Tamamlanan'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _ensureFirebaseInitialized();
    _loadData();
  }

  Future<void> _ensureFirebaseInitialized() async {
    // Global fonksiyonu kullanarak Firebase kontrolü yap
    final bool isInitialized = await app.ensureFirebaseInitialized();
    if (!isInitialized) {
      _logger.e('Firebase başlatılamadı, bazı özellikler çalışmayabilir');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim servisi başlatılamadı. Bazı özellikler çalışmayabilir.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    await _viewModel.getOrderList(
      userToken: widget.userToken,
      compID: widget.compID,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getStatusFilter(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return '2'; // Hazır
      case 2:
        return '4'; // Tamamlandı
      default:
        return 'all'; // Tümü
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _viewModel,
      child: Scaffold(
            appBar: AppBar(
              title: const Text('Sipariş Listesi', style: TextStyle(color: Colors.white)),
              backgroundColor: Color(AppConstants.primaryColorValue),
              bottom: TabBar(
                controller: _tabController,
                tabs: _tabs,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                
                onTap: (index) {
                  setState(() {});
                  _loadData(); // Sekme değiştiğinde sipariş listesini yenile
                },
              ),
            ),
            drawer: const AppDrawer(),
        body: Consumer<OrderListViewModel>(
          builder: (context, viewModel, _) {
            return _buildBody(viewModel);
        },
        ),
      ),
    );
  }

  Widget _buildBody(OrderListViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.errorMessage != null) {
      String errorMessage = viewModel.errorMessage!;
      
      if (errorMessage.contains('401')) {
        errorMessage = 'Oturum süreniz dolmuş olabilir. Lütfen tekrar giriş yapın.';
      } else if (errorMessage.contains('timeout') || errorMessage.contains('SocketException')) {
        errorMessage = 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Hata: $errorMessage',
                style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConstants.primaryColorValue),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
                elevation: 3,
              ),
              child: const Text('Yeniden Dene', 
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredOrders = viewModel.getFilteredOrders(
      _getStatusFilter(_tabController.index),
    );

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sipariş bulunamadı',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _tabController.index == 0
                  ? 'Henüz aktif sipariş bulunmuyor.'
                  : _tabController.index == 1
                      ? 'Hazır durumda sipariş bulunmuyor.'
                      : 'Tamamlanmış sipariş bulunmuyor.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConstants.primaryColorValue),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [0, 1, 2].map((tabIndex) {
        final tabOrders = viewModel.getFilteredOrders(
          _getStatusFilter(tabIndex),
        );
        
        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            itemCount: tabOrders.length,
            itemBuilder: (context, index) {
              final order = tabOrders[index];
              return _buildOrderCard(order);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderCard(Order order) {
    Color statusColor;
    
    switch (order.orderStatusID) {
      case '2':
        statusColor = Colors.green;
        break;
      case '4':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    // Sipariş tipini kontrol et
    final bool canCancel = order.orderStatusID != '4'; // İptal edilebilir durumlar
    final bool canPay = order.orderStatusID != '4'; // Ödeme alınabilir durumlar
    
    // Gel-Al siparişlerini kontrol et - Sipariş adına göre
    final bool isGelAl = order.orderName.contains('Gel-Al');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              color: statusColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              order.orderName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        _buildStatusBadge(order.orderStatus, statusColor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDetailRow(Icons.receipt_outlined, 'Sipariş Kodu: ${order.orderCode}'),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.person_outline, 'Garson: ${order.orderUserName}'),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.access_time, 'Tarih: ${order.orderDate}'),
                    const SizedBox(height: 8),
                    _buildOrderDescRow(order),
                    
                    if (order.orderCustName.isNotEmpty || order.orderCustAdr.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildCustomerCard(order),
                    ],
                    
                    if (canPay || canCancel) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (canPay) ...[
                            _buildPaymentButton(order, isQuickPay: true),
                            _buildPaymentButton(order, isQuickPay: false),
                          ],
                          if (canCancel) _buildCancelOrderButton(order),
                        ],
                      ),
                    ],
                    
                    const Divider(height: 24, thickness: 0.5, color: Colors.black12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          order.orderAmount,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(AppConstants.primaryColorValue).withOpacity(0.9),
                          ),
                        ),
                        if (order.orderPayment.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.orderPayment,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    if (order.payments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Ödemeler:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ...order.payments.map((payment) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${payment.payType}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ödeme butonu
  Widget _buildPaymentButton(Order order, {required bool isQuickPay}) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () => _showPaymentView(order, isQuickPay),
        icon: Icon(isQuickPay ? Icons.flash_on : Icons.payment, size: 16),
        label: Text(isQuickPay ? 'Hızlı Öde' : 'Parçalı Öde', style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isQuickPay ? Colors.green.shade600 : const Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // Ödeme sayfasını aç
  void _showPaymentView(Order order, bool isQuickPay) async {
    // Sipariş detayını al
    final orderViewModel = OrderViewModel();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş detayları alınıyor...'),
          duration: Duration(seconds: 1),
        ),
      );

      final success = await orderViewModel.getSiparisDetayi(
        userToken: widget.userToken,
        compID: widget.compID,
        orderID: order.orderID,
      );

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderViewModel.errorMessage ?? 'Sipariş detayları alınamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Ödenecek sepet öğelerini oluştur
      final basketItems = orderViewModel.siparisUrunleriniSepeteAktar();
      
      if (basketItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödenecek ürün bulunamadı. Sipariş zaten tamamlanmış olabilir.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Toplam tutarı hesapla
      double totalAmount = 0;
      for (var item in basketItems) {
        totalAmount += item.birimFiyat * item.proQty;
      }

      // Ödeme sayfasını aç
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentView(
            userToken: widget.userToken,
            compID: widget.compID,
            orderID: order.orderID,
            totalAmount: totalAmount,
            basketItems: basketItems,
            onPaymentSuccess: () {
              _loadData(); // Ödeme başarılı olduğunda listeyi yenile
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusBadge(String status, Color color) {
    IconData iconData;
    switch (status.toLowerCase()) {
      case 'hazır':
        iconData = Icons.check_circle_outline;
        break;
      case 'tamamlandı':
        iconData = Icons.task_alt;
        break;
      default:
        iconData = Icons.hourglass_empty;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2), width: 1)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDescRow(Order order) {
    const int maxDescLength = 30;
    final String desc = order.orderDesc;
    final bool isLong = desc.length > maxDescLength;
    final String shortDesc = isLong ? desc.substring(0, maxDescLength) + '...' : desc;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.description, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Sipariş Açıklaması: $shortDesc',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLong)
                TextButton(
                  onPressed: () => _showOrderDescDialog(desc),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Tümünü Gör',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Açıklama detay dialogu
  Future<void> _showOrderDescDialog(String desc) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: const [
              Icon(Icons.description, color: Colors.blue),
              SizedBox(width: 8),
              Text('Sipariş Açıklaması'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerCard(Order order) {
    final bool hasCustomerName = order.orderCustName.isNotEmpty;
    final bool hasCustomerAddress = order.orderCustAdr.isNotEmpty;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin, size: 18, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Müşteri Bilgileri',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 28,
                child: TextButton.icon(
                  onPressed: () => _showCustomerDetailDialog(order),
                  icon: Icon(Icons.visibility, size: 14, color: Colors.blue.shade600),
                  label: Text(
                    'Detay',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasCustomerName) ...[
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.blue.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.orderCustName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (hasCustomerAddress) ...[
            if (hasCustomerName) const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.blue.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.orderCustAdr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Sipariş iptal butonu
  Widget _buildCancelOrderButton(Order order) {
    return SizedBox(
      height: 36,
      child: Consumer<OrderListViewModel>(
        builder: (context, viewModel, _) {
          return ElevatedButton.icon(
            onPressed: viewModel.isLoading 
                ? null 
                : () => _showCancelOrderDialog(order.orderID),
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('İptal', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }

  // Sipariş iptal diyaloğu
  Future<void> _showCancelOrderDialog(int orderID) async {
    final TextEditingController _cancelReasonController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sipariş İptali'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Siparişi iptal etmek istediğinize emin misiniz?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('İptal Gerekçesi (İsteğe Bağlı):'),
                const SizedBox(height: 8),
                TextField(
                  controller: _cancelReasonController,
                  decoration: const InputDecoration(
                    hintText: 'İptal nedeni girin',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Vazgeç'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Consumer<OrderListViewModel>(
              builder: (context, viewModel, _) {
                return TextButton(
                  child: viewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('İptal Et'),
                  onPressed: viewModel.isLoading
                      ? null
                      : () {
                          _cancelOrder(
                            orderID, 
                            _cancelReasonController.text
                          );
                          Navigator.of(context).pop();
                        },
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Sipariş iptal işlevi
  Future<void> _cancelOrder(int orderID, String? cancelReason) async {
    final viewModel = Provider.of<OrderListViewModel>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final result = await viewModel.cancelOrder(
      userToken: widget.userToken,
      compID: widget.compID,
      orderID: orderID,
      cancelDesc: cancelReason,
    );
    
    if (result) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(viewModel.successMessage ?? 'Sipariş başarıyla iptal edildi'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData(); // Sipariş listesini yenile
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'İşlem sırasında bir hata oluştu'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Müşteri detay diyaloğu
  Future<void> _showCustomerDetailDialog(Order order) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.person_pin, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Müşteri Detayları'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sipariş Kodu
                _buildDialogDetailRow(
                  icon: Icons.receipt_outlined,
                  title: 'Sipariş Kodu',
                  value: order.orderCode,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(height: 12),
                
                // Müşteri Adı
                if (order.orderCustName.isNotEmpty) ...[
                  _buildDialogDetailRow(
                    icon: Icons.person,
                    title: 'Müşteri Adı',
                    value: order.orderCustName,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Müşteri Adresi
                if (order.orderCustAdr.isNotEmpty) ...[
                  _buildDialogDetailRow(
                    icon: Icons.location_on,
                    title: 'Teslimat Adresi',
                    value: order.orderCustAdr,
                    color: Colors.green.shade600,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Sipariş Tutarı
                _buildDialogDetailRow(
                  icon: Icons.attach_money,
                  title: 'Sipariş Tutarı',
                  value: order.orderAmount,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(height: 12),
                
                // Sipariş Tarihi
                _buildDialogDetailRow(
                  icon: Icons.access_time,
                  title: 'Sipariş Tarihi',
                  value: order.orderDate,
                  color: Colors.purple.shade600,
                ),
                const SizedBox(height: 12),
                
                // Garson
                _buildDialogDetailRow(
                  icon: Icons.person_outline,
                  title: 'Garson',
                  value: order.orderUserName,
                  color: Colors.indigo.shade600,
                ),
                
                // Ödeme Bilgileri
                if (order.payments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.payment, size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Ödeme Bilgileri',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...order.payments.map((payment) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.green.shade500),
                        const SizedBox(width: 8),
                        Text(
                          payment.payType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 