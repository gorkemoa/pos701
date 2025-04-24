import 'package:flutter/material.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/services/table_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pos701/constants/app_constants.dart';

class TablesViewModel extends ChangeNotifier {
  final TableService _tableService = TableService();
  
  TablesResponse? _tablesResponse;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  TablesResponse? get tablesResponse => _tablesResponse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  
  List<Region> get regions => _tablesResponse?.data.regions ?? [];
  
  Future<void> getTablesData({
    required String userToken,
    required int compID,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
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
  
  // Arka planda veri güncellemesi - Ana ekranı bloke etmeden
  Future<bool> refreshTablesDataSilently({
    required String userToken,
    required int compID,
  }) async {
    // Loading durumunu değiştirmiyoruz ve notifyListeners çağırmıyoruz
    // bu sayede kullanıcı arayüzünde kesinti olmayacak
    _errorMessage = null;
    _successMessage = null;
    
    try {
      final response = await _tableService.getTables(
        userToken: userToken,
        compID: compID,
      );
      
      // Yeni yanıtı ayarla ve güncelleme olduğunu bildir
      _tablesResponse = response;
      notifyListeners();
      return true;
    } catch (e) {
      // Hata durumunda eski verileri koru
      debugPrint('Arka plan veri yenileme hatası: $e');
      return false;
    }
  }
  
  Future<bool> changeTable({
    required String userToken,
    required int compID,
    required int orderID,
    required int tableID,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _tableService.changeTable(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        tableID: tableID,
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        _successMessage = response['success_message'] ?? 'Masa başarıyla değiştirildi';
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error_message'] ?? 'Masa değiştirme işlemi başarısız oldu';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> mergeTables({
    required String userToken,
    required int compID,
    required int mainTableID,
    required int orderID,
    required List<int> tablesToMerge,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _tableService.mergeTables(
        userToken: userToken,
        compID: compID,
        tableID: mainTableID,
        orderID: orderID,
        mergeTables: tablesToMerge,
        step: 'merged',
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        _successMessage = response['success_message'] ?? 'Masalar başarıyla birleştirildi';
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error_message'] ?? 'Masa birleştirme işlemi başarısız oldu';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  

  Future<bool> transferOrder({
    required String userToken,
    required int compID,
    required int oldOrderID,
    required int newOrderID,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _tableService.transferOrder(
        userToken: userToken,
        compID: compID,
        oldOrderID: oldOrderID,
        newOrderID: newOrderID,
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        _successMessage = response['success_message'] ?? 'Adisyon başarıyla aktarıldı';
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error_message'] ?? 'Adisyon aktarma işlemi başarısız oldu';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Masa ayırma (unmerge) işlemi
  Future<bool> unMergeTables({
    required String userToken,
    required int compID,
    required int tableID,
    required int orderID,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _tableService.mergeTables(
        userToken: userToken,
        compID: compID,
        tableID: tableID,
        orderID: orderID,
        mergeTables: [], // Boş liste göndermek yeterli
        step: 'unmerged', // Ayırma işlemi
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        _successMessage = response['success_message'] ?? 'Masalar başarıyla ayrıldı';
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error_message'] ?? 'Masa ayırma işlemi başarısız oldu';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
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
  
  // Tüm pasif masaları (siparişi olmayan) döndürür
  List<TableItem> get inactiveTables {
    final allTables = regions.expand((region) => region.tables).toList();
    return allTables.where((table) => !table.isActive).toList();
  }

  // Seçilen masa dışındaki tüm aktif ve pasif masaları döndürür
  List<TableItem> getAvailableTablesForMerge(int excludeTableID) {
    final allTables = regions.expand((region) => region.tables).toList();
    // Sadece pasif masaları listele (aktif masalar birleştirilemez)
    return allTables.where((table) => 
      table.tableID != excludeTableID && !table.isActive
    ).toList();
  }
  
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> fastPay({
    required String userToken,
    required int compID,
    required int orderID,
    required int isDiscount,
    required int discountType,
    required int discount,
    required int payType,
    required String payAction,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _tableService.fastPay(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        isDiscount: isDiscount,
        discountType: discountType,
        discount: discount,
        payType: payType,
        payAction: payAction,
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        _successMessage = response['success_message'] ?? 'Ödeme işlemi başarıyla tamamlandı';
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error_message'] ?? 'Ödeme işlemi başarısız oldu';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Parçalı ödeme alma metodu
  Future<bool> partPay({
    required String userToken,
    required int compID,
    required int orderID,
    required int opID,
    required int opQty,
    required int payType,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final url = "${AppConstants.baseUrl}/service/user/order/payment/partPay";
      
      final requestBody = {
        "userToken": userToken,
        "compID": compID,
        "orderID": orderID,
        "opID": opID,
        "opQty": opQty,
        "payType": payType
      };
      
      debugPrint('📤 Parçalı ödeme gönderiliyor: $requestBody');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('📥 Parçalı ödeme yanıtı alındı: ${response.statusCode}');
      
      if (response.statusCode == 410) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['error'] == false) {
          debugPrint('✅ Parçalı ödeme başarılı: ${responseData['data']}');
          _errorMessage = null;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          debugPrint('⛔️ Parçalı ödeme hatası: ${responseData['message']}');
          _errorMessage = responseData['message'] ?? 'Parçalı ödeme alınamadı.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        debugPrint('🔴 Parçalı ödeme API hatası: ${response.statusCode}');
        _errorMessage = 'Sunucu hatası: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('🔴 Parçalı ödeme exception: $e');
      _errorMessage = 'Ödeme işlemi sırasında hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
} 