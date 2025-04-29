import 'package:flutter/material.dart';
import 'package:pos701/models/table_model.dart';
import 'package:pos701/services/table_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TablesViewModel extends ChangeNotifier {
  final TableService _tableService = TableService();
  
  TablesResponse? _tablesResponse;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _jsonErrorCount = 0; // JSON hataları için sayaç
  
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
  
  // Sadece masa aktifliğini yenileyen metod - sunucuyu yormamak için
  Future<bool> refreshTableActiveStatusOnly({
    required String userToken,
    required int compID,
  }) async {
    _errorMessage = null;
    _successMessage = null;
    
    try {
      // JSON dosyasından aktif sipariş bilgilerini al
      final response = await http.get(
        Uri.parse('https://appfiles.pos701.com/files/comp/comp_orders_${compID}.json'),
      );
      
      if (response.statusCode != 200) {
        debugPrint('Sipariş durumu alınamadı: ${response.statusCode}');
        return false; // Hata durumunda başarısız olarak dön
      }
      
      // Dönen veriyi işleyerek JSON formatını ayıkla
      String responseBody = response.body;
      debugPrint('Ham yanıt: $responseBody');
      
      try {
        // Özel format düzeltmesi
        if (responseBody.startsWith("order_counts_data='") && responseBody.endsWith("'")) {
          responseBody = responseBody.substring(18, responseBody.length - 1);
        }
        
        // Başında ve sonunda tek tırnak varsa temizle
        if (responseBody.startsWith("'") && responseBody.endsWith("'")) {
          responseBody = responseBody.substring(1, responseBody.length - 1);
        } else if (responseBody.startsWith("'")) {
          responseBody = responseBody.substring(1);
        } else if (responseBody.endsWith("'")) {
          responseBody = responseBody.substring(0, responseBody.length - 1);
        }
        
        // Güvenli JSON parse etme
        Map<String, dynamic> jsonData;
        try {
          jsonData = jsonDecode(responseBody);
        } catch (jsonDecodeError) {
          debugPrint('İlk JSON decode hatası: $jsonDecodeError, farklı bir format denenecek');
          
          // Tüm tırnak işaretlerini temizleyip tekrar dene
          String cleanedJson = responseBody.replaceAll("'", "");
          try {
            jsonData = jsonDecode(cleanedJson);
          } catch (secondError) {
            debugPrint('İkinci JSON decode denemesi de başarısız: $secondError');
            return false; // JSON parse edilemiyorsa başarısız olarak dön
          }
        }
        
        // Eğer henüz hiç masa verisi yoksa hata olarak dön
        if (_tablesResponse == null) {
          debugPrint('Masa verisi henüz yüklenmemiş');
          return false;
        }
        
        // "data" null kontrolü - Data null ise tüm masaları pasif olarak işaretle
        if (jsonData['data'] == null) {
          debugPrint('Sipariş verisi null - tüm masalar pasif olarak işaretlenecek');
          
          bool anyChanges = false;
          
          // Tüm bölgeleri ve masaları kontrol et
          for (var region in _tablesResponse!.data.regions) {
            for (var table in region.tables) {
              // Eğer hala aktif görünen masa varsa
              if (table.isActive) {
                anyChanges = true;
                break;
              }
            }
            if (anyChanges) break;
          }
          
          // Eğer hala aktif masa varsa, güncellemeliyiz
          if (anyChanges) {
            debugPrint('Aktif görünen masalar var ancak sipariş verisi null, tam veri güncellemesi gerekli');
            // Tam veri güncellemesi yap
            return await refreshTablesDataSilently(userToken: userToken, compID: compID);
          }
          
          debugPrint('Sipariş verisi null ve hiçbir masa aktif değil, durum tutarlı');
          return true;
        }
        
        final List<dynamic>? ordersData = jsonData['data'] as List<dynamic>?;
        
        // Eğer veri yoksa veya boşsa, tüm masaları pasif yap
        if (ordersData == null || ordersData.isEmpty) {
          debugPrint('Sipariş listesi boş - tüm masalar pasif olarak işaretlenecek');
          
          bool anyChanges = false;
          
          // Tüm bölgeleri ve masaları kontrol et
          for (var region in _tablesResponse!.data.regions) {
            for (var table in region.tables) {
              // Eğer hala aktif görünen masa varsa
              if (table.isActive) {
                anyChanges = true;
                break;
              }
            }
            if (anyChanges) break;
          }
          
          // Eğer hala aktif masa varsa, güncellemeliyiz
          if (anyChanges) {
            debugPrint('Aktif görünen masalar var ancak sipariş listesi boş, tam veri güncellemesi gerekli');
            // Tam veri güncellemesi yap
            return await refreshTablesDataSilently(userToken: userToken, compID: compID);
          }
          
          debugPrint('Sipariş listesi boş ve hiçbir masa aktif değil, durum tutarlı');
          return true;
        }
        
        // Aktif sipariş ID'lerini al
        final activeOrderIds = ordersData.map((order) => int.parse(order['order_id'].toString())).toSet();
        debugPrint('Aktif sipariş ID\'leri: $activeOrderIds');
        
        // Mevcut masa verilerini kontrol et
        bool anyChanges = false;
        
        for (var region in _tablesResponse!.data.regions) {
          for (var table in region.tables) {
            // Masa ID'si aktif sipariş listesinde var mı kontrol et
            bool shouldBeActive = activeOrderIds.contains(table.orderID) && table.orderID > 0;
            
            // Eğer aktiflik durumu farklıysa
            if (table.isActive != shouldBeActive) {
              debugPrint('Masa ${table.tableName} (ID: ${table.tableID}) - OrderID: ${table.orderID} - Mevcut durum: ${table.isActive}, Olması gereken: $shouldBeActive');
              anyChanges = true;
              break;
            }
          }
          if (anyChanges) break;
        }
        
        // Eğer değişiklik varsa, bunu sadece bildir ama tam veri güncellemesi yapma
        if (anyChanges) {
          debugPrint('Masa aktifliğinde değişiklik tespit edildi, tam veri yenileniyor...');
          // Tam veri güncellemesi yap
          return await refreshTablesDataSilently(userToken: userToken, compID: compID);
        }
        
        debugPrint('Masa aktifliği kontrol edildi, değişiklik yok');
        _jsonErrorCount = 0; // Başarılı işlem - hata sayacını sıfırla
        return true;
      } catch (jsonError) {
        debugPrint('JSON işleme hatası: $jsonError');
        _jsonErrorCount++;
        debugPrint('JSON hatası (sayı: $_jsonErrorCount) - tam veri güncellemesi yapılıyor...');
        return await refreshTablesDataSilently(userToken: userToken, compID: compID);
      }
    } catch (e) {
      debugPrint('Masa aktifliği kontrolü sırasında hata: $e');
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
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _tableService.partPay(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        opID: opID,
        opQty: opQty,
        payType: payType,
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        _successMessage = response['message'] ?? 'Parçalı ödeme başarıyla tamamlandı';
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error_message'] ?? 'Parçalı ödeme işlemi başarısız oldu';
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

  /// Sipariş iptal metodu
  Future<bool> cancelOrder({
    required String userToken,
    required int compID,
    required int orderID,
    String? cancelDesc,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    
    try {
      final response = await _tableService.cancelOrder(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        cancelDesc: cancelDesc,
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        _successMessage = response['message'] ?? 'Sipariş başarıyla iptal edildi';
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error_message'] ?? 'Sipariş iptal işlemi başarısız oldu';
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
} 