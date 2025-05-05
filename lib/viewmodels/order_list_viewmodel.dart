import 'package:flutter/material.dart';
import 'package:pos701/models/order_model.dart';
import 'package:pos701/services/order_service.dart';
import 'package:pos701/services/table_service.dart';

class OrderListViewModel extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  final TableService _tableService = TableService();
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  
  // Başarı ve hata mesajlarını temizleme
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
  
  Future<void> getOrderList({
    required String userToken,
    required int compID,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
      
      final orderModel = await _orderService.getOrderList(
        userToken: userToken,
        compID: compID,
      );
      
      _orders = orderModel.orders;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // Siparişleri durumlarına göre filtreleme
  List<Order> getFilteredOrders(String statusID) {
    if (statusID == 'all') {
      return _orders;
    } else {
      return _orders.where((order) => order.orderStatusID == statusID).toList();
    }
  }
  
  /// Paket ve Gel Al siparişlerinin tamamlanması için
  Future<bool> completeOrder({
    required String userToken,
    required int compID,
    required int orderID,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
      
      final response = await _orderService.completeOrder(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
      );
      
      _isLoading = false;
      
      if (response.success) {
        _successMessage = response.successMessage ?? 'Sipariş başarıyla tamamlandı';
        
        // Sipariş listesini güncelle
        await getOrderList(
          userToken: userToken,
          compID: compID,
        );
        
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.errorCode ?? 'İşlem sırasında bir hata oluştu';
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
  
  /// Sipariş iptal etme
  Future<bool> cancelOrder({
    required String userToken,
    required int compID,
    required int orderID,
    String? cancelDesc,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();
      
      final response = await _tableService.cancelOrder(
        userToken: userToken,
        compID: compID,
        orderID: orderID,
        cancelDesc: cancelDesc,
      );
      
      _isLoading = false;
      
      if (response['success']) {
        _successMessage = response['success_message'] ?? 'Sipariş başarıyla iptal edildi';
        
        // Sipariş listesini güncelle
        await getOrderList(
          userToken: userToken,
          compID: compID,
        );
        
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['error_message'] ?? 'İşlem sırasında bir hata oluştu';
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