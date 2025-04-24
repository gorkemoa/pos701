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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Kullanıcı bilgilerini yükle
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      if (userViewModel.userInfo == null) {
        // Kullanıcı bilgilerinin yüklenmesini bekle
        await userViewModel.loadUserInfo();
      }
      
      // Kullanıcı bilgileri yüklendikten sonra istatistik verilerini yükle
      if (mounted) {
        final statisticsViewModel = Provider.of<StatisticsViewModel>(context, listen: false);
        final int compID = userViewModel.userInfo?.compID ?? 0;
        statisticsViewModel.loadStatistics(compID);
      }
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
            onPressed: () async {
              // Önce kullanıcı bilgilerini güncelle
              await userViewModel.loadUserInfo();
              
              // Sonra güncel compID ile istatistikleri yenile
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
                          child: _buildPaymentTypesChart(statisticsViewModel),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 350,
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
                          child: _buildOccupancyChart(statisticsViewModel),
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

    // En yüksek tutarı bul (grafik ölçeği için)
    double maxY = 0;
    for (var payment in payments) {
      if ((payment.amount ?? 0) > maxY) {
        maxY = payment.amount ?? 0;
      }
    }
    
    // Yuvarlama işlemi yap ve ekstra boşluk ekle
    maxY = (maxY * 1.2).ceilToDouble(); 
    
    // Toplam tutarı hesapla (yüzdeler için)
    final double totalAmount = payments.fold(0.0, (sum, payment) => sum + (payment.amount ?? 0.0));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ödeme Tipleri',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
        ),
        const SizedBox(height: 16),
        
        // Grafik
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.shade800,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final payment = payments[groupIndex];
                    final percentage = totalAmount > 0 
                      ? ((payment.amount ?? 0.0) / totalAmount * 100).toStringAsFixed(1)
                      : '0.0';
                    return BarTooltipItem(
                      '${payment.type}\n${payment.amount?.toStringAsFixed(2)} TL\n%$percentage',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < payments.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            payments[value.toInt()].type ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF444444),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 36,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: maxY > 2000 ? maxY / 4 : maxY / 3,
                    getTitlesWidget: (value, meta) {
                      String formattedValue;
                      if (value >= 1000) {
                        formattedValue = '${(value / 1000).toStringAsFixed(1)}K';
                      } else {
                        formattedValue = value.toInt().toString();
                      }
                      
                      return Text(
                        formattedValue,
                        style: const TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF666666),
                        ),
                      );
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
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 2000 ? maxY / 4 : maxY / 3,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              barGroups: payments.asMap().entries.map((entry) {
                final int index = entry.key;
                final payment = entry.value;
                
                final Color color = payment.color != null && payment.color!.startsWith('#')
                    ? _hexToColor(payment.color!)
                    : Colors.blue;
                
                final double barWidth = payments.length > 3 ? 16 : 25;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: payment.amount ?? 0,
                      color: color,
                      width: barWidth,
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: Colors.grey.shade100,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        
        // Tutarlar ve yüzdeler
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: payments.map((payment) {
              final Color color = payment.color != null && payment.color!.startsWith('#')
                  ? _hexToColor(payment.color!)
                  : Colors.blue;
              
              final double percentage = totalAmount > 0 
                  ? ((payment.amount ?? 0.0) / totalAmount * 100)
                  : 0.0;
              
              return Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.type ?? 'Bilinmeyen',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${payment.amount?.toStringAsFixed(2)} TL (%${percentage.toStringAsFixed(1)})',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF666666),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  // Masa doluluk oranını gösteren pasta grafiği 
  Widget _buildOccupancyChart(StatisticsViewModel viewModel) {
    final int totalTables = viewModel.statistics?.totalTables ?? 0;
    final int orderTables = viewModel.statistics?.orderTables ?? 0;
    final int emptyTables = totalTables - orderTables;
    
    if (totalTables <= 0) {
      return const Center(
        child: Text(
          'Masa verisi yok',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }
    
    final double occupancyPercentage = totalTables > 0 
        ? (orderTables / totalTables * 100)
        : 0.0;
    
    // Dolu ve boş masalar için renkler
    const Color occupiedColor = Color(0xFFFF4560);
    const Color emptyColor = Color(0xFF13D8AA);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Masa Doluluk Oranı',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Column(
            children: [
              // Pasta grafiği
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 60,
                          startDegreeOffset: -90,
                          sections: [
                            // Dolu masalar
                            PieChartSectionData(
                              color: occupiedColor,
                              value: orderTables.toDouble(),
                              title: '',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 0),
                            ),
                            // Boş masalar
                            PieChartSectionData(
                              color: emptyColor,
                              value: emptyTables.toDouble(),
                              title: '',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Merkezdeki doluluk oranı
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 6,
                                    color: Colors.black.withOpacity(0.05),
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${occupancyPercentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const Text(
                                    'Doluluk',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Açıklamalar
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // Dolu masalar
                      Expanded(
                        child: _buildTableInfoRow(
                          color: occupiedColor,
                          title: 'Dolu Masalar',
                          count: orderTables,
                          percentage: occupancyPercentage,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Boş masalar
                      Expanded(
                        child: _buildTableInfoRow(
                          color: emptyColor,
                          title: 'Boş Masalar',
                          count: emptyTables,
                          percentage: 100 - occupancyPercentage,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Toplam masalar
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.table_restaurant,
                              size: 16,
                              color: Color(0xFF666666),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Toplam Masalar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$totalTables masa',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Masa bilgi satırı widget'ı
  Widget _buildTableInfoRow({
    required Color color,
    required String title,
    required int count,
    required double percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$count masa (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // HexColor'ı Flutter Color'a dönüştürme
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse('0x$hexColor'));
  }
} 