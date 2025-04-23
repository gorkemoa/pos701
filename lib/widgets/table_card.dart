import 'package:flutter/material.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/widgets/table_selection_dialog.dart';
import 'package:pos701/widgets/table_merge_dialog.dart';
import 'package:provider/provider.dart';
import 'package:pos701/views/category_view.dart';

class TableCard extends StatelessWidget {
  final TableItem table;
  final VoidCallback onTap;
  final String userToken;
  final int compID;

  const TableCard({
    Key? key,
    required this.table,
    required this.onTap,
    required this.userToken,
    required this.compID,
  }) : super(key: key);

  void _showTableOptions(BuildContext context) {
    final TablesViewModel viewModel = Provider.of<TablesViewModel>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Masa & Sipariş İşlemleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                _optionButton(
                  bottomSheetContext,
                  icon: Icons.payment,
                  iconColor: Colors.red,
                  text: 'Hızlı Öde (${table.orderAmount} ₺)',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // Hızlı ödeme işlemi
                    Future.microtask(() {
                      _handleFastPay(context, viewModel);
                    });
                  },
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
                  },
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
                ),
                const Divider(),
                // Masa birleştirilmiş ise "Masaları Ayır" düğmesi, değilse "Masaları Birleştir" düğmesi göster
                table.isMerged 
                ? _optionButton(
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
                )
                : _optionButton(
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
                ),
                const Divider(),
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
                ),
                const Divider(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(bottomSheetContext);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.blue),
                  label: const Text('Vazgeç', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleFastPay(BuildContext context, TablesViewModel viewModel) async {
    // Onay diyaloğu göster
    final confirmPay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.red),
            SizedBox(width: 10),
            Text('Hızlı Ödeme'),
          ],
        ),
        content: Text(
          '${table.tableName} masasının ${table.orderAmount} ₺ tutarındaki hesabı hızlı ödeme ile kapatılacaktır. Onaylıyor musunuz?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
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
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (confirmPay != true) return;

    // Yükleniyor diyaloğu göster
    if (!context.mounted) return;
    
    late BuildContext loadingContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        loadingContext = context;
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Ödeme işlemi gerçekleştiriliyor...'),
            ],
          ),
        );
      },
    );

    // Hızlı ödeme API çağrısı
    final success = await viewModel.fastPay(
      userToken: userToken,
      compID: compID,
      orderID: table.orderID,
      isDiscount: 0,
      discountType: 0,
      discount: 0,
      payType: 2,
      payAction: "payClose",
    );
    
    // Yükleniyor diyaloğunu kapat
    if (context.mounted) {
      try {
        Navigator.of(loadingContext).pop();
      } catch (e) {
        debugPrint('Diyalog kapatma hatası: $e');
      }
    }
    
    if (success) {
      // Başarılı mesajını göster
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.successMessage ?? 'Ödeme başarıyla tamamlandı'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Tabloları yenile
      await viewModel.getTablesData(
        userToken: userToken,
        compID: compID,
      );
    } else {
      // Hata mesajını göster
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Ödeme işlemi başarısız oldu'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleTableUnmerge(BuildContext context, TablesViewModel viewModel) async {
    // Ayırma işleminden önce onay al
    final confirmUnmerge = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text('Masaları Ayır'),
          ],
        ),
        content: Text(
          'Bu işlem ${table.tableName} masasını ve bağlı masaları ayıracaktır. Devam etmek istiyor musunuz?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Ayır'),
          ),
        ],
      ),
    );

    if (confirmUnmerge != true) return;

    // Yükleniyor diyaloğu göster
    if (!context.mounted) return;
    
    late BuildContext loadingContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        loadingContext = context;
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Masalar ayrılıyor...'),
            ],
          ),
        );
      },
    );

    
    
    // Yükleniyor diyaloğunu kapat
    if (context.mounted) {
      try {
        Navigator.of(loadingContext).pop();
      } catch (e) {
        debugPrint('Diyalog kapatma hatası: $e');
      }
    }
    

      
      // Tabloları yenile
      await viewModel.getTablesData(
        userToken: userToken,
        compID: compID,
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
          // Yükleniyor diyaloğu göster
          if (!dialogContext.mounted) return;
          
          late BuildContext loadingContext;
          showDialog(
            context: dialogContext,
            barrierDismissible: false,
            builder: (context) {
              loadingContext = context;
              return const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Masa değiştiriliyor...'),
                  ],
                ),
              );
            },
          );

          // Masa değiştirme API çağrısı
          final success = await viewModel.changeTable(
            userToken: userToken,
            compID: compID,
            orderID: table.orderID,
            tableID: selectedTable.tableID,
          );
          
          // Yükleniyor diyaloğunu kapat
          if (dialogContext.mounted) {
            try {
              Navigator.of(loadingContext).pop();
            } catch (e) {
              debugPrint('Diyalog kapatma hatası: $e');
            }
          }
          
          if (success) {
            // Başarılı mesajını göster
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.successMessage ?? 'Masa başarıyla değiştirildi')),
            );
            
            // Tabloları yenile
            await viewModel.getTablesData(
              userToken: userToken,
              compID: compID,
            );
          } else {
            // Hata mesajını göster
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.errorMessage ?? 'Masa değiştirme işlemi başarısız oldu')),
            );
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
            Icon(Icons.receipt, color: Colors.blue),
            SizedBox(width: 10),
            Text('Adisyon Aktarım'),
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
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activeTables.length,
                  itemBuilder: (context, index) {
                    final targetTable = activeTables[index];
                    return ListTile(
                      title: Text(targetTable.tableName),
                      subtitle: Text('Sipariş: ${targetTable.orderAmount} ₺'),
                      onTap: () async {
                        // Onay dialogu göster
                        final confirmTransfer = await showDialog<bool>(
                          context: dialogContext,
                          builder: (confirmContext) => AlertDialog(
                            title: const Text('Onay'),
                            content: Text(
                              '${table.tableName} masasının adisyonu ${targetTable.tableName} masasına aktarılacak. Onaylıyor musunuz?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(confirmContext).pop(false),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(confirmContext).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text('Onayla'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmTransfer != true) return;
                        
                        // İlk diyaloğu kapat
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                        
                        // Yükleme dialogu göster
                        if (!context.mounted) return;
                        
                        late BuildContext loadingContext;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            loadingContext = context;
                            return const AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Adisyon aktarılıyor...'),
                                ],
                              ),
                            );
                          },
                        );
                        
                        // Adisyon aktarma işlemini gerçekleştir
                        final success = await viewModel.transferOrder(
                          userToken: userToken,
                          compID: compID,
                          oldOrderID: table.orderID,
                          newOrderID: targetTable.orderID,
                        );
                        
                        // Yükleme dialogunu kapat
                        if (context.mounted) {
                          try {
                            Navigator.of(loadingContext).pop();
                          } catch (e) {
                            debugPrint('Diyalog kapatma hatası: $e');
                          }
                        }
                        
                        // Sonucu göster
                        if (!context.mounted) return;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                ? (viewModel.successMessage ?? 'Adisyon başarıyla aktarıldı')
                                : (viewModel.errorMessage ?? 'Adisyon aktarma işlemi başarısız oldu')
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        
                        if (success) {
                          // Tabloları yenile
                          await viewModel.getTablesData(
                            userToken: userToken,
                            compID: compID,
                          );
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
            child: const Text('İptal'),
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

    // Birleştirilecek masaların seçimi diyaloğunu göster
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => TableMergeDialog(
        mainTable: table,
        availableTables: availableTables,
        onTablesMerged: (selectedTables) async {
          // Seçilen masa ID'lerini al
          final selectedTableIds = selectedTables.map((t) => t.tableID).toList();
          
          // Yükleniyor diyaloğu göster
          if (!dialogContext.mounted) return;
          
          // Yükleniyor diyaloğunu göster
          late BuildContext loadingContext;
          showDialog(
            context: dialogContext,
            barrierDismissible: false,
            builder: (context) {
              loadingContext = context;
              return const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Masalar birleştiriliyor...'),
                  ],
                ),
              );
            },
          );

          // Masa birleştirme API çağrısı
          final success = await viewModel.mergeTables(
            userToken: userToken,
            compID: compID,
            mainTableID: table.tableID,
            orderID: table.orderID,
            tablesToMerge: selectedTableIds,
          );
          
          try {
            // Yükleniyor diyaloğunu kapat
            if (dialogContext.mounted) {
              Navigator.of(loadingContext).pop();
            }
          } catch (e) {
            debugPrint('Diyalog kapatma hatası: $e');
          }
          
          if (success) {
            // Başarılı mesajını göster
            if (context.mounted) {
              // Başarılı bir birleştirme için özel bir diyalog göster
              showDialog(
                context: context,
                builder: (successContext) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(AppConstants.primaryColorValue),
                      ),
                      const SizedBox(width: 10),
                      const Text('İşlem Başarılı'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${table.tableName} masası başarıyla birleştirildi.'),
                      const SizedBox(height: 16),
                      const Text(
                        'Birleştirilen masalar sol üst köşedeki insan simgesiyle işaretlenmiştir.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(successContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(AppConstants.primaryColorValue),
                      ),
                      child: const Text('Tamam'),
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
            
            // Tabloları yenile
            await viewModel.getTablesData(
              userToken: userToken,
              compID: compID,
            );
          } else {
            // Hata mesajını göster
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.errorMessage ?? 'Masa birleştirme işlemi başarısız oldu'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _optionButton(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    final primaryColor = Color(AppConstants.primaryColorValue);
    
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
            await viewModel.getTablesData(
              userToken: userToken,
              compID: compID,
            );
          }
        });
      },
      onLongPress: table.isActive ? () => _showTableOptions(context) : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: table.isActive 
                ? primaryColor 
                : primaryColor,
            width: table.isActive ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        height: 100, // Sabit yükseklik
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ana içerik
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      table.tableName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (table.isActive && table.orderAmount.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '₺${table.orderAmount}',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
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
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tight(const Size(32, 32)),
                  onPressed: () => _showTableOptions(context),
                ),
              ),
              
            // Birleştirilmiş masa için arka plan overlay
            if (table.isMerged)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              ),
            
            // Birleştirilmiş masa ikonu - daha belirgin ve ortada
            if (table.isMerged)
              Positioned(
                top: 3,
                left: 3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.people_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Birleşik',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}