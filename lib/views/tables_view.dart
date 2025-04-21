import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/widgets/table_card.dart';
import 'package:pos701/constants/app_constants.dart';

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

class _TablesViewState extends State<TablesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TablesViewModel _viewModel = TablesViewModel();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _viewModel.getTablesData(
      userToken: widget.userToken,
      compID: widget.compID,
    );
    
    if (_viewModel.regions.isNotEmpty) {
      _tabController = TabController(
        length: _viewModel.regions.length,
        vsync: this,
      );
    }
  }

  @override
  void dispose() {
    if (_viewModel.regions.isNotEmpty) {
      _tabController.dispose();
    }
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
              appBar: AppBar(title: Text(widget.title)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${AppStrings.errorTitle}: ${viewModel.errorMessage}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: Text(AppStrings.retryButtonText),
                    ),
                  ],
                ),
              ),
            );
          }

          final regions = viewModel.regions;
          
          if (regions.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.title)),
              body: Center(child: Text(AppStrings.noRegionsFound)),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              backgroundColor: Color(AppConstants.primaryColorValue),
              actions: [
                // Destek İste butonu - ekran görüntüsündeki gibi
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Destek işlevi
                    },
                    icon: const Icon(Icons.support_agent, color: Colors.white),
                    label: const Text('Destek İste', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.receipt_long),
                  onPressed: () {
                    // Fiş işlevi
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // Daha fazla işlevi
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
            body: TabBarView(
              controller: _tabController,
              children: regions.map((region) => _buildTablesGrid(region)).toList(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // Yeni masa veya sipariş ekle
              },
              backgroundColor: Color(AppConstants.primaryColorValue),
              child: const Icon(Icons.add),
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
          childAspectRatio: 1.2,
        ),
        itemCount: region.tables.length,
        itemBuilder: (context, index) {
          final table = region.tables[index];
          return TableCard(
            table: table,
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
    // Masa seçildiğinde yapılacak işlemler
    if (table.isActive) {
      // Aktif masa - sipariş detayına git
    } else {
      // Pasif masa - yeni sipariş başlat
    }
  }
} 