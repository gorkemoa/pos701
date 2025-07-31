import 'package:flutter/material.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/boss_statistics_viewmodel.dart';
import 'package:pos701/models/boss_statistics_model.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:intl/intl.dart';

class PatronStatisticsView extends StatefulWidget {
  final String userToken;
  final int compID;
  final String title;


  const PatronStatisticsView({
    Key? key,
    required this.userToken,
    required this.compID,
    required this.title,
  }) : super(key: key);

  @override
  State<PatronStatisticsView> createState() => _PatronStatisticsViewState();

    
}

class _PatronStatisticsViewState extends State<PatronStatisticsView> {
  int _selectedTabIndex = 0;
  int _selectedPeriodIndex = 0;
  final _logger = AppLogger();

  final List<String> _tabs = ['Raporlar', 'Grafik'];
  final List<String> _periods = ['Bugün', 'Dün', 'Bu Hafta', 'Bu Ay', 'Bu Yıl'];

  // İkon mapping'i
  final Map<String, IconData> _iconMapping = {
    'Kapatılan Siparişler': Icons.check_circle,
    'Nakit Ödemeler': Icons.money,
    'Açık Masalar': Icons.table_restaurant,
    'Açık Paketler': Icons.shopping_cart,
    'Ürün Satışları': Icons.restaurant,
    'Hediye Ürünler': Icons.card_giftcard,
    'Giderler': Icons.trending_down,
    'Gelirler': Icons.trending_up,
    'Zayiatlar': Icons.delete_outline,
    'Kasa Tahsilatı': Icons.account_balance_wallet,
    'Kapalı Siparişler': Icons.check_circle_outline,
    'Garson Performansı': Icons.people,
    'Departman Satışları': Icons.business,
    'İptaller': Icons.cancel,
    'İkram İndirimleri': Icons.local_offer,
    'İade Edilenler': Icons.undo,
  };

  @override
  void initState() {

    super.initState();
    _logger.i('🚀 Patron Statistics View: initState çağrıldı');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.d('📱 Patron Statistics View: Post frame callback çalıştırılıyor');
      _loadStatistics();
    });
  }

  void _loadStatistics() {
    _logger.i('🔄 Patron Statistics View: Veri yükleme başlatılıyor...');
    _logger.d('📋 Seçili periyot: ${_periods[_selectedPeriodIndex]} (index: $_selectedPeriodIndex)');
    
    final viewModel = Provider.of<BossStatisticsViewModel>(context, listen: false);
    final dateRange = _getDateRangeForPeriod(_selectedPeriodIndex);
    
    _logger.d('📅 Tarih aralığı: ${dateRange['startDate']} - ${dateRange['endDate']}');
    
    viewModel.fetchBossStatistics(
      userToken: widget.userToken,
      compID: widget.compID,
      startDate: dateRange['startDate']!,
      endDate: dateRange['endDate']!,
    );
  }

  Map<String, String> _getDateRangeForPeriod(int periodIndex) {
    final now = DateTime.now();
    final formatter = DateFormat('dd.MM.yyyy');
    
    switch (periodIndex) {
      case 0: // Bugün
        return {
          'startDate': formatter.format(now),
          'endDate': formatter.format(now),
        };
      case 1: // Dün
        final yesterday = now.subtract(const Duration(days: 1));
        return {
          'startDate': formatter.format(yesterday),
          'endDate': formatter.format(yesterday),
        };
      case 2: // Bu Hafta
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return {
          'startDate': formatter.format(startOfWeek),
          'endDate': formatter.format(endOfWeek),
        };
      case 3: // Bu Ay
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return {
          'startDate': formatter.format(startOfMonth),
          'endDate': formatter.format(endOfMonth),
        };
      case 4: // Bu Yıl
        final startOfYear = DateTime(now.year, 1, 1);
        final endOfYear = DateTime(now.year, 12, 31);
        return {
          'startDate': formatter.format(startOfYear),
          'endDate': formatter.format(endOfYear),
        };
      default:
        return {
          'startDate': formatter.format(now),
          'endDate': formatter.format(now),
        };
    }
  }

  @override
  Widget build(BuildContext context) {

    final userViewModel = Provider.of<UserViewModel>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Section
          Container(
            color: primaryColor,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Title Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Consumer<BossStatisticsViewModel>(
                            builder: (context, viewModel, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userViewModel.userInfo?.company?.compName ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                
                                ],
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list, color: Colors.white),
                          onPressed: () {},
                        ),
                      
                      ],
                    ),
                  ),
                  // Navigation Tabs
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _tabs.asMap().entries.map((entry) {
                        int index = entry.key;
                        String tab = entry.value;
                        bool isSelected = index == _selectedTabIndex;
                        
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: isSelected ? Colors.orange : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                tab,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Period Selection Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: _periods.asMap().entries.map((entry) {
                int index = entry.key;
                String period = entry.value;
                bool isSelected = index == _selectedPeriodIndex;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriodIndex = index;
                      });
                      _loadStatistics();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        period,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Main Content - Statistics Cards
          Expanded(
            child: Consumer<BossStatisticsViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (viewModel.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hata',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          viewModel.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            viewModel.clearError();
                            _loadStatistics();
                          },
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.statistics.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Veri Bulunamadı',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: viewModel.statistics.length,
                    itemBuilder: (context, index) {
                      final statistic = viewModel.statistics[index];
                      return _buildStatisticsCard(statistic);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(BossStatisticsModel statistic) {
    final iconData = _iconMapping[statistic.title] ?? Icons.help_outline;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 28,
              color: Colors.orange,
            ),
            const SizedBox(height: 4),
            Text(
              statistic.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              statistic.amount,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 