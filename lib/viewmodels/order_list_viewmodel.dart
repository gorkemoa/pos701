import 'package:flutter/material.dart';
import 'package:pos701/models/order_model.dart';
import 'package:pos701/services/order_service.dart';

class OrderListViewModel extends ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> getOrderList({
    required String userToken,
    required int compID,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
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
} 