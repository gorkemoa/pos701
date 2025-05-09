import 'package:flutter/material.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/widgets/table_selection_dialog.dart';
import 'package:pos701/widgets/table_merge_dialog.dart';
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
    Key? key,
    required this.table,
    required this.onTap,
    required this.userToken,
    required this.compID,
  }) : super(key: key);

  void _showTableOptions(BuildContext context) {
    final TablesViewModel viewModel = Provider.of<TablesViewModel>(context, listen: false);
    
    // Debug: Birleştirilmiş masa bilgisini konsola yazdir
    debugPrint('Masa bilgisi: ID=${table.tableID}, İsim=${table.tableName}');
    debugPrint('Birleştirilmiş mi: ${table.isMerged}');
    if (table.isMerged) {
      debugPrint('Birleştirilmiş masalar: ${table.mergedTableIDs}');
    }
    
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
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Masa & Sipariş İşlemleri',
                    style: TextStyle(
                      fontSize: 17,
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
                    Future.microtask(() {
                      _handleCancelOrder(context, viewModel);
                    });
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
                if (table.isMerged)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
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
                    ),
                  )
                else
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
                  icon: const Icon(Icons.arrow_back, color: Colors.blue, size: 20),
                  label: const Text('Vazgeç', style: TextStyle(color: Colors.blue, fontSize: 15)),
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
    
    // Kullanıcının ödeme tiplerini kontrol et
    if (userViewModel.userInfo == null || userViewModel.userInfo!.company == null || 
        userViewModel.userInfo!.company!.compPayTypes.isEmpty) {
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
      builder: (ctx) {
        loadingContext = ctx;
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Ödeme işlemi gerçekleştiriliyor...', style: TextStyle(fontSize: 15)),
            ],
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
    // Ayırma işleminden önce onay al
    final confirmUnmerge = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text('Masaları Ayır', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: Text(
          'Bu işlem ${table.tableName} masasını ve bağlı masaları ayıracaktır. Devam etmek istiyor musunuz?',
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Evet, Ayır', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );

    if (confirmUnmerge != true) return;

    // Yükleniyor diyaloğunu göster
    if (!context.mounted) return;
    
    BuildContext? loadingContext;
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loadingContext = ctx;
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Masalar ayrılıyor...', style: TextStyle(fontSize: 15)),
            ],
          ),
        );
      },
    );

    try {
      // Masa ayırma API çağrısı - unMergeTables fonksiyonunu kullan
      final success = await viewModel.unMergeTables(
        userToken: userToken,
        compID: compID,
        tableID: table.tableID,
        orderID: table.orderID,
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
            content: Text(viewModel.successMessage ?? 'Masalar başarıyla ayrıldı'),
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
          
          // Yükleniyor diyaloğu göster
          if (!context.mounted) return;
          
          BuildContext? loadingContext;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              loadingContext = ctx;
              return const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Masa değiştiriliyor...', style: TextStyle(fontSize: 15)),
                  ],
                ),
              );
            },
          );

          try {
            // Masa değiştirme API çağrısı
            final success = await viewModel.changeTable(
              userToken: userToken,
              compID: compID,
              orderID: table.orderID,
              tableID: selectedTable.tableID,
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
                SnackBar(content: Text(viewModel.successMessage ?? 'Masa başarıyla değiştirildi')),
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
                  content: Text(viewModel.errorMessage ?? 'Masa değiştirme işlemi başarısız oldu'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            debugPrint('Masa değiştirme hatası: $e');
            
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
                                child: const Text('İptal', style: TextStyle(color: Colors.white, fontSize: 15)),
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
                          builder: (ctx) {
                            loadingContext = ctx;
                            return const AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 12),
                                  Text('Adisyon aktarılıyor...', style: TextStyle(fontSize: 15)),
                                ],
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
            builder: (ctx) {
              loadingContext = ctx;
              return const AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Masalar birleştiriliyor...', style: TextStyle(fontSize: 15)),
                  ],
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
      builder: (ctx) {
        loadingContext = ctx;
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Sipariş iptal ediliyor...', style: TextStyle(fontSize: 15)),
            ],
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
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
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
            await viewModel.refreshTablesDataSilently(
              userToken: userToken,
              compID: compID,
            );
          }
        });
      },
      onLongPress: table.isActive ? () => _showTableOptions(context) : null,
      child: Container(
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: table.isActive 
                ? primaryColor.withOpacity(0.8)
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
              padding: const EdgeInsets.all(10.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      table.tableName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: table.isActive ? Colors.black87 : Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (table.isActive && table.orderAmount.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '₺${table.orderAmount}',
                          style: TextStyle(
                            fontSize: 12,
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
                top: 1,
                right: 1,
                child: IconButton(
                  icon: Icon(Icons.more_vert, size: 16, color: Colors.grey.shade600),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tight(const Size(24, 24)),
                  onPressed: () => _showTableOptions(context),
                  tooltip: 'Masa İşlemleri',
                ),
              ),
            
            // Birleştirilmiş masa için arka plan overlay kaldırıldı, yerine ikon kullanılacak
            // if (table.isMerged)
            //   Positioned.fill(
            //     child: IgnorePointer(
            //       ignoring: true,
            //       child: Container(
            //         decoration: BoxDecoration(
            //           color: primaryColor.withOpacity(0.10),
            //           borderRadius: borderRadius,
            //         ),
            //       ),
            //     ),
            //   ),
            
            // Birleştirilmiş masa ikonu - sol üstte daha küçük
            if (table.isMerged)
              Positioned(
                top: 3,
                left: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.people_alt,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}