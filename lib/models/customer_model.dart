import 'package:flutter/foundation.dart';

class CustomerAddress {
  final int adrID;
  final String adrTitle;
  final String adrAddress;
  final String adrNote;
  final bool isDefault;

  CustomerAddress({
    required this.adrID,
    required this.adrTitle,
    required this.adrAddress,
    required this.adrNote,
    required this.isDefault,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      adrID: json['adrID'] ?? 0,
      adrTitle: json['adrTitle'] ?? '',
      adrAddress: json['adrAddress'] ?? '',
      adrNote: json['adrNote'] ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adrID': adrID,
      'adrTitle': adrTitle,
      'adrAddress': adrAddress,
      'adrNote': adrNote,
      'isDefault': isDefault,
    };
  }
}

class Customer {
  final int custID;
  final String custCode;
  final String custName;
  final String custEmail;
  final String custPhone;
  final String custPhone2;
  final List<CustomerAddress> addresses;

  Customer({
    required this.custID,
    required this.custCode,
    required this.custName,
    required this.custEmail,
    required this.custPhone,
    required this.custPhone2,
    required this.addresses,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      custID: json['custID'] ?? 0,
      custCode: json['custCode'] ?? '',
      custName: json['custName'] ?? '',
      custEmail: json['custEmail'] ?? '',
      custPhone: json['custPhone'] ?? '',
      custPhone2: json['custPhone2'] ?? '',
      addresses: (json['addresses'] as List<dynamic>?)
              ?.map((address) => CustomerAddress.fromJson(address))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'custID': custID,
      'custCode': custCode,
      'custName': custName,
      'custEmail': custEmail,
      'custPhone': custPhone,
      'custPhone2': custPhone2,
      'addresses': addresses.map((address) => address.toJson()).toList(),
    };
  }
}

class CustomerListResponse {
  final List<Customer> customers;

  CustomerListResponse({
    required this.customers,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    return CustomerListResponse(
      customers: (json['customers'] as List<dynamic>?)
              ?.map((customer) => Customer.fromJson(customer))
              .toList() ??
          [],
    );
  }
} 