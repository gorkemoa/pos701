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
      final int compID = userViewModel.userInfo?.compID ?? 0;
      statisticsViewModel.loadStatistics(compID);
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
              final int compID = userViewModel.userInfo?.compID ?? 0;
              statisticsViewModel.refreshStatistics(compID);
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
                          value: statisticsViewModel.statistics?.totalAmount ?? '',
                          title: statisticsViewModel.statistics?.totalAmountText ?? '',
                        ),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.expenseCardColor),
                          icon: Icons.currency_exchange,
                          value: statisticsViewModel.statistics?.totalExpenseAmount ?? '',
                          title: statisticsViewModel.statistics?.totalExpenseAmountText ?? '',
                        ),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.orderCardColor),
                          icon: Icons.coffee,
                          value: statisticsViewModel.statistics?.totalOpenAmount ?? '',
                          title: statisticsViewModel.statistics?.totalOpenAmountText ?? '',
                        ),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.customerCardColor),
                          icon: Icons.people,
                          value: '${statisticsViewModel.statistics?.totalGuest}',
                          title: statisticsViewModel.statistics?.totalGuestText ?? '',
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
                              Expanded(
                                child: _buildPaymentTypesChart(statisticsViewModel),
                              ),
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
    final List<SalesData> sales = viewModel.statistics?.nowDaySales ?? [];
    
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
    
    // Mevcut verileri debug amaçlı yazdır
    debugPrint('Satış verileri: ${sales.length} adet');
    for (var sale in sales) {
      debugPrint('Saat: ${sale.hour}, Miktar: ${sale.amount}');
    }
    
    // Veri noktaları oluştur
    final spots = List.generate(25, (index) {
      // Saat formatını 'index:00' olarak standardize et
      String hourKey = '$index:00';
      
      // Saat bazında veriyi bul
      final hourData = sales.firstWhere(
        (s) => s.hour == hourKey,
        orElse: () => SalesData(hour: hourKey, amount: 0.0),
      );
      
      return FlSpot(index.toDouble(), hourData.amount ?? 0.0);
    });
    
    // Min ve max değerleri hesapla
    double minY = 0.0;
    double maxY = 0.0;
    
    if (spots.isNotEmpty) {
      minY = spots.map((spot) => spot.y).reduce((min, y) => y < min ? y : min);
      maxY = spots.map((spot) => spot.y).reduce((max, y) => y > max ? y : max);
      
      // Grafik daha iyi görünsün diye biraz boşluk ekle
      minY = minY > 0 ? 0 : minY * 1.1;
      maxY = maxY * 1.1;
      
      // Eğer min ve max eşitse, görsel aralık oluştur
      if (minY == maxY) {
        minY = minY > 0 ? 0 : minY - 1;
        maxY = maxY + 1;
      }
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY > 5 ? maxY / 5 : 1,
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
              interval: maxY > 5 ? maxY / 5 : 1,
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
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Color(AppConstants.chartLineColor),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Color(AppConstants.chartLineColor).withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentTypesChart(StatisticsViewModel viewModel) {
    final List<PaymentData> payments = viewModel.statistics?.nowDayPayments ?? [];
    
    if (payments.isEmpty) {
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
    
    // Toplam tutar hesapla
    final double totalAmount = payments.fold(0.0, (sum, payment) => sum + (payment.amount ?? 0.0));
    
    return Row(
      children: [
        // Pasta grafiği
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: payments.map((payment) {
                final double percentage = totalAmount > 0 
                  ? ((payment.amount ?? 0.0) / totalAmount) * 100 
                  : 0.0;
                
                // API'den gelen renk kodunu kullan veya varsayılan renkler listesinden seç
                final Color color = payment.color != null && payment.color!.startsWith('#')
                    ? _hexToColor(payment.color!)
                    : Colors.blue;
                
                return PieChartSectionData(
                  color: color,
                  value: payment.amount ?? 0.0,
                  title: '${percentage.toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Ödeme tipleri listesi ve açıklamalar
        Expanded(
          child: ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              
              // API'den gelen renk kodunu kullan veya varsayılan renkler listesinden seç
              final Color color = payment.color != null && payment.color!.startsWith('#')
                  ? _hexToColor(payment.color!)
                  : Colors.blue;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payment.type ?? 'Bilinmeyen',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${payment.amount?.toStringAsFixed(2)} TL',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // HexColor'ı Flutter Color'a dönüştürme
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // Alfa kanalını ekle
    }
    return Color(int.parse('0x$hexColor'));
  }
} 