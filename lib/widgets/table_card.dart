import 'package:flutter/material.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/widgets/table_selection_dialog.dart';
import 'package:pos701/widgets/table_merge_dialog.dart';
import 'package:pos701/widgets/table_unmerge_dialog.dart';
import 'package:provider/provider.dart';
import 'package:pos701/views/category_view.dart';
import 'package:pos701/viewmodels/user_viewmodel.dart';
import 'package:pos701/models/user_model.dart';
import 'package:pos701/views/tables_view.dart';

class TableCard extends StatelessWidget {
  final TableItem table;
  final VoidCallback onTap;
  final String userToken;
  final int compID;

  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
    required this.userToken,
    required this.compID,
  });

  void _showTableOptions(BuildContext context) {
    final TablesViewModel viewModel = Provider.of<TablesViewModel>(context, listen: false);
    
    // Responsive tasarım için ekran boyutlarını al
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final bool isLargeTablet = screenSize.width > 900;
    
    // Responsive boyutlar
    final double titleFontSize = isLargeTablet ? 20 : isTablet ? 18 : 17;
    final double padding = isLargeTablet ? 12.0 : isTablet ? 10.0 : 8.0;
    
    // Debug: Birleştirilmiş masa bilgisini konsola yazdir
    debugPrint('Masa bilgisi: ID=${table.tableID}, İsim=${table.tableName}');
    debugPrint('Birleştirilmiş mi: ${table.isMerged}');
    if (table.isMerged) {
      debugPrint('Birleştirilmiş masalar: ${table.mergedTableIDs}');
    }
    
    final TablesViewModel debugViewModel = Provider.of<TablesViewModel>(context, listen: false);
    final TableItem? debugMainTable = debugViewModel.getMainTableForMergedTable(table.tableID);
    if (debugMainTable != null) {
      debugPrint('Bu masa ${debugMainTable.tableName} (ID: ${debugMainTable.tableID}) ana masasına bağlı');
    }
    
    // Yan masa kontrolü: Masa bir ana masaya bağlıysa ve kendisi ana masa değilse yan masadır
    final bool isSideTable = debugMainTable != null && !table.isMerged;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                  child: Text(
                    'Masa & Sipariş İşlemleri',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                _optionButton(
                  bottomSheetContext,
                  icon: Icons.payment,
                  iconColor: Colors.red,
                  text: 'Hızlı Öde (${table.orderAmount})',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // Hızlı ödeme işlemi
                    Future.microtask(() {
                      _handleFastPay(context, viewModel);
                    });
                  },
                  isTablet: isTablet,
                ),
                const Divider(),
                _optionButton(
                  bottomSheetContext,
                  icon: Icons.cancel,
                  iconColor: Colors.blue,
                  text: 'İptal',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // İptal işlemi
                    Future.microtask(() {
                      _handleCancelOrder(context, viewModel);
                    });
                  },
                  isTablet: isTablet,
                ),
                const Divider(),
                _optionButton(
                  bottomSheetContext,
                  icon: Icons.swap_horiz,
                  iconColor: Colors.blue,
                  text: 'Masayı Değiştir',
                  onTap: () {
                    // Önce BottomSheet'i kapat, sonra işlemi gerçekleştir
                    Navigator.pop(bottomSheetContext);
                    // Context kapandıktan sonraki işlem için Future.microtask kullan
                    Future.microtask(() {
                      _handleTableChange(context, viewModel);
                    });
                  },
                  isTablet: isTablet,
                ),
                const Divider(),
                // Masa birleştirilmiş ise hem "Masaları Ayır" hem de "Masaları Birleştir" düğmeleri göster
                if (table.isMerged)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: isTablet ? 6 : 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                    ),
                    child: _optionButton(
                      bottomSheetContext,
                      icon: Icons.call_split,
                      iconColor: Colors.orange,
                      text: 'Masaları Ayır',
                      onTap: () {
                        // Önce BottomSheet'i kapat, sonra işlemi gerçekleştir
                        Navigator.pop(bottomSheetContext);
                        // Context kapandıktan sonraki işlem için Future.microtask kullan
                        Future.microtask(() {
                          _handleTableUnmerge(context, viewModel);
                        });
                      },
                      isTablet: isTablet,
                    ),
                  ),

                // Yan masa değilse (bağımsız masa veya ana masa) "Masaları Birleştir" seçeneğini göster
                if (!isSideTable) ...[
                  _optionButton(
                    bottomSheetContext,
                    icon: Icons.merge_type,
                    iconColor: Colors.blue,
                    text: 'Masaları Birleştir',
                    onTap: () {
                      // Önce BottomSheet'i kapat, sonra işlemi gerçekleştir
                      Navigator.pop(bottomSheetContext);
                      // Context kapandıktan sonraki işlem için Future.microtask kullan
                      Future.microtask(() {
                        _handleTableMerge(context, viewModel);
                      });
                    },
                    isTablet: isTablet,
                  ),
                  const Divider(),
                ],
                _optionButton(
                  bottomSheetContext,
                  icon: Icons.receipt,
                  iconColor: Colors.blue,
                  text: 'Adisyon Aktar',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // Adisyon aktarma işlemi
                    Future.microtask(() {
                      _handleOrderTransfer(context, viewModel);
                    });
                  },
                  isTablet: isTablet,
                ),
                const Divider(),
                _optionButton(
                  bottomSheetContext,
                  icon: Icons.print,
                  iconColor: Colors.blue,
                  text: 'Yazdır',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // Yazdırma işlemi
                  },
                  isTablet: isTablet,
                ),
                const Divider(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext);
                  },
                  icon: Icon(
                    Icons.arrow_back, 
                    color: Colors.blue, 
                    size: isTablet ? 24 : 20
                  ),
                  label: Text(
                    'Vazgeç', 
                    style: TextStyle(
                      color: Colors.blue, 
                      fontSize: isTablet ? 17 : 15
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFastPay(BuildContext context, TablesViewModel viewModel) async {
    // Kullanıcı bilgilerini al
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    // Debug: Kullanıcı ve şirket bilgilerini kontrol et
    try {
      if (userViewModel.userInfo != null) {
      if (userViewModel.userInfo!.company != null) {
        }
      }
    } catch (e) {
    }
    
    // userInfo null ise anlık olarak yüklemeyi dene
    if (userViewModel.userInfo == null) {
      debugPrint('HIZLI ÖDE DEBUG → userInfo null, loadUserInfo() çağrılıyor');
      try {
        final bool loaded = await userViewModel.loadUserInfo();
        debugPrint('HIZLI ÖDE DEBUG → loadUserInfo sonucu: $loaded');
        if (loaded && userViewModel.userInfo != null) {
          debugPrint('HIZLI ÖDE DEBUG → Yüklenen kullanıcı: userID=${userViewModel.userInfo!.userID}, company null mu? ${userViewModel.userInfo!.company == null}');
          if (userViewModel.userInfo!.company != null) {
            debugPrint('HIZLI ÖDE DEBUG → Yüklenen company: compID=${userViewModel.userInfo!.company!.compID}, compName=${userViewModel.userInfo!.company!.compName}');
            debugPrint('HIZLI ÖDE DEBUG → Yüklenen compPayTypes length: ${userViewModel.userInfo!.company!.compPayTypes.length}');
          }
        }
      } catch (e) {
        debugPrint('HIZLI ÖDE DEBUG → loadUserInfo çağrısında hata: $e');
      }
    }
    
    // Kullanıcının ödeme tiplerini kontrol et
    if (userViewModel.userInfo == null || userViewModel.userInfo!.company == null || 
        userViewModel.userInfo!.company!.compPayTypes.isEmpty) {
      debugPrint('HIZLI ÖDE DEBUG → Ödeme tipleri boş veya erişilemedi. userInfo: ${userViewModel.userInfo != null}, company: ${userViewModel.userInfo?.company != null}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ödeme bilgileri alınamadı. Lütfen tekrar giriş yapın.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Ödeme tiplerini al
    final List<PaymentType> paymentTypes = userViewModel.userInfo!.company!.compPayTypes;
    // Debug: Ödeme tiplerini listele
    for (final PaymentType t in paymentTypes) {
      debugPrint('HIZLI ÖDE DEBUG → PayType: id=${t.typeID}, name=${t.typeName}, color=${t.typeColor}, img=${t.typeImg}');
    }
    PaymentType? selectedPaymentType;
    
    // Ödeme tipi seçme diyaloğu göster
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('Ödeme Tipi Seçin', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.4,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: paymentTypes.length,
            itemBuilder: (context, index) {
              final paymentType = paymentTypes[index];
              Color typeColor;
              try {
                typeColor = Color(int.parse(paymentType.typeColor.replaceFirst('#', '0xFF')));
              } catch (e) {
                typeColor = Colors.grey;
              }
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: typeColor.withOpacity(0.2),
                  child: paymentType.typeImg.isNotEmpty 
                    ? Image.network(
                        paymentType.typeImg,
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => 
                            Icon(Icons.payment, color: typeColor),
                      )
                    : Icon(Icons.payment, color: typeColor),
                ),
                title: Text(paymentType.typeName, style: TextStyle(fontSize: 15)),
                onTap: () {
                  selectedPaymentType = paymentType;
                  Navigator.of(dialogContext).pop();
                },
                trailing: Icon(Icons.chevron_right, color: typeColor, size: 20),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
    
    // Eğer ödeme tipi seçilmediyse işlemi iptal et
    if (selectedPaymentType == null) {
      return;
    }
    
    // Onay diyaloğu göster
    final confirmPay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('${selectedPaymentType!.typeName} ile Ödeme', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Text(
          '${table.tableName} masasının ${table.orderAmount} ₺ tutarındaki hesabı ${selectedPaymentType!.typeName} ile ödenecektir. Onaylıyor musunuz?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal', style: TextStyle(fontSize: 15)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Onayla', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirmPay != true) return;

    // Yükleniyor diyaloğu göster
    if (!context.mounted) return;
    
    BuildContext? loadingContext;
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // Yarı şeffaf arka plan
      builder: (ctx) {
        loadingContext = ctx;
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ödeme işlemi gerçekleştiriliyor...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu işlem birkaç saniye sürebilir',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Hızlı ödeme API çağrısı
      final success = await viewModel.fastPay(
        userToken: userToken,
        compID: compID,
        orderID: table.orderID,
        isDiscount: 0,
        discountType: 0,
        discount: 0,
        payType: selectedPaymentType!.typeID,
        payAction: "payClose",
      );
      
      // Yükleniyor diyaloğunu kapat
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        // ignore: use_build_context_synchronously
        Navigator.of(loadingContext!).pop();
        loadingContext = null;
      }
      
      // Küçük bir gecikme ekle
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (success) {
        // Başarılı mesajını göster
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedPaymentType!.typeName} ile ${viewModel.successMessage ?? 'ödeme başarıyla tamamlandı'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Masalar sayfasına yönlendir
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => TablesView(
                userToken: userToken,
                compID: compID,
                title: 'Masalar',
              ),
            ),
            (route) => false, // Tüm geçmiş sayfaları temizle
          );
        }
      } else {
        // Hata mesajını göster
        if (!context.mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Ödeme işlemi başarısız oldu'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Hızlı ödeme hatası: $e');
      
      // Yükleniyor diyaloğunu kapat (hata durumunda da)
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        // ignore: use_build_context_synchronously
        Navigator.of(loadingContext!).pop();
        loadingContext = null;
      }
      
      // Küçük bir gecikme ekle
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Hata mesajını göster
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme işlemi sırasında hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleTableUnmerge(BuildContext context, TablesViewModel viewModel) async {
    // Birleştirilmiş masaları al
    final List<TableItem> mergedTables = [];
    if (table.isMerged && table.mergedTableIDs.isNotEmpty) {
      for (int mergedTableID in table.mergedTableIDs) {
        final mergedTable = viewModel.getTableByID(mergedTableID);
        if (mergedTable != null) {
          mergedTables.add(mergedTable);
        }
      }
    }

    if (mergedTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayrılabilecek masa bulunamadı')),
      );
      return;
    }

    // Seçimli masa ayırma diyaloğunu göster
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => TableUnmergeDialog(
        mainTable: table,
        mergedTables: mergedTables,
        onTablesUnmerged: (selectedTables) async {
          if (selectedTables.isEmpty) return;
          
          // Seçilen masaların ID'lerini al
          final selectedTableIds = selectedTables.map((t) => t.tableID).toList();

          // TableCard üzerinden gelen güvenilir kimlik bilgilerini kullan
          final String userTokenValue = userToken;
          final int compIDValue = compID;

          // Yükleniyor diyaloğunu göster
          if (!context.mounted) return;
          
          BuildContext? loadingContext;
          // ignore: use_build_context_synchronously
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black54,
            builder: (ctx) {
              loadingContext = ctx;
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 8.0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Seçilen masalar ayrılıyor...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu işlem birkaç saniye sürebilir',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          try {
            // Seçimli masa ayırma API çağrısı
            final success = await viewModel.unMergeSelectedTables(
              userToken: userTokenValue,
              compID: compIDValue,
              tableID: table.tableID,
              orderID: table.orderID,
              tablesToUnmerge: selectedTableIds,
            );
            
            // Yükleniyor diyaloğunu kapat
            if (loadingContext != null && Navigator.canPop(loadingContext!)) {
              // ignore: use_build_context_synchronously
              Navigator.of(loadingContext!).pop();
              loadingContext = null;
            }
            
            // Küçük bir gecikme ekle
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (success) {
              // Başarılı mesajını göster
              if (!context.mounted) return;
              
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.successMessage ?? 'Seçilen masalar başarıyla ayrıldı'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
              
              // Masalar sayfasına yönlendir
              if (context.mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TablesView(
                      userToken: userTokenValue,
                      compID: compIDValue,
                      title: 'Masalar',
                    ),
                  ),
                  (route) => false, // Tüm geçmiş sayfaları temizle
                );
              }
            } else {
              // Hata mesajını göster
              if (!context.mounted) return;
              
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.errorMessage ?? 'Masa ayırma işlemi başarısız oldu'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } catch (e) {
            debugPrint('Masa ayırma hatası: $e');
            
            // Yükleniyor diyaloğunu kapat (hata durumunda da)
            if (loadingContext != null && Navigator.canPop(loadingContext!)) {
              // ignore: use_build_context_synchronously
              Navigator.of(loadingContext!).pop();
              loadingContext = null;
            }
            
            // Küçük bir gecikme ekle
            await Future.delayed(const Duration(milliseconds: 300));
            
            // Hata mesajını göster
            if (context.mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Masa ayırma işlemi sırasında hata oluştu: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handleTableChange(BuildContext context, TablesViewModel viewModel) async {
    final inactiveTables = viewModel.inactiveTables;
    
    if (inactiveTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktif olmayan masa bulunamadı')),
      );
      return;
    }

    // Boş (aktif olmayan) masa seçimi diyaloğunu göster
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => TableSelectionDialog(
        inactiveTables: inactiveTables,
        onTableSelected: (selectedTable) async {
          // Diyaloğu kapat
          Navigator.of(dialogContext).pop();
          
          // Küçük bir gecikme ekle
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Yükleniyor göstergesini ekranın ortasında göster
          if (!context.mounted) return;
          
          // Overlay olarak kullanacağımız widget'ı göster (şeffaf)
          OverlayEntry? loadingOverlay;
          loadingOverlay = OverlayEntry(
            builder: (ctx) => Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Masa değiştiriliyor...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bu işlem birkaç saniye sürebilir',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );

          // Overlay'i göster
          if (context.mounted) {
            Overlay.of(context).insert(loadingOverlay);
          }

          try {
            // Masa değiştirme API çağrısı
            final success = await viewModel.changeTable(
              userToken: userToken,
              compID: compID,
              orderID: table.orderID,
              tableID: selectedTable.tableID,
            );
            
            // Yükleniyor overlay'ini kaldır
            loadingOverlay.remove();
            loadingOverlay = null;
            
            // Küçük bir gecikme ekle
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (success) {
              // Başarılı mesajını göster
              if (!context.mounted) return;
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(viewModel.successMessage ?? 'Masa başarıyla değiştirildi')),
              );
              
              // Mevcut sayfadaki verileri güncelle, anasayfaya yönlendirme yapma
              if (context.mounted) {
                // ignore: use_build_context_synchronously
                await viewModel.refreshTablesDataSilently(
                  userToken: userToken,
                  compID: compID,
                );
              }
            } else {
              // Hata mesajını göster
              if (!context.mounted) return;
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.errorMessage ?? 'Masa değiştirme işlemi başarısız oldu'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            debugPrint('Masa değiştirme hatası: $e');
            
            // Yükleniyor overlay'ini kaldır (hata durumunda da)
            loadingOverlay?.remove();
            loadingOverlay = null;
            
            // Küçük bir gecikme ekle
            await Future.delayed(const Duration(milliseconds: 300));
            
            // Hata mesajını göster
            if (context.mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Masa değiştirme sırasında hata oluştu: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handleOrderTransfer(BuildContext context, TablesViewModel viewModel) async {
    // Hedef masa olarak aktif masaları listele
    final activeTables = viewModel.activeTables.where((t) => t.tableID != table.tableID).toList();
    
    if (activeTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktarılabilecek başka aktif masa bulunamadı')),
      );
      return;
    }

    // Hedef masa seçimi diyaloğunu göster
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text('Adisyon Aktarım', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adisyonu aktarmak istediğiniz hedef masayı seçin:',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activeTables.length,
                  itemBuilder: (context, index) {
                    final targetTable = activeTables[index];
                    return ListTile(
                      title: Text(targetTable.tableName, style: TextStyle(fontSize: 15)),
                      subtitle: Text('Sipariş: ${targetTable.orderAmount} ₺', style: TextStyle(fontSize: 13)),
                      onTap: () async {
                        // Onay dialogu göster
                        final confirmTransfer = await showDialog<bool>(
                          context: dialogContext,
                          builder: (confirmContext) => AlertDialog(
                            title: const Text('Onay', style: TextStyle(fontSize: 17)),
                            content: Text(
                              '${table.tableName} masasının adisyonu ${targetTable.tableName} masasına aktarılacak. Onaylıyor musunuz?',
                              style: TextStyle(fontSize: 15),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(confirmContext).pop(false),
                                child: const Text('İptal', style: TextStyle(fontSize: 15)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(confirmContext).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text('Onayla', style: TextStyle(color: Colors.white, fontSize: 15)),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmTransfer != true) return;
                        
                        // Kaynak ve hedef sipariş ID'lerini logla
                        debugPrint('📋 ADISYON AKTARIM BAŞLIYOR:');
                        debugPrint('📋 Kaynak Sipariş ID: ${table.orderID}, Masa: ${table.tableName}');
                        debugPrint('📋 Hedef Sipariş ID: ${targetTable.orderID}, Masa: ${targetTable.tableName}');
                        
                        // İlk diyaloğu kapat
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                        
                        // Küçük bir gecikme ekle
                        await Future.delayed(const Duration(milliseconds: 100));
                        
                        // Yükleme dialogu göster
                        if (!context.mounted) return;
                        
                        BuildContext? loadingContext;
                        // ignore: use_build_context_synchronously
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierColor: Colors.black54, // Yarı şeffaf arka plan
                          builder: (ctx) {
                            loadingContext = ctx;
                            return Dialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              elevation: 8.0,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Adisyon aktarılıyor...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Bu işlem birkaç saniye sürebilir',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                        
                        try {
                          // Adisyon aktarma işlemini gerçekleştir
                          debugPrint('📋 Adisyon aktarma API çağrısı yapılıyor...');
                          final success = await viewModel.transferOrder(
                            userToken: userToken,
                            compID: compID,
                            oldOrderID: table.orderID,
                            newOrderID: targetTable.orderID,
                          );
                          
                          // Yükleme dialogunu kapat
                          if (loadingContext != null && Navigator.canPop(loadingContext!)) {
                            // ignore: use_build_context_synchronously
                            Navigator.of(loadingContext!).pop();
                            loadingContext = null;
                          }
                          
                          // Küçük bir gecikme ekle
                          await Future.delayed(const Duration(milliseconds: 300));
                          
                          // Sonucu göster
                          if (!context.mounted) return;
                          
                          if (success) {
                            debugPrint('✅ Adisyon aktarma başarılı!');
                            debugPrint('✅ Yanıt: ${viewModel.successMessage}');
                            
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(viewModel.successMessage ?? 'Adisyon başarıyla aktarıldı'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            
                            // Masalar sayfasına yönlendir
                            if (context.mounted) {
                              // ignore: use_build_context_synchronously
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TablesView(
                                    userToken: userToken,
                                    compID: compID,
                                    title: 'Masalar',
                                  ),
                                ),
                                (route) => false, // Tüm geçmiş sayfaları temizle
                              );
                            }
                          } else {
                            debugPrint('❌ Adisyon aktarma başarısız!');
                            debugPrint('❌ Hata: ${viewModel.errorMessage}');
                            
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(viewModel.errorMessage ?? 'Adisyon aktarma işlemi başarısız oldu'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint('🔴 Adisyon aktarma hatası: $e');
                          
                          // Yükleme dialogunu kapat (hata durumunda da)
                          if (loadingContext != null && Navigator.canPop(loadingContext!)) {
                            // ignore: use_build_context_synchronously
                            Navigator.of(loadingContext!).pop();
                            loadingContext = null;
                          }
                          
                          // Küçük bir gecikme ekle
                          await Future.delayed(const Duration(milliseconds: 300));
                          
                          // Hata mesajını göster
                          if (context.mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Adisyon aktarma işlemi sırasında hata oluştu: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  void _handleTableMerge(BuildContext context, TablesViewModel viewModel) async {
    // Ana masa ile birleştirilecek masaların seçimi için kullanılabilir masaları al
    final availableTables = viewModel.getAvailableTablesForMerge(table.tableID);
    
    if (availableTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Birleştirilebilecek masa bulunamadı')),
      );
      return;
    }

    // Ana masanın mevcut birleştirilmiş masalarını al
    final List<TableItem> existingMergedTables = [];
    if (table.isMerged && table.mergedTableIDs.isNotEmpty) {
      for (int mergedTableID in table.mergedTableIDs) {
        final mergedTable = viewModel.getTableByID(mergedTableID);
        if (mergedTable != null) {
          existingMergedTables.add(mergedTable);
        }
      }
    }

    // Birleştirilecek masaların seçimi diyaloğunu göster
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => TableMergeDialog(
        mainTable: table,
        availableTables: availableTables,
        existingMergedTables: existingMergedTables,
        onTablesMerged: (selectedTables) async {
          // Seçilen masa ID'lerini al
          final selectedTableIds = selectedTables.map((t) => t.tableID).toList();
          
          // Diyaloğu kapat
          if (Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext).pop();
          }
          
          // Küçük bir gecikme ekle
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Yükleniyor diyaloğunu göster
          if (!context.mounted) return;
          
          BuildContext? loadingContext;
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black54, // Yarı şeffaf arka plan
            builder: (ctx) {
              loadingContext = ctx;
              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 8.0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Masalar birleştiriliyor...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu işlem birkaç saniye sürebilir',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          try {
            // Masa birleştirme API çağrısı
            final success = await viewModel.mergeTables(
              userToken: userToken,
              compID: compID,
              mainTableID: table.tableID,
              orderID: table.orderID,
              tablesToMerge: selectedTableIds,
              step: 'merged',
            );
            
            // Yükleniyor diyaloğunu kapat
            if (loadingContext != null && Navigator.canPop(loadingContext!)) {
              // ignore: use_build_context_synchronously
              Navigator.of(loadingContext!).pop();
              loadingContext = null;
            }
            
            // Küçük bir gecikme ekle
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (success) {
              // Başarılı mesajını göster
              if (context.mounted) {
                // Başarılı bir birleştirme için özel bir diyalog göster
                // ignore: use_build_context_synchronously
                showDialog(
                  context: context,
                  builder: (successContext) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(AppConstants.primaryColorValue),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('İşlem Başarılı', style: TextStyle(fontSize: 17)),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${table.tableName} masası başarıyla birleştirildi.', style: TextStyle(fontSize: 15)),
                        const SizedBox(height: 12),
                        const Text(
                          'Birleştirilen masalar sol üst köşedeki insan simgesiyle işaretlenmiştir.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(successContext).pop();
                          
                          // Masalar sayfasına yönlendir
                          if (context.mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TablesView(
                                  userToken: userToken,
                                  compID: compID,
                                  title: 'Masalar',
                                ),
                              ),
                              (route) => false, // Tüm geçmiş sayfaları temizle
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(AppConstants.primaryColorValue),
                        ),
                        child: const Text('Tamam', style: TextStyle(fontSize: 15)),
                      ),
                    ],
                  ),
                );
                
                // SnackBar ile de bildirim göster
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.successMessage ?? 'Masalar başarıyla birleştirildi'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } else {
              // Hata mesajını göster
              if (context.mounted) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.errorMessage ?? 'Masa birleştirme işlemi başarısız oldu'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Masa birleştirme hatası: $e');
            
            // Yükleniyor diyaloğunu kapat (hata durumunda da)
            if (loadingContext != null && Navigator.canPop(loadingContext!)) {
              // ignore: use_build_context_synchronously
              Navigator.of(loadingContext!).pop();
              loadingContext = null;
            }
            
            // Küçük bir gecikme ekle
            await Future.delayed(const Duration(milliseconds: 300));
            
            // Hata mesajını göster
            if (context.mounted) {
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Masa birleştirme sırasında hata oluştu: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handleCancelOrder(BuildContext context, TablesViewModel viewModel) async {
    // Sipariş iptali için onay diyaloğu
    if (!table.isActive || table.orderID <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İptal edilecek aktif bir sipariş bulunamadı.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // İptal nedeni girişi için controller
    final TextEditingController cancelDescController = TextEditingController();
    
    // İptal onay diyaloğu
    final confirmCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('Sipariş İptali', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu işlem siparişi iptal edecek ve masayı kapatacaktır. Devam etmek istiyor musunuz?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cancelDescController,
              decoration: const InputDecoration(
                hintText: 'İptal nedeni (opsiyonel)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 2,
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Siparişi İptal Et', style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirmCancel != true) return;

    // Yükleniyor diyaloğu göster
    if (!context.mounted) return;
    
    BuildContext? loadingContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // Yarı şeffaf arka plan
      builder: (ctx) {
        loadingContext = ctx;
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sipariş iptal ediliyor...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu işlem birkaç saniye sürebilir',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Sipariş iptal API çağrısı
      final success = await viewModel.cancelOrder(
        userToken: userToken,
        compID: compID,
        orderID: table.orderID,
        cancelDesc: cancelDescController.text,
      );
      
      // Yükleniyor diyaloğunu kapat
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        // ignore: use_build_context_synchronously
        Navigator.of(loadingContext!).pop();
        loadingContext = null;
      }
      
      // Küçük bir gecikme ekle
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!context.mounted) return;
      
      if (success) {
        // Başarılı mesajını göster
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.successMessage ?? 'Sipariş başarıyla iptal edildi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Masalar sayfasına yönlendir
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => TablesView(
                userToken: userToken,
                compID: compID,
                title: 'Masalar',
              ),
            ),
            (route) => false, // Tüm geçmiş sayfaları temizle
          );
        }
      } else {
        // Hata mesajını göster
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Sipariş iptal edilemedi'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Sipariş iptal hatası: $e');
      
      // Yükleniyor diyaloğunu kapat (hata durumunda da)
      if (loadingContext != null && Navigator.canPop(loadingContext!)) {
        // ignore: use_build_context_synchronously
        Navigator.of(loadingContext!).pop();
        loadingContext = null;
      }
      
      // Küçük bir gecikme ekle
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Hata mesajını göster
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş iptal edilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _optionButton(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    final double iconSize = isTablet ? 20 : 18;
    final double textFontSize = isTablet ? 16 : 14;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 10.0 : 8.0, 
          horizontal: isTablet ? 20.0 : 16.0
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: iconSize),
            SizedBox(width: isTablet ? 12 : 10),
            Text(
              text,
              style: TextStyle(fontSize: textFontSize),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive tasarım için ekran boyutlarını al
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final bool isLargeTablet = screenSize.width > 900;
    
    // Responsive boyutlar
    final double tableNameFontSize = isLargeTablet ? 16 : isTablet ? 14 : 12;
    final double orderAmountFontSize = isLargeTablet ? 14 : isTablet ? 12 : 10;
    final double linkedTableFontSize = isLargeTablet ? 12 : isTablet ? 10 : 8;
    final double margin = isLargeTablet ? 10.0 : isTablet ? 8.0 : 6.0;
    final double padding = isLargeTablet ? 8.0 : isTablet ? 6.0 : 4.0;
    final double borderRadius = isLargeTablet ? 16.0 : isTablet ? 14.0 : 12.0;
    final double iconSize = isLargeTablet ? 20.0 : isTablet ? 18.0 : 16.0;
    final double peopleIconSize = isLargeTablet ? 16.0 : isTablet ? 14.0 : 12.0;
    
    final borderRadiusValue = BorderRadius.circular(borderRadius);
    final primaryColor = Color(AppConstants.primaryColorValue);
    
    // Bu masanın hangi ana masaya bağlı olduğunu kontrol et
    final TablesViewModel viewModel = Provider.of<TablesViewModel>(context, listen: false);
    final TableItem? mainTable = viewModel.getMainTableForMergedTable(table.tableID);
    final bool isLinkedToMainTable = mainTable != null;
    // Yan masa: başka bir ana masaya bağlı ancak kendisi ana masa olmayan masa
    final bool isSideTable = isLinkedToMainTable && !table.isMerged;
    
    return GestureDetector(
      onTap: () {
        // Masanın durumuna bakılmaksızın, her durumda CategoryView'a yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryView(
              tableName: table.tableName,
              compID: compID,
              userToken: userToken,
              tableID: table.tableID,
              // Masa aktifse orderID'yi geçir, değilse null gönder
              orderID: table.isActive ? table.orderID : null,
            ),
          ),
        ).then((_) async {
          // CategoryView'den geri döndükten sonra masa verilerini güncelle
          if (context.mounted) {
            final viewModel = Provider.of<TablesViewModel>(context, listen: false);
            await viewModel.refreshTablesDataSilently(
              userToken: userToken,
              compID: compID,
            );
          }
        });
      },

      //masa rengi aktif / pasif
      onLongPress: table.isActive ? () => _showTableOptions(context) : null,
      child: Container(
        margin: EdgeInsets.all(margin),
        decoration: BoxDecoration(
          color: table.isActive ? const Color.fromARGB(255, 97, 205, 101).withOpacity(0.9) : Colors.white,
          borderRadius: borderRadiusValue,
          border: Border.all(
            color: table.isActive 
                ? Colors.white.withOpacity(0.8)
                : Colors.grey.shade300,
            width: table.isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Ana içerik
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding + 2),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      table.tableName,
                      style: TextStyle(
                        fontSize: tableNameFontSize,
                        fontWeight: FontWeight.w600,
                        color: table.isActive ? Colors.white : Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (table.isActive && table.orderAmount.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: isTablet ? 4 : 2),
                        child: Text(
                          table.orderAmount,
                          style: TextStyle(
                            fontSize: orderAmountFontSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Yan masa ise bağlı olduğu ana masayı göster
                    if (isSideTable)
                      Padding(
                        padding: EdgeInsets.only(top: isTablet ? 2 : 1),
                        child: Text(
                          '→ ${mainTable.tableName}',
                          style: TextStyle(
                            fontSize: linkedTableFontSize,
                            color: table.isActive ? Colors.white70 : Colors.blue.shade700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Aktif masa için sağ üst köşede menü ikonu
            if (table.isActive)
              Positioned(
                top: isTablet ? -12 : -10,
                right: isTablet ? -12 : -10,
                child: IconButton(
                  icon: Icon(
                    Icons.more_vert, 
                    size: iconSize, 
                    color: Colors.white
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tight(Size(iconSize + 8, iconSize + 8)),
                  onPressed: () => _showTableOptions(context),
                  tooltip: 'Masa İşlemleri',
                ),
              ),
            // Ana masa etiketi (yalnızca ikon)
            if (table.isMerged)
              Positioned(
                top: isTablet ? 4 : 3,
                left: isTablet ? 4 : 3,
                child: Tooltip(
                  message: 'Ana masa - ${table.mergedTableIDs.length} masa birleştirildi',
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 3 : 2),
                    decoration: BoxDecoration(
                      color: table.isActive ? Colors.white : primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.people_alt, 
                      color: table.isActive ? primaryColor : Colors.white, 
                      size: peopleIconSize
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}