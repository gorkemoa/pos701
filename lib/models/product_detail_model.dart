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
  final List<FeatureGroup> featureGroups;

  ProductVariant({
    required this.proID,
    required this.proUnit,
    required this.proPrice,
    required this.proStock,
    required this.isDefault,
    this.featureGroups = const [],
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
      featureGroups: (json['featureGroups'] as List<dynamic>?)
          ?.map((group) => FeatureGroup.fromJson(group))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proID': proID,
      'proUnit': proUnit,
      'proPrice': proPrice,
      'proStock': proStock,
      'isDefault': isDefault,
      'featureGroups': featureGroups.map((group) => group.toJson()).toList(),
    };
  }
}

class FeatureGroup {
  final int fgID;
  final String fgName;
  final String fgType;
  final bool isPrescription;
  final bool isFeatureRequired;
  final int requiredQty;
  final int order;
  final List<Feature> features;

  FeatureGroup({
    required this.fgID,
    required this.fgName,
    required this.fgType,
    required this.isPrescription,
    required this.isFeatureRequired,
    required this.requiredQty,
    required this.order,
    this.features = const [],
  });

  factory FeatureGroup.fromJson(Map<String, dynamic> json) {
    return FeatureGroup(
      fgID: json['fgID'] ?? 0,
      fgName: json['fgName'] ?? '',
      fgType: json['fgType'] ?? '',
      isPrescription: json['isPrescription'] ?? false,
      isFeatureRequired: json['isFeatureRequired'] ?? false,
      requiredQty: json['requiredQty'] ?? 0,
      order: json['order'] ?? 0,
      features: (json['features'] as List<dynamic>?)
          ?.map((feature) => Feature.fromJson(feature))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fgID': fgID,
      'fgName': fgName,
      'fgType': fgType,
      'isPrescription': isPrescription,
      'isFeatureRequired': isFeatureRequired,
      'requiredQty': requiredQty,
      'order': order,
      'features': features.map((feature) => feature.toJson()).toList(),
    };
  }
}

class Feature {
  final int featureID;
  final String featureName;
  final double featurePrice;
  final int featureOrder;
  final Prescription prescription;

  Feature({
    required this.featureID,
    required this.featureName,
    required this.featurePrice,
    required this.featureOrder,
    required this.prescription,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      featureID: json['featureID'] ?? 0,
      featureName: json['featureName'] ?? '',
      featurePrice: (json['featurePrice'] is int)
          ? (json['featurePrice'] as int).toDouble()
          : json['featurePrice'] ?? 0.0,
      featureOrder: json['featureOrder'] ?? 0,
      prescription: json['prescription'] != null 
          ? Prescription.fromJson(json['prescription'])
          : Prescription(pro: false, variant: false, qty: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'featureID': featureID,
      'featureName': featureName,
      'featurePrice': featurePrice,
      'featureOrder': featureOrder,
      'prescription': prescription.toJson(),
    };
  }
}

class Prescription {
  final bool pro;
  final bool variant;
  final int qty;

  Prescription({
    required this.pro,
    required this.variant,
    required this.qty,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      pro: json['pro'] ?? false,
      variant: json['variant'] ?? false,
      qty: json['qty'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pro': pro,
      'variant': variant,
      'qty': qty,
    };
  }
} 