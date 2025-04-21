class ApiResponseModel<T> {
  final bool error;
  final bool success;
  final T? data;
  final String? errorCode;

  ApiResponseModel({
    required this.error,
    required this.success,
    this.data,
    this.errorCode,
  });

  factory ApiResponseModel.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return ApiResponseModel<T>(
      error: json['error'] as bool,
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data'] as Map<String, dynamic>) : null,
      errorCode: json['410'] as String?,
    );
  }
} 