import 'package:flutter/material.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/constants/app_constants.dart';
import 'package:pos701/viewmodels/tables_viewmodel.dart';
import 'package:pos701/widgets/table_selection_dialog.dart';
import 'package:provider/provider.dart';

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
    // BottomSheet açılmadan önce viewModel'i alıyoruz
    final viewModel = Provider.of<TablesViewModel>(context, listen: false);
    
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
                    Navigator.pop(bottomSheetContext);
                    // Context'i değiştirmeden önce viewModel'i aktarıyoruz
                    _handleTableChange(context, viewModel);
                  },
                ),
                const Divider(),
                _optionButton(
                  bottomSheetContext,
                  icon: Icons.merge_type,
                  iconColor: Colors.blue,
                  text: 'Masaları Birleştir',
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // Masaları birleştirme işlemi
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

  void _handleTableChange(BuildContext context, TablesViewModel viewModel) async {
    // artık viewModel parametre olarak geçirildiği için Provider.of kullanmıyoruz
    final inactiveTables = viewModel.inactiveTables;
    
    if (inactiveTables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktif olmayan masa bulunamadı')),
      );
      return;
    }

    // Boş (aktif olmayan) masa seçimi diyaloğunu göster
    showDialog(
      context: context,
      builder: (context) => TableSelectionDialog(
        inactiveTables: inactiveTables,
        onTableSelected: (selectedTable) async {
          // Yükleniyor diyaloğu göster
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
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
          Navigator.of(context).pop();
          
          if (success) {
            // Başarılı mesajını göster
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.errorMessage ?? 'Masa değiştirme işlemi başarısız oldu')),
            );
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
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: table.isActive ? () => _showTableOptions(context) : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: table.isActive 
                ? Color(AppConstants.primaryColorValue) 
                : Color(AppConstants.primaryColorValue),
            width: table.isActive ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        height: 100, // Sabit yükseklik
        child: Stack(
          fit: StackFit.expand,
          children: [
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
                            color: Color(AppConstants.primaryColorValue),
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
          ],
        ),
      ),
    );
  }
}