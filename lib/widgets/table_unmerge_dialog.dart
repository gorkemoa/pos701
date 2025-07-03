import 'package:flutter/material.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/constants/app_constants.dart';

class TableUnmergeDialog extends StatefulWidget {
  final TableItem mainTable;
  final List<TableItem> mergedTables;
  final Function(List<TableItem>) onTablesUnmerged;

  const TableUnmergeDialog({
    Key? key,
    required this.mainTable,
    required this.mergedTables,
    required this.onTablesUnmerged,
  }) : super(key: key);

  @override
  State<TableUnmergeDialog> createState() => _TableUnmergeDialogState();
}

class _TableUnmergeDialogState extends State<TableUnmergeDialog> {
  final List<TableItem> _selectedTables = [];
  final TextEditingController _searchController = TextEditingController();
  late List<TableItem> filteredTables;

  @override
  void initState() {
    super.initState();
    if (widget.mergedTables.length > 1) {
      filteredTables = List.from(widget.mergedTables);
    }
  }

  void _filterTables(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTables = List.from(widget.mergedTables);
      } else {
        filteredTables = widget.mergedTables
            .where((table) => 
                table.tableName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleTableSelection(TableItem table) {
    setState(() {
      if (_selectedTables.contains(table)) {
        _selectedTables.remove(table);
      } else {
        _selectedTables.add(table);
      }
    });
  }

  void _confirmUnmerge() {
    if (_selectedTables.length == widget.mergedTables.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm masalar ayrılamaz. En az bir masa birleşik kalmalı.')),
      );
      return;
    }

    // Doğru mantık: Seçilen masalar ayrılacak
    final List<TableItem> tablesToUnmerge = List<TableItem>.from(_selectedTables);

    if (tablesToUnmerge.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ayrılacak en az bir masa seçin.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: Colors.orange,
            ),
            const SizedBox(width: 10),
            const Text('Onay'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aşağıdaki masalar ${widget.mainTable.tableName} masasından ayrılacak:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            
            // Seçilen masaları (ayrılacak masaları) göster
            ...tablesToUnmerge.map((table) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.call_split,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      table.tableName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 10),
            const Text(
              'Not: Ayrılan masalar bağımsız hale gelir ve kendi siparişlerini alabilir.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Ana diyaloğu kapat
              
              widget.onTablesUnmerged(tablesToUnmerge);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(AppConstants.primaryColorValue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: const Text('Evet, Masaları Ayır'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(AppConstants.primaryColorValue);
    
    // Sadece bir masa birleşikse, basit onay diyaloğu göster
    if (widget.mergedTables.length == 1) {
      final tableToUnmerge = widget.mergedTables.first;
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_split_outlined, size: 48, color: primaryColor),
              const SizedBox(height: 16),
              const Text(
                'Masayı Ayır',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey[700], height: 1.5),
                  children: [
                    const TextSpan(text: 'Sadece bir masa birleşik. '),
                    TextSpan(
                      text: '\'${tableToUnmerge.tableName}\'',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const TextSpan(text: ' masasını '),
                    TextSpan(
                      text: '\'${widget.mainTable.tableName}\'',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const TextSpan(
                        text: ' masasından ayırmak istediğinize emin misiniz?'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      child: Text(
                        'İptal',
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Dialog'u kapat
                        widget.onTablesUnmerged([tableToUnmerge]);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.call_split),
                      label: const Text('Evet, Ayır',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Birden fazla masa birleşikse, normal listeyi göster
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.9),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.call_split,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Masaları Ayır',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.mainTable.tableName} ile birleştirilmiş masalardan ayrılacakları seçin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Masa Ara...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search),
                    fillColor: Colors.grey[100],
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                  onChanged: _filterTables,
                ),
              ),
              
              // Seçilen masa sayısı
              if (_selectedTables.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.call_split, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedTables.length} masa ayrılacak',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
              // Table List
              Expanded(
                child: filteredTables.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.table_bar_outlined,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Birleştirilmiş masa bulunamadı',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredTables.length,
                        itemBuilder: (context, index) {
                          final table = filteredTables[index];
                          final isSelected = _selectedTables.contains(table);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: 2,
                            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected 
                                  ? BorderSide(color: primaryColor, width: 2) 
                                  : BorderSide.none,
                            ),
                            child: InkWell(
                              onTap: () => _toggleTableSelection(table),
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 8,
                                ),
                                title: Text(
                                  table.tableName,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  isSelected 
                                      ? 'Bu masa ayrılacak'
                                      : 'Birleşik kalacak',
                                  style: TextStyle(
                                    color: isSelected ? primaryColor : Colors.grey[600],
                                  ),
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? primaryColor 
                                        : primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.table_bar_outlined,
                                    color: isSelected ? Colors.white : primaryColor,
                                    size: 28,
                                  ),
                                ),
                                trailing: isSelected 
                                    ? Icon(Icons.check_circle, color: primaryColor, size: 28) 
                                    : const Icon(Icons.link, color: Colors.grey, size: 28),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // Buttons
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tümünü Seç/Temizle
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_selectedTables.length == filteredTables.length) {
                            _selectedTables.clear();
                          } else {
                            _selectedTables.clear();
                            _selectedTables.addAll(filteredTables);
                          }
                        });
                      },
                      icon: Icon(
                        _selectedTables.length == filteredTables.length 
                            ? Icons.deselect 
                            : Icons.select_all,
                        color: primaryColor,
                      ),
                      label: Text(
                        _selectedTables.length == filteredTables.length 
                            ? 'Tümünü Temizle' 
                            : 'Tümünü Seç',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                    
                    // Ana butonlar
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('İptal', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selectedTables.isEmpty ? null : _confirmUnmerge,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.call_split),
                              SizedBox(width: 8),
                              Text('Ayır', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 