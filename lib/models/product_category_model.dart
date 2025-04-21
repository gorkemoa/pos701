import 'dart:convert';
import 'package:flutter/foundation.dart';

class CategoryResponse {
  final bool error;
  final bool success;
  final CategoryData? data;

  CategoryResponse({
    required this.error,
    required this.success,
    this.data,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: json['data'] != null ? CategoryData.fromJson(json['data']) : null,
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

class CategoryData {
  final List<Category> categories;

  CategoryData({
    required this.categories,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      categories: (json['categories'] as List<dynamic>?)
          ?.map((category) => Category.fromJson(category))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }
}

class Category {
  final int catID;
  final String catName;
  final String catColor;

  Category({
    required this.catID,
    required this.catName,
    required this.catColor,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      catID: json['catID'] ?? 0,
      catName: json['catName'] ?? '',
      catColor: json['catColor'] ?? '#FFFFFF',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'catID': catID,
      'catName': catName,
      'catColor': catColor,
    };
  }

  @override
  String toString() {
    return 'Category(catID: $catID, catName: $catName, catColor: $catColor)';
  }
} 