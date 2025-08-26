class ProductResponse {
  final bool error;
  final bool success;
  final ProductData? data;

  ProductResponse({
    required this.error,
    required this.success,
    this.data,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: json['data'] != null ? ProductData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'success': success,
      'data': data?.toJson(),
    };
  }
}

class ProductData {
  final List<Product> products;

  ProductData({
    required this.products,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      products: (json['products'] as List<dynamic>?)
          ?.map((product) => Product.fromJson(product))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((product) => product.toJson()).toList(),
    };
  }
}

class Product {
  final int postID;
  final int proID;
  final int catID;
  final String proName;
  final String proUnit;
  final String proStock;
  final String proPrice;
  final String proNote;


  Product({
    required this.postID,
    required this.proID,
    this.catID = 0,
    required this.proName,
    required this.proUnit,
    required this.proStock,
    required this.proPrice,
    this.proNote = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      postID: json['postID'] ?? 0,
      proID: json['proID'] ?? 0,
      catID: json['catID'] ?? 0,
      proName: json['proName'] ?? '',
      proUnit: json['proUnit'] ?? '',
      proStock: json['proStock'] ?? '0',
      proPrice: json['proPrice'] ?? '',
      proNote: json['proNote'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postID': postID,
      'proID': proID,
      'catID': catID,
      'proName': proName,
      'proUnit': proUnit,
      'proStock': proStock,
      'proPrice': proPrice,
      'proNote': proNote,
    };
  }

  @override
  String toString() {
    return 'Product(postID: $postID, proID: $proID, catID: $catID, proName: $proName, proUnit: $proUnit, proStock: $proStock, proPrice: $proPrice, proNote: $proNote)';
  }
} 