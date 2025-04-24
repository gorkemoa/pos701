import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/viewmodels/order_list_viewmodel.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/models/order_model.dart';
import 'package:pos701/widgets/app_drawer.dart';

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
  final OrderListViewModel _viewModel = OrderListViewModel();
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
    _loadData();
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
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<OrderListViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Sipariş Listesi'),
              backgroundColor: Color(AppConstants.primaryColorValue),
              bottom: TabBar(
                controller: _tabController,
                tabs: _tabs,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                onTap: (index) {
                  setState(() {});
                },
              ),
            ),
            drawer: const AppDrawer(),
            body: _buildBody(viewModel),
          );
        },
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
                style: const TextStyle(fontSize: 16),
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
                  fontSize: 16,
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.orderStatus,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.receipt, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Sipariş Kodu: ${order.orderCode}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Garson: ${order.orderUserName}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Tarih: ${order.orderDate}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderAmount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (order.orderPayment.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.orderPayment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
            if (order.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Ödemeler:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              ...order.payments.map((payment) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• ${payment.payType}'),
              )),
            ],
          ],
        ),
      ),
    );
  }
} 