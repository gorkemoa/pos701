import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/widgets/table_card.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/views/category_view.dart';
import 'package:pos701/widgets/app_drawer.dart';
import 'dart:async'; // Timer için import ekle
import 'package:pos701/views/order_list_view.dart'; // OrderListView import'u ekle

class TablesView extends StatefulWidget {
  final String userToken;
  final int compID;
  final String title;

  const TablesView({
    Key? key,
    required this.userToken,
    required this.compID,
    required this.title,
  }) : super(key: key);

  @override
  State<TablesView> createState() => _TablesViewState();
}

class _TablesViewState extends State<TablesView> with TickerProviderStateMixin {
  TabController? _tabController;
  final TablesViewModel _viewModel = TablesViewModel();
  bool _isInitialized = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // 10 saniyede bir masa aktiflik durumlarını kontrol et
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _refreshDataSilently();
      }
    });
  }

  Future<void> _refreshDataSilently() async {
    if (!mounted) return;
    
    // Arka planda veri yenileme - gösterge olmadan
    await _viewModel.refreshTableActiveStatusOnly(
      userToken: widget.userToken,
      compID: widget.compID,
    );
    
    // TabController durumunu güncelle
    if (_viewModel.regions.isNotEmpty && mounted) {
      if (_tabController == null || _tabController!.length != _viewModel.regions.length) {
        _disposeTabController();
        setState(() {
          _tabController = TabController(
            length: _viewModel.regions.length,
            vsync: this,
          );
        });
      }
    }
  }

  Future<void> _loadData() async {
    // Eğer halen tabController varsa, önce onu dispose et
    _disposeTabController();
    
    try {
      setState(() {
        _isInitialized = false;
      });
      
      await _viewModel.getTablesData(
        userToken: widget.userToken,
        compID: widget.compID,
      );
      
      if (_viewModel.regions.isNotEmpty && mounted) {
        setState(() {
          _tabController = TabController(
            length: _viewModel.regions.length,
            vsync: this,
          );
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        // Hata durumunda kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  void _disposeTabController() {
    if (_tabController != null) {
      _tabController!.dispose();
      _tabController = null;
    }
  }

  @override
  void dispose() {
    _disposeTabController();
    // Timer'ı temizle
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<TablesViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (viewModel.errorMessage != null) {
            return Scaffold(
              appBar: AppBar(
               title: Text(widget.title , style: const TextStyle(color: Colors.white),),
                backgroundColor: Color(AppConstants.primaryColorValue),
                leading: IconButton(
                  icon: Icon(Icons.chevron_left, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              drawer: const AppDrawer(),
              body: Center(
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
                        'Hata: ${viewModel.errorMessage}',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppConstants.primaryColorValue),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Yeniden Dene', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          }

          final regions = viewModel.regions;
          
          if (regions.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.title , style: TextStyle(color: Colors.white),),
                backgroundColor: Color(AppConstants.primaryColorValue),
                leading: IconButton(
                  icon: Icon(Icons.chevron_left, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                  ),
                ],
              ),
              drawer: const AppDrawer(),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_bar,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bölge bulunamadı',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Henüz bölge eklenmemiş veya görüntüleme izniniz bulunmuyor.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Yeniden Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppConstants.primaryColorValue),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // TabController yoksa veya region sayısı değiştiyse yeni tabController oluştur
          if (_tabController == null || _tabController!.length != regions.length) {
            _disposeTabController();
            _tabController = TabController(
              length: regions.length,
              vsync: this,
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title , style: const TextStyle(color: Colors.white),),
              backgroundColor: Color(AppConstants.primaryColorValue),
              actions: [
                // Destek İste butonu - ekran görüntüsündeki gibi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Destek işlevi
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Destek İletişim'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Telefon: +90 555 123 4567'),
                              SizedBox(height: 8),
                              Text('E-posta: destek@pos701.com'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Kapat'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.support_agent, color: Colors.white),
                    label: const Text('Destek İste', style: TextStyle(color: Colors.white, fontSize: 8)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black26,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
            
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // iOS tarzında BottomSheet göster
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext context) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              topRight: Radius.circular(20.0),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(Icons.receipt_long),
                                title: const Text('Tüm Siparişler' , style: TextStyle(fontSize: 12),),
                                onTap: () {
                                  Navigator.pop(context);
                                  // Sipariş Listesi sayfasına yönlendir
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderListView(
                                        userToken: widget.userToken,
                                        compID: widget.compID,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 28),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: regions.map((region) => Tab(
                  text: '${region.regionName} (${region.totalOrder})',
                )).toList(),
              ),
            ),
            drawer: const AppDrawer(),
            body: TabBarView(
              controller: _tabController,
              children: regions.map((region) => _buildTablesGrid(region)).toList(),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                _handleFloatingActionButton(context);
              },
              backgroundColor: Color(AppConstants.primaryColorValue),
              icon: const Icon(Icons.add , color: Colors.white,),
              label: const Text('Yeni Sipariş', style: TextStyle(color: Colors.white),),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTablesGrid(Region region) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.4,
        ),
        itemCount: region.tables.length,
        itemBuilder: (context, index) {
          final table = region.tables[index];
          return TableCard(
            table: table,
            userToken: widget.userToken,
            compID: widget.compID,
            onTap: () {
              // Masa seçildiğinde
              debugPrint('${table.tableName} seçildi');
              _handleTableTap(table);
            },
          );
        },
      ),
    );
  }

  void _handleTableTap(TableItem table) {
    // Masa aktif olsa da olmasa da kategorileri ve ürünleri göster
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryView(
          compID: widget.compID,
          userToken: widget.userToken,
          tableID: table.tableID,
          orderID: table.isActive ? table.orderID : null,
          tableName: table.tableName,
          
        ),
      ),
    );
  }

  void _handleFloatingActionButton(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delivery_dining, color: Colors.orange),
                title: const Text('Paket Sipariş'),
                subtitle: const Text('Müşteriye teslim edilecek paket siparişleri oluşturun'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryView(
                        compID: widget.compID,
                        userToken: widget.userToken,
                        tableID: 0, // Masa ID'si 0 olmalı
                        orderID: null,
                        tableName: "Paket Sipariş", // Sipariş türü adı
                        orderType: 2, // 2: Paket Sipariş
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.takeout_dining, color: Colors.green),
                title: const Text('Gel-Al Sipariş'),
                subtitle: const Text('Müşterinin gelip alacağı siparişleri oluşturun'),
                onTap: () {
                  Navigator.pop(context);
                  _handleGelAlOrder();
                },
              ),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }

  void _handleGelAlOrder() {
    // Gel-Al siparişler için kategori sayfasını aç
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryView(
          compID: widget.compID,
          userToken: widget.userToken,
          tableID: 0, // Masa ID'si 0 olmalı
          orderID: null,
          tableName: "Gel-Al Sipariş", // Sipariş türü adı
          orderType: 3, // 3: Gel-Al Sipariş
        ),
      ),
    );
  }
} 