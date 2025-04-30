import 'package:flutter/foundation.dart';
import 'package:pos701/models/customer_model.dart';
import 'package:pos701/services/customer_service.dart';
import 'package:pos701/models/order_model.dart' as order_model;

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

  /// Yeni müşteri ekler
  Future<bool> addCustomer({
    required String userToken,
    required int compID,
    required String custName,
    required String custPhone,
    List<order_model.CustomerAddress>? addresses,
  }) async {
    _setStatus(CustomerStatus.loading);
    _errorMessage = null;
    
    try {
      // Adres bilgilerini API'nin beklediği formata dönüştür
      final List<Map<String, dynamic>> addressMaps = [];
      if (addresses != null && addresses.isNotEmpty) {
        for (var address in addresses) {
          addressMaps.add({
            'adrTitle': address.adrTitle,
            'adrAdress': address.adrAdress,
            'adrNote': address.adrNote,
            'isDefault': address.isDefault ? 1 : 0,
          });
        }
      }
      
      final response = await _customerService.addCustomer(
        userToken: userToken,
        compID: compID,
        custName: custName,
        custPhone: custPhone,
        custAdrs: addressMaps,
      );
      
      if (response.success && !response.error) {
        if (response.data != null) {
          // Eklenen müşterinin bilgilerini seçili müşteri olarak ayarla
          _selectedCustomer = response.data;
          // Müşteri listesinin başına yeni müşteriyi ekle
          _customers.insert(0, response.data!);
        }
        _setStatus(CustomerStatus.success);
        return true;
      } else {
        _setError(response.errorCode ?? 'Müşteri eklenemedi');
        return false;
      }
    } catch (e) {
      _setError('Müşteri eklenirken hata oluştu: $e');
      return false;
    }
  }
} 