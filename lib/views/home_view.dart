import 'package:flutter/material.dart';
import 'package:pos701/models/statistics_model.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/viewmodels/statistics_viewmodel.dart';
import 'package:pos701/widgets/app_drawer.dart';
import 'package:pos701/widgets/dashboard_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pos701/widgets/notification_badge.dart';
import 'package:pos701/views/notifications_view.dart';
import 'package:pos701/views/login_view.dart';
import 'package:pos701/services/api_service.dart';

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
    
    // Yetkisiz erişim hatası kontrolü ve login sayfasına yönlendirme
    if (statisticsViewModel.errorMessage != null && 
        statisticsViewModel.errorMessage!.contains('Yetkisiz erişim') && 
        statisticsViewModel.errorMessage!.contains('417')) {
      // Bir kereden fazla yönlendirmeyi önlemek için gecikmeli çalıştır
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Token ve kullanıcı bilgilerini temizle
        final apiService = Provider.of<ApiService>(context, listen: false);
        await apiService.clearToken();
        
        // Login sayfasına yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      });
    }
    
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
          // Bildirim butonu
          NotificationBadge(
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsView()),
                );
              },
              tooltip: 'Bildirimler',
            ),
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
                        const SizedBox(height: 14),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.expenseCardColor),
                          icon: Icons.currency_exchange,
                          value: statisticsViewModel.statistics?.totalExpenseAmount ?? '',
                          title: statisticsViewModel.statistics?.totalExpenseAmountText ?? '',
                        ),
                        const SizedBox(height: 14),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.orderCardColor),
                          icon: Icons.coffee,
                          value: statisticsViewModel.statistics?.totalOpenAmount ?? '',
                          title: statisticsViewModel.statistics?.totalOpenAmountText ?? '',
                        ),
                        const SizedBox(height: 14),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.customerCardColor),
                          icon: Icons.people,
                          value: '${statisticsViewModel.statistics?.totalGuest}',
                          title: statisticsViewModel.statistics?.totalGuestText ?? '',
                        ),
                        const SizedBox(height: 24),
                        
                        Container(
                          height: 450,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Günlük Satış Grafiği',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(AppConstants.chartLineColor),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Bugün',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              Expanded(
                                child: _buildSalesChart(statisticsViewModel),
                              ),
                            ],
                          ),
                        ),
                        
                        Container(
                          height: 450,
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildPaymentTypesChart(statisticsViewModel),
                        ),
                        
                        Container(
                          height: 380,
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
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
            fontSize: 14,
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
      maxY = maxY * 1.2; // Üst boşluğu artır
      
      // Eğer min ve max eşitse, görsel aralık oluştur
      if (minY == maxY) {
        minY = minY > 0 ? 0 : minY - 1;
        maxY = maxY + 1;
      }
    } else {
      // Veri yoksa varsayılan değerler kullan
      maxY = 1.0;
    }
    
    // Interval değerinin 0 olmamasını sağla
    double horizontalInterval = maxY > 5 ? maxY / 4 : 1; // Yatay çizgi sayısını azalt
    if (horizontalInterval <= 0) {
      horizontalInterval = 1.0; // Minimum interval değeri
    }
    
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.shade800,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final int hour = touchedSpot.x.toInt();
                  final double amount = touchedSpot.y;
                  return LineTooltipItem(
                    '$hour:00\n${amount.toStringAsFixed(1)} TL',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: horizontalInterval,
            verticalInterval: 4, // Dikey ızgaraları seyrekleştir
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 0.5, // İnce çizgi
                dashArray: [5, 5], // Kesikli çizgi
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 0.5, // İnce çizgi
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24, // Boyutu azalt
                interval: 4, // Sadece her 4 saatte bir göster
                getTitlesWidget: (value, meta) {
                  if (value % 4 == 0 && value <= 24) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${value.toInt()}:00',
                        style: const TextStyle(
                          color: Color(0xff72719b),
                          fontWeight: FontWeight.normal,
                          fontSize: 9, // Font boyutu küçültüldü
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: horizontalInterval,
                reservedSize: 40, // Boyutu azalt
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
                      color: Color(0xff72719b),
                      fontWeight: FontWeight.normal,
                      fontSize: 9, // Font boyutu küçültüldü
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
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
              left: BorderSide(color: Colors.grey.shade300, width: 0.5),
              right: BorderSide.none,
              top: BorderSide.none,
            ),
          ),
          minX: 0,
          maxX: 24,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3, // Eğriyi biraz daha yumuşat
              color: Color(AppConstants.chartLineColor),
              barWidth: 3, // Çizgi inceltildi
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: false, // Noktaları kaldır, sadece çizgi göster
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3, // Nokta boyutu küçültüldü
                    color: Color(AppConstants.chartLineColor),
                    strokeWidth: 1, // Kenar çizgisi inceltildi
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Color(AppConstants.chartLineColor).withOpacity(0.1), // Daha hafif dolgu
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(AppConstants.chartLineColor).withOpacity(0.2),
                    Color(AppConstants.chartLineColor).withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            fontSize: 14,
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
    
    // Eğer maxY hala 0 ise, minimum değer ata
    if (maxY <= 0) {
      maxY = 1.0;
    }
    
    // Interval değerlerinin 0 olmamasını sağla
    double leftTitleInterval = maxY > 2000 ? maxY / 4 : maxY / 3;
    if (leftTitleInterval <= 0) {
      leftTitleInterval = 1.0; // Minimum interval değeri
    }
    
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
        const SizedBox(height: 40),
        
        // Grafik
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceBetween,
              groupsSpace: 25,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey.shade800,
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(10),
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
                        fontSize: 10,
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
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            payments[value.toInt()].type ?? '',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF444444),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: leftTitleInterval,
                    getTitlesWidget: (value, meta) {
                      String formattedValue;
                      if (value >= 1000) {
                        formattedValue = '${(value / 1000).toStringAsFixed(1)}K';
                      } else {
                        formattedValue = value.toInt().toString();
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          formattedValue,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF666666),
                          ),
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
                horizontalInterval: leftTitleInterval,
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
                    : Colors.pink.shade300;
                
                final double barWidth = payments.length > 4 ? 12 : payments.length > 2 ? 16 : 22;

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
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        
        // Sadeleştirilmiş tutarlar ve yüzdeler
        Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Ödeme tiplerini 2 veya 3'lü gruplarda göster
              for (int i = 0; i < payments.length; i += 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (int j = i; j < i + 3 && j < payments.length; j++)
                        Expanded(
                          child: _buildPaymentLegendItem(payments[j], totalAmount),
                        ),
                      // Boş alan ekleme (eğer son grupta 3'ten az öğe varsa)
                      if (i + 3 > payments.length)
                        for (int k = 0; k < 3 - (payments.length - i); k++)
                          const Spacer(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Ödeme açıklama öğesi
  Widget _buildPaymentLegendItem(PaymentData payment, double totalAmount) {
    final Color color = payment.color != null && payment.color!.startsWith('#')
        ? _hexToColor(payment.color!)
        : Colors.pink.shade300;
    
    final double percentage = totalAmount > 0 
        ? ((payment.amount ?? 0.0) / totalAmount * 100)
        : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.type ?? 'Bilinmeyen',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '${payment.amount?.toStringAsFixed(0)} ₺ (%${percentage.toStringAsFixed(0)})',
                  style: const TextStyle(
                    fontSize: 7,
                    color: Color(0xFF666666),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Masa doluluk oranını gösteren pasta grafiği 
  Widget _buildOccupancyChart(StatisticsViewModel viewModel) {
    // Null değerlere karşı güvenli bir şekilde değerleri alalım
    final int totalTables = viewModel.statistics?.totalTables ?? 0;
    final int orderTables = viewModel.statistics?.orderTables ?? 0;
    final int emptyTables = totalTables > 0 ? totalTables - orderTables : 0;
    
    // API'den gelen veriler geçersiz olduğunda
    if (totalTables <= 0) {
      return const Center(
        child: Text(
          'Veri yok veya masa bilgisi alınamadı',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }
    
    // Doluluk oranını hesapla
    final double occupancyPercentage = totalTables > 0 
        ? (orderTables / totalTables * 100)
        : 0.0;
    
    // Dolu ve boş masalar için renkler
    const Color occupiedColor = Color(0xFFFF4560); // Kırmızı tonu
    const Color emptyColor = Color(0xFF13D8AA); // Yeşil/Turkuaz tonu
    
    // Her iki değer de sıfır olduğunda grafik çalışmayacağı için
    // en azından görsel olarak doğru görünmesi için minimum değerler atayalım
    final double occupiedValue = orderTables > 0 ? orderTables.toDouble() : 0.1;
    final double emptyValue = emptyTables > 0 ? emptyTables.toDouble() : 0.1;
    
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
        const SizedBox(height: 15),
        Expanded(
          child: Column(
            children: [
              // Pasta grafiği ve merkezdeki yüzde
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 55,
                          startDegreeOffset: -90,
                          sections: [
                            // Dolu masalar
                            PieChartSectionData(
                              color: occupiedColor,
                              value: occupiedValue, // Minimum değer kullanıyoruz
                              title: '',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 0),
                            ),
                            // Boş masalar
                            PieChartSectionData(
                              color: emptyColor,
                              value: emptyValue, // Minimum değer kullanıyoruz
                              title: '',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Merkezdeki doluluk oranı (daha sade)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${occupancyPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 2), // Boşluk azaltıldı
                          const Text(
                            'Doluluk',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Açıklamalar (daha az yer kaplayacak şekilde)
              Expanded(
                flex: 2, // Açıklama alanına daha az yer ver
                child: Container(
                  margin: const EdgeInsets.only(top: 15), // Boşluk azaltıldı
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10), // Padding ayarlandı
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
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
                      
                      const SizedBox(width: 20),
                      
                      // Boş masalar
                      Expanded(
                        child: _buildTableInfoRow(
                          color: emptyColor,
                          title: 'Boş Masalar',
                          count: emptyTables,
                          percentage: 100 - occupancyPercentage,
                        ),
                      ),
                      
                      const SizedBox(width: 20),
                      
                      // Toplam masalar
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.table_restaurant,
                              size: 20,
                              color: Color(0xFF666666),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Toplam Masalar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF666666),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$totalTables masa',
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '$count masa (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 12,
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