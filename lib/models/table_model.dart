class TablesResponse {
  final bool error;
  final bool success;
  final TablesData data;
  final String? message;

  TablesResponse({
    required this.error,
    required this.success,
    required this.data,
    this.message,
  });

  factory TablesResponse.fromJson(Map<String, dynamic> json) {
    return TablesResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: TablesData.fromJson(json['data'] ?? {}),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'success': success,
      'data': data.toJson(),
      if (message != null) 'message': message,
    };
  }
}

class TablesData {
  final List<Region> regions;

  TablesData({required this.regions});

  factory TablesData.fromJson(Map<String, dynamic> json) {
    List<dynamic> regionsList = json['regions'] ?? [];
    return TablesData(
      regions: regionsList.map((region) => Region.fromJson(region)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'regions': regions.map((region) => region.toJson()).toList(),
    };
  }
}

class Region {
  final int regionID;
  final String regionName;
  final int totalOrder;
  final List<TableItem> tables;

  Region({
    required this.regionID,
    required this.regionName,
    required this.totalOrder,
    required this.tables,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    List<dynamic> tablesList = json['tables'] ?? [];
    return Region(
      regionID: json['regionID'] ?? 0,
      regionName: json['regionName'] ?? '',
      totalOrder: json['totalOrder'] ?? 0,
      tables: tablesList.map((table) => TableItem.fromJson(table)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'regionID': regionID,
      'regionName': regionName,
      'totalOrder': totalOrder,
      'tables': tables.map((table) => table.toJson()).toList(),
    };
  }
}

class TableItem {
  final int tableID;
  final int orderID;
  final String tableName;
  final String orderAmount;
  final bool isActive;
  final bool isMerged;
  final List<int> mergedTableIDs;

  TableItem({
    required this.tableID,
    required this.orderID,
    required this.tableName,
    required this.orderAmount,
    required this.isActive,
    this.isMerged = false,
    this.mergedTableIDs = const [],
  });

  factory TableItem.fromJson(Map<String, dynamic> json) {
    return TableItem(
      tableID: json['tableID'] ?? 0,
      orderID: json['orderID'] ?? 0,
      tableName: json['tableName'] ?? '',
      orderAmount: json['orderAmount'] ?? '',
      isActive: json['isActive'] ?? false,
      isMerged: json['isMerged'] ?? false,
      mergedTableIDs: json['mergedTableIDs'] != null 
          ? List<int>.from(json['mergedTableIDs'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tableID': tableID,
      'orderID': orderID,
      'tableName': tableName,
      'orderAmount': orderAmount,
      'isActive': isActive,
      'isMerged': isMerged,
      'mergedTableIDs': mergedTableIDs,
    };
  }
} 