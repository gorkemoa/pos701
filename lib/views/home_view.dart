import 'package:flutter/material.dart';
import 'package:pos701/models/statistics_model.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/viewmodels/statistics_viewmodel.dart';
import 'package:pos701/widgets/app_drawer.dart';
import 'package:pos701/widgets/dashboard_card.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Kullanıcı bilgilerini yükle
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      if (userViewModel.userInfo == null) {
        userViewModel.loadUserInfo();
      }
      
      // İstatistik verilerini yükle
      final statisticsViewModel = Provider.of<StatisticsViewModel>(context, listen: false);
      statisticsViewModel.loadStatistics(1); // Burada compID'yi 1 olarak sabit verdim, gerçek uygulamada dinamik olmalı
    });
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final statisticsViewModel = Provider.of<StatisticsViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Anasayfa / ${userViewModel.userInfo?.userFirstname ?? ''}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(AppConstants.primaryColorValue),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              userViewModel.loadUserInfo();
              statisticsViewModel.refreshStatistics(1); // compID'yi 1 olarak sabit verdim
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: statisticsViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : statisticsViewModel.errorMessage != null
              ? Center(child: Text('Hata: ${statisticsViewModel.errorMessage}'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DashboardCard(
                          backgroundColor: Color(AppConstants.incomeCardColor),
                          icon: Icons.payments,
                          value: statisticsViewModel.statistics?.totalAmount ?? '₺0.00',
                          title: statisticsViewModel.statistics?.totalAmountText ?? 'Bugün alınan ödemeler',
                        ),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.expenseCardColor),
                          icon: Icons.currency_exchange,
                          value: statisticsViewModel.statistics?.totalExpenseAmount ?? '₺0.00',
                          title: statisticsViewModel.statistics?.totalExpenseAmountText ?? 'Bugünkü toplam gider tutarı',
                        ),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.orderCardColor),
                          icon: Icons.coffee,
                          value: statisticsViewModel.statistics?.totalOpenAmount ?? '₺0.00',
                          title: statisticsViewModel.statistics?.totalOpenAmountText ?? 'Açık sipariş toplamı',
                        ),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.customerCardColor),
                          icon: Icons.people,
                          value: '${statisticsViewModel.statistics?.totalGuest ?? 0}',
                          title: statisticsViewModel.statistics?.totalGuestText ?? 'Bugün ağırlanan misafir sayısı',
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 300,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: Color(AppConstants.chartLineColor),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Bugün'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: _buildSalesChart(statisticsViewModel),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 300,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: Colors.pink,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Ödeme Tipleri'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildPaymentTypesChart(statisticsViewModel),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildSalesChart(StatisticsViewModel viewModel) {
    final sales = viewModel.statistics?.nowDaySales ?? [];
    
    if (sales.isEmpty) {
      return const Center(
        child: Text(
          'Veri yok',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }
    
    // Örnek veri noktaları oluştur
    final spots = List.generate(25, (index) {
      // Saat bazında veriyi bul
      final hourData = sales.firstWhere(
        (s) => s.hour == '$index:00',
        orElse: () => SalesData(hour: '$index:00', amount: 0.0),
      );
      
      return FlSpot(index.toDouble(), hourData.amount ?? 0.0);
    });
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.2,
          verticalInterval: 2,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Color(0xff72719b),
                  fontWeight: FontWeight.normal,
                  fontSize: 10,
                );
                String text;
                if (value % 2 == 0) {
                  text = '${value.toInt().toString()}:00';
                } else {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.2,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Color(0xff72719b),
                  fontWeight: FontWeight.normal,
                  fontSize: 10,
                );
                return Text('${value.toStringAsFixed(1)}', style: style);
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xffeceff1)),
        ),
        minX: 0,
        maxX: 24,
        minY: -1.0,
        maxY: 1.0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Color(AppConstants.chartLineColor),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentTypesChart(StatisticsViewModel viewModel) {
    final payments = viewModel.statistics?.nowDayPayments ?? [];
    
    if (payments.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Veri yok',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    // Burada ödeme tiplerini gösteren chart widget'ı eklenebilir
    // Şimdilik basit bir liste gösterimi yapalım
    return Expanded(
      child: ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return ListTile(
            title: Text(payment.type ?? 'Bilinmeyen'),
            trailing: Text('${payment.amount?.toStringAsFixed(2)} TL'),
          );
        },
      ),
    );
  }
} 