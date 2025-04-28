import 'package:flutter/foundation.dart';
import 'package:pos701/models/customer_model.dart';
import 'package:pos701/services/customer_service.dart';

enum CustomerStatus {
  idle,
  loading,
  success,
  error,
}

class CustomerViewModel extends ChangeNotifier {
  final CustomerService _customerService;
  CustomerStatus _status = CustomerStatus.idle;
  String? _errorMessage;
  List<Customer> _customers = [];
  Customer? _selectedCustomer;

  CustomerViewModel({CustomerService? customerService}) 
      : _customerService = customerService ?? CustomerService();
  
  CustomerStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get hasCustomers => _customers.isNotEmpty;
  bool get isLoading => _status == CustomerStatus.loading;

  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearSelectedCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }
  
  void _setStatus(CustomerStatus status) {
    _status = status;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    _setStatus(CustomerStatus.error);
  }
  
  void resetState() {
    _status = CustomerStatus.idle;
    _errorMessage = null;
    _customers = [];
    _selectedCustomer = null;
    notifyListeners();
  }
  
  /// Müşteri listesini getirir
  Future<bool> getCustomers({
    required String userToken,
    required int compID,
    String searchText = '',
  }) async {
    _setStatus(CustomerStatus.loading);
    _errorMessage = null;
    
    try {
      final response = await _customerService.getCustomers(
        userToken: userToken,
        compID: compID,
        searchText: searchText,
      );
      
      if (response.success && !response.error) {
        _customers = response.data?.customers ?? [];
        _setStatus(CustomerStatus.success);
        return true;
      } else {
        _setError(response.errorCode ?? 'Müşteri bilgileri alınamadı');
        return false;
      }
    } catch (e) {
      _setError('Müşteri bilgileri alınırken hata oluştu: $e');
      return false;
    }
  }
} 