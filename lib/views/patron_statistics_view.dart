import 'package:flutter/material.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/boss_statistics_viewmodel.dart';
import 'package:pos701/models/boss_statistics_model.dart';
import 'package:pos701/utils/app_logger.dart';
import 'package:intl/intl.dart';
import 'package:pos701/views/statistics_detail_view.dart';
import 'package:pos701/widgets/app_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // Tarih filtresi için yeni state'ler
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isCustomDateRange = false;
  
  // Grafik için yeni state'ler
  int? _touchedIndex;
  
  // Görünüm değiştirme için state
  bool _isGridView = true;

  final List<String> _tabs = ['Raporlar', 'Grafik'];
  final List<String> _periods = ['Bugün', 'Dün', 'Bu Hafta', 'Bu Ay', 'Bu Yıl'];



  @override
  void initState() {
    super.initState();
    _logger.i('🚀 Patron Statistics View: initState çağrıldı');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.d('📱 Patron Statistics View: Post frame callback çalıştırılıyor');
      _loadCachedSettings();
      _loadStatistics();
    });
  }

  Future<void> _loadCachedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isGridView = prefs.getBool('patron_stats_grid_view') ?? true;
        _selectedTabIndex = prefs.getInt('patron_stats_selected_tab') ?? 0;
        _selectedPeriodIndex = 0; // Her zaman "Bugün" seçili olsun
      });
      _logger.d('📱 Cache\'den ayarlar yüklendi: grid=$_isGridView, tab=$_selectedTabIndex, period=$_selectedPeriodIndex');
    } catch (e) {
      _logger.e('❌ Cache ayarları yüklenirken hata: $e');
    }
  }

  Future<void> _saveCachedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('patron_stats_grid_view', _isGridView);
      await prefs.setInt('patron_stats_selected_tab', _selectedTabIndex);
      // Periyot seçimi cache'lenmez, her zaman "Bugün" olarak başlar
      _logger.d('💾 Ayarlar cache\'e kaydedildi: grid=$_isGridView, tab=$_selectedTabIndex, period=$_selectedPeriodIndex');
    } catch (e) {
      _logger.e('❌ Cache ayarları kaydedilirken hata: $e');
    }
  }

  void _loadStatistics() {
    _logger.i('🔄 Patron Statistics View: Veri yükleme başlatılıyor...');
    
    final viewModel = Provider.of<BossStatisticsViewModel>(context, listen: false);
    Map<String, String> dateRange;
    String order;
    
    if (_isCustomDateRange && _selectedStartDate != null && _selectedEndDate != null) {
      // Özel tarih aralığı kullanılıyor
      final formatter = DateFormat('dd.MM.yyyy');
      dateRange = {
        'startDate': formatter.format(_selectedStartDate!),
        'endDate': formatter.format(_selectedEndDate!),
      };
      order = 'custom'; // API'de özel tarih aralığı için
      _logger.d('📅 Özel tarih aralığı: ${_formatDateRangeForDisplay(_selectedStartDate!, _selectedEndDate!)}');
    } else {
      // Standart periyot kullanılıyor
      dateRange = _getDateRangeForPeriod(_selectedPeriodIndex);
      order = _getOrderForPeriod(_selectedPeriodIndex);
      _logger.d('📋 Seçili periyot: ${_periods[_selectedPeriodIndex]} (index: $_selectedPeriodIndex)');
      _logger.d('📅 Tarih aralığı: ${_formatDateRangeForDisplay(DateFormat('dd.MM.yyyy').parse(dateRange['startDate']!), DateFormat('dd.MM.yyyy').parse(dateRange['endDate']!))}');
      _logger.d('📅 Order: $order');
    }
    
    viewModel.fetchBossStatistics(
      userToken: widget.userToken,
      compID: widget.compID,
      startDate: dateRange['startDate']!,
      endDate: dateRange['endDate']!,
      order: order,
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

  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Bugün';
    } else if (dateOnly == yesterday) {
      return 'Dün';
    } else {
      final formatter = DateFormat('dd MMMM yyyy', 'tr_TR');
      return formatter.format(date);
    }
  }

  String _formatDateRangeForDisplay(DateTime startDate, DateTime endDate) {
    final startFormatted = _formatDateForDisplay(startDate);
    final endFormatted = _formatDateForDisplay(endDate);
    
    if (startFormatted == endFormatted) {
      return startFormatted;
    } else {
      return '$startFormatted - $endFormatted';
    }
  }

  String _getOrderForPeriod(int periodIndex) {
    switch (periodIndex) {
      case 0: // Bugün
        return 'today';
      case 1: // Dün
        return 'today';
      case 2: // Bu Hafta
        return 'week';
      case 3: // Bu Ay
        return 'month';
      case 4: // Bu Yıl
        return 'year';
      default:
        return 'today';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const AppDrawer(),
      appBar: _buildAppBar(userViewModel, primaryColor),
      body: Column(
        children: [
          // Periyot seçiciyi sadece raporlar sekmesinde göster
          if (_selectedTabIndex == 0) _buildPeriodSelector(primaryColor),
          Expanded(
            child: _buildStatisticsContent(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(UserViewModel userViewModel, Color primaryColor) {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      title: _isCustomDateRange ? Text(
        _formatDateRangeForDisplay(_selectedStartDate!, _selectedEndDate!),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ) : Text(
        userViewModel.userInfo?.company?.compName ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 0),
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
                    _saveCachedSettings();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? primaryColor : Colors.white,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.filter_list, 
            color: Colors.black87,
          ),
          onPressed: () => _showDateRangePicker(),
        ),
        // Tarih filtresi aktifse temizleme butonu
        if (_isCustomDateRange)
          IconButton(
            icon: const Icon(
              Icons.clear,
              color: Colors.black,
            ),
            onPressed: _clearDateFilter,
          ),
        // Görünüm değiştirme ikonu (sadece raporlar sekmesinde göster)
        if (_selectedTabIndex == 0)
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
              _saveCachedSettings();
            },
          ),
      ],
    );
  }

  Widget _buildPeriodSelector(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: _periods.asMap().entries.map((entry) {
          int index = entry.key;
          String period = entry.value;
          bool isSelected = index == _selectedPeriodIndex && !_isCustomDateRange;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriodIndex = index;
                  _isCustomDateRange = false;
                  _selectedStartDate = null;
                  _selectedEndDate = null;
                });
                _saveCachedSettings();
                _loadStatistics();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey[300]!,
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Text(
                       period,
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         color: isSelected ? Colors.white : Colors.grey[700],
                         fontSize: 12,
                         fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                       ),
                     ),
                     if (_isCustomDateRange && _selectedStartDate != null && _selectedEndDate != null && isSelected)
                       Padding(
                         padding: const EdgeInsets.only(top: 4),
                         child: Text(
                           _formatDateRangeForDisplay(_selectedStartDate!, _selectedEndDate!),
                           textAlign: TextAlign.center,
                           style: const TextStyle(
                             color: Colors.white,
                             fontSize: 8,
                             fontWeight: FontWeight.normal,
                           ),
                         ),
                       ),
                   ],
                 ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(AppConstants.primaryColorValue),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
        _isCustomDateRange = true;
      });
      _saveCachedSettings();
      _loadStatistics();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _isCustomDateRange = false;
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
    _saveCachedSettings();
    _loadStatistics();
  }

  Widget _buildIconWidget(String iconUrl, Color primaryColor) {
    if (iconUrl.toLowerCase().endsWith('.svg')) {
      // SVG dosyası için
      return SvgPicture.network(
        iconUrl,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
       
      );
    } else {
      // Normal resim dosyası için
      return Image.network(
        iconUrl,
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.help_outline,
            size: 24,
            color: primaryColor,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 24,
            height: 24,
           
          );
        },
      );
    }
  }

  Widget _buildStatisticsContent() {
    return Consumer<BossStatisticsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.errorMessage != null) {
          return _buildErrorWidget(viewModel);
        }

        if (viewModel.statistics.isEmpty) {
          return _buildEmptyWidget();
        }

        // Tab bar'a göre içeriği değiştir
        switch (_selectedTabIndex) {
          case 0: // Raporlar
            return _isGridView ? _buildStatisticsGrid(viewModel) : _buildStatisticsList(viewModel);
          case 1: // Grafik
            return _buildChartView(viewModel);
          default:
            return _isGridView ? _buildStatisticsGrid(viewModel) : _buildStatisticsList(viewModel);
        }
      },
    );
  }

  // Grid yerleşimini ekran genişliğine göre ayarlayan yardımcılar
  int _getGridCrossAxisCount(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return 6; // Büyük tablet ve üstü
    }
    if (width >= 900) {
      return 5; // Tablet
    }
    if (width >= 600) {
      return 4 ; // Büyük telefon / küçük tablet
    }
    return 2; // Telefon
  }

  double _getGridChildAspectRatio(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return 1.4;
    }
    if (width >= 900) {
      return 1.35;
    }
    if (width >= 600) {
      return 1.3;
    }
    return 1.25;
  }

  Widget _buildErrorWidget(BossStatisticsViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Hata',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              viewModel.clearError();
              _loadStatistics();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConstants.primaryColorValue),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Veri Bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seçili periyot için istatistik verisi bulunmuyor',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(BossStatisticsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(context),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: _getGridChildAspectRatio(context),
        ),
        itemCount: viewModel.statistics.length,
        itemBuilder: (context, index) {
          final statistic = viewModel.statistics[index];
          return _buildStatisticsCard(statistic);
        },
      ),
    );
  }

  Widget _buildStatisticsList(BossStatisticsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        itemCount: viewModel.statistics.length,
        itemBuilder: (context, index) {
          final statistic = viewModel.statistics[index];
          return _buildStatisticsListItem(statistic);
        },
      ),
    );
  }

  Widget _buildStatisticsCard(BossStatisticsModel statistic) {
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    
    return GestureDetector(
      onTap: () => _showStatisticsDetail(statistic),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              statistic.statisticsIcon.isNotEmpty
                  ? _buildIconWidget(statistic.statisticsIcon, primaryColor)
                  : Icon(
                      Icons.help_outline,
                      size: 24,
                      color: primaryColor,
                    ),
              const SizedBox(height: 12),
              Text(
                statistic.statisticsTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                statistic.statisticsAmount,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsListItem(BossStatisticsModel statistic) {
    final Color primaryColor = Color(AppConstants.primaryColorValue);
    
    return GestureDetector(
      onTap: () => _showStatisticsDetail(statistic),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // İkon - daha küçük
              Container(
                width: 32,
                height: 32,
                child: Center(
                  child: statistic.statisticsIcon.isNotEmpty
                      ? _buildIconWidget(statistic.statisticsIcon, primaryColor)
                      : Icon(
                          Icons.help_outline,
                          size: 16,
                          color: primaryColor,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // İsim - sol tarafta
              Expanded(
                child: Text(
                  statistic.statisticsTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Fiyat - sağ tarafta
              Text(
                statistic.statisticsAmount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(width: 8),
              // Ok ikonu
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartView(BossStatisticsViewModel viewModel) {
    final allGraphics = viewModel.graphics;
    final totalAmount = viewModel.totalGraphicAmount;
    
    if (allGraphics.isEmpty) {
      return _buildEmptyChartWidget();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pasta Grafiği
          Container(
            height: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '1 Haftalık Satış Dağılımı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 25),
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: _buildPieChartSections(allGraphics, totalAmount),
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (pieTouchResponse?.touchedSection != null) {
                              final touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                              // Aynı dilime tekrar tıklandığında eski haline dön
                              if (_touchedIndex == touchedIndex) {
                                _touchedIndex = null;
                              } else {
                                _touchedIndex = touchedIndex;
                              }
                            } else {
                              _touchedIndex = null;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Grafik Açıklamaları
          _buildChartLegend(allGraphics),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<BossStatisticsGraphicModel> graphics,
    double totalAmount,
  ) {
    final List<Color> colors = [
      Color(AppConstants.primaryColorValue),
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    // Sadece sıfır olmayan değerleri filtrele
    final nonZeroGraphics = graphics.where((graphic) => graphic.numericAmount > 0).toList();
    
    return nonZeroGraphics.asMap().entries.map((entry) {
      final index = entry.key;
      final graphic = entry.value;
      final percentage = totalAmount > 0 ? (graphic.numericAmount / totalAmount) * 100 : 0.0;
      final isTouched = _touchedIndex == index;
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: graphic.numericAmount,
        title: isTouched ? graphic.date : '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 90 : 80,
        titleStyle: TextStyle(
          fontSize: isTouched ? 10 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildChartLegend(List<BossStatisticsGraphicModel> graphics) {
    final List<Color> colors = [
      Color(AppConstants.primaryColorValue),
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    // Sıfır olmayan değerlerin indekslerini bul
    final nonZeroIndices = <int>[];
    for (int i = 0; i < graphics.length; i++) {
      if (graphics[i].numericAmount > 0) {
        nonZeroIndices.add(i);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Açıklaması',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          ...graphics.asMap().entries.map((entry) {
            final index = entry.key;
            final graphic = entry.value;
            final isZero = graphic.numericAmount == 0.0;
            
            // Sıfır olmayan değerler için pasta grafiğindeki aynı renk indeksini kullan
            Color color;
            if (isZero) {
              color = Colors.grey[300]!;
            } else {
              final nonZeroIndex = nonZeroIndices.indexOf(index);
              color = colors[nonZeroIndex % colors.length];
            }
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      graphic.date,
                      style: TextStyle(
                        fontSize: 14,
                        color: isZero ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ),
                  Text(
                    graphic.amount,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isZero ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyChartWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.pie_chart,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Grafik Verisi Yok',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seçili periyot için grafik verisi bulunmuyor',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDetail(BossStatisticsModel statistic) {
    _logger.i('📊 İstatistik detayı açılıyor: ${statistic.statisticsTitle}');
    
    Map<String, String> dateRange;
    String order;
    
    if (_isCustomDateRange && _selectedStartDate != null && _selectedEndDate != null) {
      // Özel tarih aralığı kullanılıyor
      final formatter = DateFormat('dd.MM.yyyy');
      dateRange = {
        'startDate': formatter.format(_selectedStartDate!),
        'endDate': formatter.format(_selectedEndDate!),
      };
      order = 'custom';
    } else {
      // Standart periyot kullanılıyor
      dateRange = _getDateRangeForPeriod(_selectedPeriodIndex);
      order = _getOrderForPeriod(_selectedPeriodIndex);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticsDetailView(
          userToken: widget.userToken,
          compID: widget.compID,
          statistic: statistic,
          startDate: dateRange['startDate']!,
          endDate: dateRange['endDate']!,
          order: order,
        ),
      ),
    );
  }
} 