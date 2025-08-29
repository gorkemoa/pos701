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
      proPrice: _parseDouble(json['proPrice']),
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
  final bool isDefault;

  Feature({
    required this.featureID,
    required this.featureName,
    required this.featurePrice,
    required this.featureOrder,
    required this.prescription,
    this.isDefault = false,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      featureID: json['featureID'] ?? 0,
      featureName: json['featureName'] ?? '',
      featurePrice: _parseDouble(json['featurePrice']),
      featureOrder: json['featureOrder'] ?? 0,
      prescription: json['prescription'] != null 
          ? Prescription.fromJson(json['prescription'])
          : Prescription(pro: false, variant: false, qty: 0),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'featureID': featureID,
      'featureName': featureName,
      'featurePrice': featurePrice,
      'featureOrder': featureOrder,
      'prescription': prescription.toJson(),
      'isDefault': isDefault,
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

// Helper function to safely parse double values from various types
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    // Handle Turkish currency formatting like "+5,00 TL", "15,50 TL", etc.
    String cleanValue = value
        .replaceAll('TL', '')  // Remove "TL"
        .replaceAll('₺', '')   // Remove Turkish lira symbol
        .replaceAll('+', '')   // Remove plus sign
        .replaceAll('-', '-')  // Keep minus sign for negative values
        .replaceAll(' ', '')   // Remove spaces
        .replaceAll(',', '.')  // Convert Turkish decimal separator to dot
        .trim();
    
    // Handle empty string after cleaning
    if (cleanValue.isEmpty || cleanValue == '-') return 0.0;
    
    final parsed = double.tryParse(cleanValue);
    return parsed ?? 0.0;
  }
  return 0.0;
} 