class ProductDetailResponse {
  final bool error;
  final bool success;
  final ProductDetail? data;

  ProductDetailResponse({
    required this.error,
    required this.success,
    this.data,
  });

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProductDetailResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: json['data'] != null ? ProductDetail.fromJson(json['data']) : null,
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

class ProductDetail {
  final int postID;
  final String postTitle;
  final List<ProductVariant> variants;

  ProductDetail({
    required this.postID,
    required this.postTitle,
    required this.variants,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      postID: json['postID'] ?? 0,
      postTitle: json['postTitle'] ?? '',
      variants: (json['variants'] as List<dynamic>?)
          ?.map((variant) => ProductVariant.fromJson(variant))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postID': postID,
      'postTitle': postTitle,
      'variants': variants.map((variant) => variant.toJson()).toList(),
    };
  }
}

class ProductVariant {
  final int proID;
  final String proUnit;
  final double proPrice;
  final int proStock;
  final bool isDefault;

  ProductVariant({
    required this.proID,
    required this.proUnit,
    required this.proPrice,
    required this.proStock,
    required this.isDefault,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      proID: json['proID'] ?? 0,
      proUnit: json['proUnit'] ?? '',
      proPrice: (json['proPrice'] is int) 
          ? (json['proPrice'] as int).toDouble() 
          : json['proPrice'] ?? 0.0,
      proStock: json['proStock'] ?? 0,
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proID': proID,
      'proUnit': proUnit,
      'proPrice': proPrice,
      'proStock': proStock,
      'isDefault': isDefault,
    };
  }
} 