import 'package:flutter/material.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/services/table_service.dart';

class TablesViewModel extends ChangeNotifier {
  final TableService _tableService = TableService();
  
  TablesResponse? _tablesResponse;
  bool _isLoading = false;
  String? _errorMessage;
  
  TablesResponse? get tablesResponse => _tablesResponse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  List<Region> get regions => _tablesResponse?.data.regions ?? [];
  
  Future<void> getTablesData({
    required String userToken,
    required int compID,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _tableService.getTables(
        userToken: userToken,
        compID: compID,
      );
      
      _tablesResponse = response;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // Belirli bir bölgenin masalarını döndürür
  List<TableItem> getTablesByRegion(int regionId) {
    final region = regions.firstWhere(
      (region) => region.regionID == regionId,
      orElse: () => Region(regionID: 0, regionName: '', totalOrder: 0, tables: []),
    );
    
    return region.tables;
  }
  
  // Tüm aktif masaları (siparişi olan) döndürür
  List<TableItem> get activeTables {
    final allTables = regions.expand((region) => region.tables).toList();
    return allTables.where((table) => table.isActive).toList();
  }
} 