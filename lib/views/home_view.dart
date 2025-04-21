import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
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
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      if (userViewModel.userInfo == null) {
        userViewModel.loadUserInfo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    
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
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: userViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : userViewModel.errorMessage != null
              ? Center(child: Text('Hata: ${userViewModel.errorMessage}'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DashboardCard(
                          backgroundColor: Color(AppConstants.incomeCardColor),
                          icon: Icons.payments,
                          value: '₺0.00',
                          title: 'Bugün alınan ödemeler',
                        ),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.expenseCardColor),
                          icon: Icons.currency_exchange,
                          value: '₺0.00',
                          title: 'Bugünkü toplam gider tutarı',
                        ),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.orderCardColor),
                          icon: Icons.coffee,
                          value: '₺0.00',
                          title: 'Açık sipariş toplamı',
                        ),
                        DashboardCard(
                          backgroundColor: Color(AppConstants.customerCardColor),
                          icon: Icons.people,
                          value: '0',
                          title: 'Bugün ağırlanan misafir sayısı',
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
                                child: LineChart(
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
                                        spots: const [
                                          FlSpot(0, 0),
                                          FlSpot(2, 0),
                                          FlSpot(4, 0),
                                          FlSpot(6, 0),
                                          FlSpot(8, 0),
                                          FlSpot(10, 0),
                                          FlSpot(12, 0),
                                          FlSpot(14, 0),
                                          FlSpot(16, 0),
                                          FlSpot(18, 0),
                                          FlSpot(20, 0),
                                          FlSpot(22, 0),
                                          FlSpot(24, 0),
                                        ],
                                        isCurved: true,
                                        color: Color(AppConstants.chartLineColor),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(show: false),
                                        belowBarData: BarAreaData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
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
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Veri yok',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
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
} 