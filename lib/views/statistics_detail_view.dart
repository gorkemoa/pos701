import 'package:flutter/material.dart';
import 'package:pos701/services/auth_service.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/boss_statistics_viewmodel.dart';
import 'package:pos701/models/boss_statistics_model.dart';
import 'package:pos701/utils/app_logger.dart';

class StatisticsDetailView extends StatefulWidget {
  final String userToken;
  final int compID;
  final BossStatisticsModel statistic;
  final String startDate;
  final String endDate;
  final String order;

  const StatisticsDetailView({
    Key? key,
    required this.userToken,
    required this.compID,
    required this.statistic,
    required this.startDate,
    required this.endDate,
    required this.order,
  }) : super(key: key);

  @override
  State<StatisticsDetailView> createState() => _StatisticsDetailViewState();
}

class _StatisticsDetailViewState extends State<StatisticsDetailView> {
  final _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _logger.i('🚀 Statistics Detail View: initState çağrıldı');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.d('📱 Statistics Detail View: Post frame callback çalıştırılıyor');
      _loadDetailStatistics();
    });
  }

  void _loadDetailStatistics() {
    _logger.i('🔄 Statistics Detail View: Detay veri yükleme başlatılıyor...');
    
    final viewModel = Provider.of<BossStatisticsViewModel>(context, listen: false);
    
    // Filter key mapping'i
    final Map<String, String> filterKeyMapping = {
      'Kapatılan Siparişler': 'closedOrdersAmount',
      'Nakit Ödemeler': 'cashAmount',
      'Açık Masalar': 'openTablesAmount',
      'Açık Paketler': 'openPackagesAmount',
      'Ürün Satışları': 'productAmount',
      'Hediye Ürünler': 'groupAmount',
      'Giderler': 'expenseAmount',
      'Gelirler': 'incomeAmount',
      'Zayiatlar': 'wasteAmount',
      'Kasa Tahsilatı': 'cashierAmount',
      'Kapalı Siparişler': 'closedAmount',
      'Garson Performansı': 'waiterPerformance',
      'Departman Satışları': 'departmentAmount',
      'İptaller': 'deletedAmount',
      'İkram İndirimleri': 'complimentAmount',
      'İade Edilenler': 'refundAmount',
    };

    final filterKey = filterKeyMapping[widget.statistic.statisticsTitle] ?? 'summaryAmount';

    viewModel.fetchBossStatisticsDetail(
      userToken: widget.userToken,
      compID: widget.compID,
      startDate: widget.startDate,
      endDate: widget.endDate,
      order: widget.order,
      filterKey: filterKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.statistic.statisticsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 0,
        toolbarHeight: 48,
      ),
      body: Column(
        children: [
          // Tarih bilgisi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: primaryColor.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.startDate} - ${widget.endDate}',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Ana içerik
          Expanded(
            child: Consumer<BossStatisticsViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isDetailLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          'Detaylar yükleniyor...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.detailErrorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hata',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            viewModel.detailErrorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            viewModel.clearDetailError();
                            _loadDetailStatistics();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            'Tekrar Dene',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (viewModel.detailStatistics.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Detay Veri Bulunamadı',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Toplam bilgileri kartı
                    if (viewModel.detailData != null)
                      Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.summarize,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Özet Bilgiler',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Toplam Adet',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${viewModel.detailData!.totalCount}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Toplam Tutar',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        viewModel.detailData!.totalAmount,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    // Detay listesi
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: viewModel.detailStatistics.length,
                        itemBuilder: (context, index) {
                          final detail = viewModel.detailStatistics[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.analytics,
                                    color: primaryColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detail.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${detail.count} adet',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  detail.amount,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 