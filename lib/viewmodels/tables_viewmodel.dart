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
      
      // Debug: Ham yanıtı kaydet
      debugPrint('JSON Yanıt (Ham): $responseBody');
      
      try {
        // Özel format düzeltmesi
        if (responseBody.startsWith("order_counts_data='") && responseBody.endsWith("'")) {
          responseBody = responseBody.substring(18, responseBody.length - 1);
          debugPrint('JSON Yanıt (Temizlendi-1): $responseBody');
        }
        
        // Başında ve sonunda tek tırnak varsa temizle
        if (responseBody.startsWith("'") && responseBody.endsWith("'")) {
          responseBody = responseBody.substring(1, responseBody.length - 1);
          debugPrint('JSON Yanıt (Temizlendi-2): $responseBody');
        } else if (responseBody.startsWith("'")) {
          responseBody = responseBody.substring(1);
          debugPrint('JSON Yanıt (Temizlendi-3): $responseBody');
        } else if (responseBody.endsWith("'")) {
          responseBody = responseBody.substring(0, responseBody.length - 1);
          debugPrint('JSON Yanıt (Temizlendi-4): $responseBody');
        }
        
        // Güvenli JSON parse etme
        Map<String, dynamic> jsonData;
        try {
          jsonData = jsonDecode(responseBody);
          debugPrint('JSON Parse başarılı');
        } catch (jsonDecodeError) {
          debugPrint('İlk JSON decode hatası: $jsonDecodeError, farklı bir format denenecek');
          
          // Tüm tırnak işaretlerini temizleyip tekrar dene
          String cleanedJson = responseBody.replaceAll("'", "");
          try {
            jsonData = jsonDecode(cleanedJson);
            debugPrint('JSON Parse ikinci denemede başarılı');
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
        
        // Debug: Sipariş verilerini görüntüle
        debugPrint('Sipariş verileri: $ordersData');
        
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
        
        // Aktif sipariş tabloları ve birleştirilmiş masaları takip et
        final Map<int, List<int>> mergedTablesMap = {};
        
        // Birleştirilmiş masaları işle
        for (var order in ordersData) {
          int orderID = int.parse(order['order_id'].toString());
          int tableID = int.parse(order['table_id'].toString());
          
          // Debug: Her siparişin detaylarını göster
          
          // mergeTables alanını kontrol et (yeni API formatı)
          if (order['mergeTables'] != null) {
            List<dynamic> mergeTables = order['mergeTables'] as List<dynamic>;
            if (mergeTables.isNotEmpty) {
              List<int> mergedTableIds = [];
              for (var mergeTable in mergeTables) {
                if (mergeTable is int) {
                  mergedTableIds.add(mergeTable);
                } else if (mergeTable is String) {
                  try {
                    mergedTableIds.add(int.parse(mergeTable));
                  } catch (e) {
                    debugPrint('Geçersiz birleştirilmiş masa ID: $mergeTable');
                  }
                } else if (mergeTable is Map) {
                  // Eğer mergeTables içinde farklı bir obje yapısı varsa
                  if (mergeTable.containsKey('table_id')) {
                    try {
                      mergedTableIds.add(int.parse(mergeTable['table_id'].toString()));
                    } catch (e) {
                    }
                  }
                }
              }
              mergedTablesMap[tableID] = mergedTableIds;
              debugPrint('Masa $tableID için birleştirilmiş masalar: $mergedTableIds');
            }
          } else {
            debugPrint('Masa $tableID için mergeTables alanı bulunamadı veya boş');
          }
        }
        
        // Mevcut masa verilerini kontrol et
        bool anyChanges = false;
        
        for (var region in _tablesResponse!.data.regions) {
          for (int i = 0; i < region.tables.length; i++) {
            var table = region.tables[i];
            
            // Masa ID'si aktif sipariş listesinde var mı kontrol et
            bool shouldBeActive = activeOrderIds.contains(table.orderID) && table.orderID > 0;
            
            // Birleştirilmiş masa kontrolü
            bool shouldBeMerged = mergedTablesMap.containsKey(table.tableID) && 
                               mergedTablesMap[table.tableID]!.isNotEmpty;
            
            // Debug: Masa durumlarını göster
            debugPrint('Masa ${table.tableName} (ID: ${table.tableID}) durum kontrolü:');
            debugPrint('  - OrderID: ${table.orderID}');
            debugPrint('  - Mevcut aktiflik: ${table.isActive}, Olması gereken: $shouldBeActive');
            debugPrint('  - Mevcut birleşik: ${table.isMerged}, Olması gereken: $shouldBeMerged');
            
            // Eğer aktiflik veya birleştirilmiş durumu farklıysa, tüm veriyi yeniden çekmek yerine burada düzeltelim
            if (table.isActive != shouldBeActive || table.isMerged != shouldBeMerged) {
              debugPrint('Masa ${table.tableName} (ID: ${table.tableID}) - ' +
                       'Mevcut aktiflik: ${table.isActive}, Olması gereken: $shouldBeActive - ' +
                       'Mevcut birleştirilmiş: ${table.isMerged}, Olması gereken: $shouldBeMerged');
                       
              // Modeli doğrudan güncelle
              try {
                // Yeni bir TableItem oluşturarak güncelleme yapalım
                final updatedTable = TableItem(
                  tableID: table.tableID,
                  orderID: table.orderID,
                  tableName: table.tableName,
                  orderAmount: table.orderAmount,
                  isActive: shouldBeActive,
                  isMerged: shouldBeMerged,
                  mergedTableIDs: shouldBeMerged ? (mergedTablesMap[table.tableID] ?? []) : [],
                );
                
                // TablesResponse içindeki TableItem'ı güncelle
                // Bu derin bir kopyalama yaparak immutable objeleri günceller
                final updatedRegions = _tablesResponse!.data.regions.map((r) {
                  if (r.regionID == region.regionID) {
                    final updatedTables = List<TableItem>.from(r.tables);
                    updatedTables[i] = updatedTable;
                    
                    return Region(
                      regionID: r.regionID,
                      regionName: r.regionName,
                      totalOrder: r.totalOrder,
                      tables: updatedTables,
                    );
                  }
                  return r;
                }).toList();
                
                // TablesResponse'ı güncelle
                _tablesResponse = TablesResponse(
                  error: _tablesResponse!.error,
                  success: _tablesResponse!.success,
                  data: TablesData(regions: updatedRegions),
                  message: _tablesResponse!.message,
                );
                
                debugPrint('⚡ Masa ${table.tableName} verisi yerel olarak güncellendi: ' +
                         'Aktiflik: $shouldBeActive, Birleştirilmiş: $shouldBeMerged');
                
                // Değişiklik yapıldığını işaretle
                anyChanges = true;
              } catch (e) {
                debugPrint('❌ Masa ${table.tableName} güncelleme hatası: $e');
                // Hata durumunda tam veri güncelleme işaretini koy
                anyChanges = true;
                break;
              }
            }
          }
          if (anyChanges) break;
        }
        
        // Değişiklik varsa UI'ı güncelle
        if (anyChanges) {
          debugPrint('Masa durumları yerel olarak güncellendi, UI yenileniyor...');
          notifyListeners();
          return true;
        }
        
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
    String step = 'merged', // İsteğe bağlı, varsayılan değer 'merged'
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
        step: step, // Metoda gönderilen step değerini kullan
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        _successMessage = step == 'merged' 
            ? (response['success_message'] ?? 'Masalar başarıyla birleştirildi')
            : (response['success_message'] ?? 'Masalar başarıyla ayrıldı');
        
        // İşlem başarılı oldu, hemen masa verilerini güncelle
        debugPrint('👍 ${step == "merged" ? "Birleştirme" : "Ayırma"} işlemi başarılı, masa verilerini güncelleniyor...');
        
        // Eğer yanıtta veri varsa, onu kullanarak masaları güncelle
        if (response.containsKey('data') && response['data'] != null) {
          Map<String, dynamic> data = response['data'] as Map<String, dynamic>;
          
          // Eğer sipariş verisi döndüyse ve birleştirilen masalar bilgisi varsa
          if (data.containsKey('order') && data['order'] is Map) {
            Map<String, dynamic> order = data['order'] as Map<String, dynamic>;
            
            if (order.containsKey('mergeTables')) {
              var mergedTables = order['mergeTables'];
              debugPrint('📊 API yanıtından birleştirilmiş masalar: $mergedTables');
              
              // Birleştirilmiş masa ID'lerini liste olarak al
              List<int> mergedTableIds = [];
              if (mergedTables is List) {
                for (var item in mergedTables) {
                  if (item is int) {
                    mergedTableIds.add(item);
                  } else if (item is String) {
                    try {
                      mergedTableIds.add(int.parse(item));
                    } catch (e) {
                      // Geçersiz ID'leri atla
                    }
                  } else if (item is Map && item.containsKey('table_id')) {
                    try {
                      mergedTableIds.add(int.parse(item['table_id'].toString()));
                    } catch (e) {
                      // Geçersiz ID'leri atla
                    }
                  }
                }
              }
              
              debugPrint('📊 İşlenen birleştirilmiş masa ID\'leri: $mergedTableIds');
              
              // Ana masayı güncelle (birleştirme için)
              if (step == 'merged' && !mergedTableIds.isEmpty) {
                // Ana masayı bul ve güncelle
                _updateTableMergeStatus(mainTableID, true, mergedTableIds);
                
                // Birleştirilen masaları da güncelle
                for (var tableId in mergedTableIds) {
                  _updateTableMergeStatus(tableId, false, []);
                }
              } 
              // Ayırma işlemi için
              else if (step == 'unmerged') {
                // Ana masanın birleştirilmiş durumunu kaldır
                _updateTableMergeStatus(mainTableID, false, []);
                
                // Ayırma işleminde, eski birleştirilmiş masaların da durumunu güncelle
                for (var region in regions) {
                  for (var table in region.tables) {
                    if (table.mergedTableIDs.contains(mainTableID)) {
                      _updateTableMergeStatus(table.tableID, false, []);
                    }
                  }
                }
              }
            }
          }
        }
        
        // Her durumda tam veri güncellemesi yap - bu, olası tutarsızlıkları çözer
        await refreshTablesDataSilently(userToken: userToken, compID: compID);
        
        notifyListeners();
        return true;
      } else {
        _errorMessage = step == 'merged'
            ? (response['error_message'] ?? 'Masa birleştirme işlemi başarısız oldu')
            : (response['error_message'] ?? 'Masa ayırma işlemi başarısız oldu');
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
  
  // Yardımcı metod - Tabloda birleştirme durumunu günceller
  void _updateTableMergeStatus(int tableID, bool isMerged, List<int> mergedTableIDs) {
    debugPrint('💫 Masa ID:$tableID için birleştirme durumu güncelleniyor - isMerged:$isMerged, mergedTableIDs:$mergedTableIDs');
    
    // Bölgeleri ve masaları dolaş
    for (int regionIndex = 0; regionIndex < regions.length; regionIndex++) {
      final region = regions[regionIndex];
      for (int tableIndex = 0; tableIndex < region.tables.length; tableIndex++) {
        final table = region.tables[tableIndex];
        
        if (table.tableID == tableID) {
          // Tabloyu bulduk, şimdi güncellememiz gerekiyor
          // Immutable nesnelerle çalıştığımız için, güncellenmiş bölgeler listesi oluşturmamız gerekiyor
          final updatedRegions = List<Region>.from(regions);
          
          // Bu bölgedeki tabloları güncelle
          final updatedTables = List<TableItem>.from(region.tables);
          
          // Yeni TableItem oluştur (tüm özellikleri koru, sadece isMerged ve mergedTableIDs'yi güncelle)
          updatedTables[tableIndex] = TableItem(
            tableID: table.tableID,
            orderID: table.orderID,
            tableName: table.tableName,
            orderAmount: table.orderAmount,
            isActive: table.isActive,
            isMerged: isMerged,
            mergedTableIDs: mergedTableIDs,
          );
          
          // Güncellenmiş tablolar listesiyle yeni Region oluştur
          updatedRegions[regionIndex] = Region(
            regionID: region.regionID,
            regionName: region.regionName,
            totalOrder: region.totalOrder,
            tables: updatedTables,
          );
          
          // TablesResponse'ı güncelle
          if (_tablesResponse != null) {
            _tablesResponse = TablesResponse(
              error: _tablesResponse!.error,
              success: _tablesResponse!.success,
              data: TablesData(regions: updatedRegions),
              message: _tablesResponse!.message,
            );
          }
          
          debugPrint('✅ Masa ID:$tableID için birleştirme durumu güncellendi');
          return;
        }
      }
    }
    
    debugPrint('❌ Masa ID:$tableID bulunamadı, güncelleme yapılamadı');
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
      // Ayırma işlemi öncesinde, mevcut birleştirilmiş masaları kaydet
      List<int> currentMergedTables = [];
      
      // Bölgeleri ve masaları dolaş, ayırılacak masanın birleştirilmiş masalarını bul
      for (var region in regions) {
        for (var table in region.tables) {
          if (table.tableID == tableID && table.isMerged) {
            currentMergedTables = List<int>.from(table.mergedTableIDs);
            debugPrint('🔍 Ayırılacak masa ID:$tableID için mevcut birleştirilmiş masalar: $currentMergedTables');
            break;
          }
        }
      }
      
      debugPrint('⚙️ Masa ayırma API çağrısı yapılıyor - Masa ID: $tableID, Sipariş ID: $orderID');
      
      final response = await _tableService.mergeTables(
        userToken: userToken,
        compID: compID,
        tableID: tableID,
        orderID: orderID,
        mergeTables: [], // Ayırma işlemi için boş liste göndermek yeterli
        step: 'unmerged', // Ayırma işlemi için "unmerged" adımı kullanılıyor
      );
      
      _isLoading = false;
      
      if (response['success'] == true) {
        _successMessage = response['success_message'] ?? 'Masalar başarıyla ayrıldı';
        
        // Önce ayrılan masaların durumunu güncelle (API çağrısı başarılı oldu)
        debugPrint('👍 Masa ayırma işlemi başarılı, masa durumları güncelleniyor...');
        
        // Ana masayı güncelle - artık birleştirilmiş masa değil
        _updateTableMergeStatus(tableID, false, []);
        
        // Önceden birleştirilmiş olan tüm masaları güncelle
        for (var mergedTableID in currentMergedTables) {
          _updateTableMergeStatus(mergedTableID, false, []);
        }
        
        // Ek kontrol olarak veri güncellemesini de yap
        await refreshTablesDataSilently(userToken: userToken, compID: compID);
        
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