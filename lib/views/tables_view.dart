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
    // Responsive tasarım için ekran boyutlarını al
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final bool isLargeTablet = screenSize.width > 900;
    
    // Responsive boyutlar
    final double titleFontSize = isLargeTablet ? 22 : isTablet ? 20 : 16;
    final double iconSize = isLargeTablet ? 32 : isTablet ? 30 : 24;
    final double buttonFontSize = isLargeTablet ? 10 : isTablet ? 9 : 8;
    final double tabFontSize = isLargeTablet ? 16 : isTablet ? 14 : 12;
    
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
               title: Text(
                 widget.title, 
                 style: TextStyle(
                   color: Colors.white,
                   fontSize: titleFontSize,
                 ),
               ),
                backgroundColor: Color(AppConstants.primaryColorValue),
                leading: IconButton(
                  icon: Icon(Icons.chevron_left, size: iconSize),
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
                      size: isTablet ? 64 : 48,
                      color: Colors.red.shade300,
                    ),
                    SizedBox(height: isTablet ? 24 : 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isTablet ? 48.0 : 32.0),
                      child: Text(
                        'Hata: ${viewModel.errorMessage}',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isTablet ? 32 : 24),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppConstants.primaryColorValue),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 40 : 32, 
                          vertical: isTablet ? 16 : 12
                        ),
                      ),
                      child: Text(
                        'Yeniden Dene', 
                        style: TextStyle(fontSize: isTablet ? 18 : 16)
                      ),
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
                title: Text(
                  widget.title, 
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                  ),
                ),
                backgroundColor: Color(AppConstants.primaryColorValue),
                leading: IconButton(
                  icon: Icon(Icons.chevron_left, size: iconSize),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      size: isTablet ? 28 : 24,
                    ),
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
                      size: isTablet ? 96 : 72,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: isTablet ? 24 : 16),
                    Text(
                      'Bölge bulunamadı',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 18, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Text(
                      'Henüz bölge eklenmemiş veya görüntüleme izniniz bulunmuyor.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: isTablet ? 32 : 24),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: Icon(
                        Icons.refresh,
                        size: isTablet ? 24 : 20,
                      ),
                      label: Text(
                        'Yeniden Dene',
                        style: TextStyle(fontSize: isTablet ? 16 : 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppConstants.primaryColorValue),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 32 : 24,
                          vertical: isTablet ? 16 : 12,
                        ),
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
              title: Text(
                widget.title, 
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleFontSize,
                ),
              ),
              backgroundColor: Color(AppConstants.primaryColorValue),
              actions: [
                // Destek İste butonu - ekran görüntüsündeki gibi
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12.0 : 8.0, 
                    vertical: isTablet ? 12.0 : 8.0
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Destek işlevi
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Destek İletişim',
                            style: TextStyle(fontSize: isTablet ? 20 : 17),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Telefon: +90 555 123 4567',
                                style: TextStyle(fontSize: isTablet ? 16 : 14),
                              ),
                              SizedBox(height: isTablet ? 12 : 8),
                              Text(
                                'E-posta: destek@pos701.com',
                                style: TextStyle(fontSize: isTablet ? 16 : 14),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Kapat',
                                style: TextStyle(fontSize: isTablet ? 16 : 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.support_agent, 
                      color: Colors.white,
                      size: isTablet ? 20 : 16,
                    ),
                    label: Text(
                      'Destek İste', 
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: buttonFontSize
                      )
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black26,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 12 : 8, 
                        vertical: isTablet ? 6 : 2
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
            
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: isTablet ? 28 : 24,
                  ),
                  onPressed: _loadData,
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: isTablet ? 28 : 24,
                  ),
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
                                margin: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.receipt_long,
                                  size: isTablet ? 24 : 20,
                                ),
                                title: Text(
                                  'Tüm Siparişler', 
                                  style: TextStyle(fontSize: isTablet ? 16 : 12)
                                ),
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
                              SizedBox(height: isTablet ? 32 : 28),
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
                labelStyle: TextStyle(fontSize: tabFontSize),
                unselectedLabelStyle: TextStyle(fontSize: tabFontSize),
                tabs: regions.map((region) => Tab(
                  text: '${region.regionName} (${region.totalOrder})',
                )).toList(),
              ),
            ),
            drawer: const AppDrawer(),
            body: TabBarView(
              controller: _tabController,
              children: regions.map((region) => _buildTablesGrid(region, isTablet)).toList(),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                _handleFloatingActionButton(context, isTablet);
              },
              backgroundColor: Color(AppConstants.primaryColorValue),
              icon: Icon(
                Icons.add, 
                color: Colors.white,
                size: isTablet ? 28 : 24,
              ),
              label: Text(
                'Yeni Sipariş', 
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTablesGrid(Region region, bool isTablet) {
    // Responsive grid ayarları
    final int crossAxisCount = isTablet ? 4 : 3;
    final double childAspectRatio = isTablet ? 1.6 : 1.4;
    final double padding = isTablet ? 16.0 : 8.0;
    
    return Padding(
      padding: EdgeInsets.all(padding),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: isTablet ? 16 : 8,
          mainAxisSpacing: isTablet ? 16 : 8,
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

  void _handleFloatingActionButton(BuildContext context, bool isTablet) {
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
                margin: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.delivery_dining, 
                  color: Colors.orange,
                  size: isTablet ? 28 : 24,
                ),
                title: Text(
                  'Paket Sipariş',
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                subtitle: Text(
                  'Müşteriye teslim edilecek paket siparişleri oluşturun',
                  style: TextStyle(fontSize: isTablet ? 14 : 12),
                ),
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
                leading: Icon(
                  Icons.takeout_dining, 
                  color: Colors.green,
                  size: isTablet ? 28 : 24,
                ),
                title: Text(
                  'Gel-Al Sipariş',
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                subtitle: Text(
                  'Müşterinin gelip alacağı siparişleri oluşturun',
                  style: TextStyle(fontSize: isTablet ? 14 : 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleGelAlOrder();
                },
              ),
              SizedBox(height: isTablet ? 32 : 28),
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