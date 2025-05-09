import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pos701/models/api_response_model.dart';
import 'package:pos701/models/kitchen_order_model.dart';
import 'package:pos701/services/kitchen_service.dart';

enum KitchenViewState {
  initial,
  loading,
  loaded,
  error
}

class KitchenViewModel extends ChangeNotifier {
  final KitchenService _kitchenService;
  KitchenViewState _state = KitchenViewState.initial;
  List<KitchenOrder> _orders = [];
  String _errorMessage = '';
  Timer? _refreshTimer;
  
  // Sunucu saati
  int _serverTime = 0;
  DateTime? _serverDateTime;

  KitchenViewModel({required KitchenService kitchenService}) 
      : _kitchenService = kitchenService;

  // Getters
  KitchenViewState get state => _state;
  List<KitchenOrder> get orders => _orders;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == KitchenViewState.loading;
  int get serverTime => _serverTime;
  DateTime? get serverDateTime => _serverDateTime;

  // Sunucu saatini güncelle
  void updateServerTime(String serverTimeString, String serverDateString) {
    bool changed = false;
    if (serverTimeString.isNotEmpty) {
      try {
        final newServerTime = int.parse(serverTimeString);
        if (_serverTime != newServerTime) {
          _serverTime = newServerTime;
          // _serverTime (UTC timestamp) kullanarak _serverDateTime'ı (local DateTime) ayarla
          _serverDateTime = DateTime.fromMillisecondsSinceEpoch(_serverTime * 1000, isUtc: true).toLocal();
          changed = true;
          debugPrint('🔵 [Mutfak VM] Sunucu saati güncellendi: _serverTime=$_serverTime, _serverDateTime=$_serverDateTime (local)');
        }
      } catch (e) {
        if (_serverTime != 0 || _serverDateTime != null) {
          _serverTime = 0; // Hata durumunda fallback'i tetikle
          _serverDateTime = null;
          changed = true;
        }
        debugPrint('🔴 [Mutfak VM] Sunucu saati dönüştürme hatası: $e. Orijinal serverTimeString: $serverTimeString, serverDateString: $serverDateString');
      }
    } else {
      if (_serverTime != 0 || _serverDateTime != null) {
        _serverTime = 0; // serverTimeString boşsa fallback'i tetikle
        _serverDateTime = null;
        changed = true;
      }
      debugPrint('🟡 [Mutfak VM] serverTimeString boş, sunucu saati güvenilir bir şekilde güncellenemedi.');
    }

    if (changed) {
      notifyListeners();
    }
  }
  
  // Şu anki sunucu saatini hesapla (sürekli güncellenir)
  int getCurrentServerTime() {
    if (_serverTime > 0) {
      // İlk aldığımız sunucu saati ile şu anki zaman arasındaki farkı hesapla
      final timeElapsed = DateTime.now().difference(_serverDateTime ?? DateTime.now()).inSeconds;
      return _serverTime + timeElapsed;
    }
    return DateTime.now().millisecondsSinceEpoch ~/ 1000; // Fallback
  }
  
  // Bir ürünün sipariş edildiği zamandan bu yana geçen süre (saniye)
  int getElapsedTime(String productTime) {
    if (productTime.isEmpty) return 0;
    
    try {
      final int productTimeInt = int.parse(productTime);
      final int currentServerTime = getCurrentServerTime();
      return currentServerTime - productTimeInt;
    } catch (e) {
      debugPrint('🔴 [Mutfak VM] Geçen süre hesaplama hatası: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> getKitchenOrders(String userToken, int compID) async {
    _state = KitchenViewState.loading;
    notifyListeners();

    try {
      final request = KitchenOrdersRequest(userToken: userToken, compID: compID);
      
      final ApiResponseModel<KitchenOrdersResponse> response = 
          await _kitchenService.getKitchenOrders(request);
      
      if (response.success && !response.error && response.data != null) {
        _orders = response.data!.orders;
        _state = KitchenViewState.loaded;
      } else {
        _errorMessage = response.errorCode ?? 'Bilinmeyen bir hata oluştu';
        _state = KitchenViewState.error;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _state = KitchenViewState.error;
    }
    
    notifyListeners();
  }
  
  // Otomatik yenileme işlemini başlat
  void startAutoRefresh(String userToken, int compID, {Duration refreshInterval = const Duration(seconds: 30)}) {
    _refreshTimer?.cancel();
    
    // İlk veri çekimi
    getKitchenOrders(userToken, compID);
    
    // Periyodik yenileme
    _refreshTimer = Timer.periodic(refreshInterval, (_) {
      getKitchenOrders(userToken, compID);
    });
  }
  
  // Otomatik yenileme işlemini durdur
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
  
  /// Bir ürünün hazır olduğunu bildir
  Future<bool> markProductReady(String userToken, int compID, int orderID, int opID) async {
    try {
      debugPrint('🔵 [Mutfak VM] Ürün hazır bildirimi gönderiliyor: orderID=$orderID, opID=$opID');
      
      final response = await _kitchenService.markOrderReady(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        opID: opID,
        step: 'product',
      );
      
      if (response.success && !response.error) {
        debugPrint('🟢 [Mutfak VM] Ürün hazır bildirimi başarılı');
        // Sipariş listesini güncelle
        await getKitchenOrders(userToken, compID);
        return true;
      } else {
        debugPrint('🔴 [Mutfak VM] Ürün hazır bildirimi başarısız: ${response.errorCode}');
        _errorMessage = response.errorCode ?? 'Ürün hazır işaretlenemedi';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('🔴 [Mutfak VM] Ürün hazır bildirimi hatası: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Tüm siparişin hazır olduğunu bildir
  Future<bool> markOrderReady(String userToken, int compID, int orderID) async {
    try {
      debugPrint('🔵 [Mutfak VM] Sipariş hazır bildirimi gönderiliyor: orderID=$orderID');
      
      final response = await _kitchenService.markOrderReady(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        opID: 0,
        step: 'order',
      );
      
      if (response.success && !response.error) {
        debugPrint('🟢 [Mutfak VM] Sipariş hazır bildirimi başarılı');
        // Sipariş listesini güncelle
        await getKitchenOrders(userToken, compID);
        return true;
      } else {
        debugPrint('🔴 [Mutfak VM] Sipariş hazır bildirimi başarısız: ${response.errorCode}');
        _errorMessage = response.errorCode ?? 'Sipariş hazır işaretlenemedi';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('🔴 [Mutfak VM] Sipariş hazır bildirimi hatası: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
} 