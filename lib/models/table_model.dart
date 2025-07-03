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
  final Map<int, String>? mergedTableNames;

  TableItem({
    required this.tableID,
    required this.orderID,
    required this.tableName,
    required this.orderAmount,
    required this.isActive,
    bool? isMerged,
    this.mergedTableIDs = const [],
    this.mergedTableNames,
  }) : isMerged = isMerged ?? mergedTableIDs.isNotEmpty;

  factory TableItem.fromJson(Map<String, dynamic> json) {
    List<int> mergedIds = [];
    Map<int, String> mergedNames = {};
    
    if (json['mergeTables'] != null) {
      List<dynamic> mergeTables = json['mergeTables'] as List<dynamic>;
      for (var item in mergeTables) {
        if (item is int) {
          mergedIds.add(item);
        } else if (item is String) {
          try {
            mergedIds.add(int.parse(item));
          } catch (e) {
            // Sayısal olmayan string değerleri atla
          }
        } else if (item is Map) {
          // Yeni JSON formatında tableID ve tableName kullanılıyor
          final id = item['mergeTableID'] ?? item['tableID'];
          final name = item['mergeTableName'] ?? item['tableName'];
          
          if (id != null) {
            try {
              final parsedId = int.parse(id.toString());
              mergedIds.add(parsedId);
              
              if (name != null && name is String && name.isNotEmpty) {
                mergedNames[parsedId] = name;
              }
            } catch (e) {
              // Dönüştürme hatası durumunda atla
            }
          }
        }
      }
    }
    
    bool? providedIsMerged = json['isMerged'] != null ? json['isMerged'] as bool : null;
    
    bool mergedStatus = providedIsMerged ?? mergedIds.isNotEmpty;
    
    return TableItem(
      tableID: json['tableID'] ?? 0,
      orderID: json['orderID'] ?? 0,
      tableName: json['tableName'] ?? '',
      orderAmount: json['orderAmount'] ?? '',
      isActive: json['isActive'] ?? false,
      isMerged: mergedStatus,
      mergedTableIDs: mergedIds,
      mergedTableNames: mergedNames.isNotEmpty ? mergedNames : null,
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
      if (mergedTableNames != null) 'mergedTableNames': mergedTableNames,
    };
  }
} 