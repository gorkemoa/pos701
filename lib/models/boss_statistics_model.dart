class BossStatisticsModel {
  final String title;
  final String amount;

  BossStatisticsModel({
    required this.title,
    required this.amount,
  });

  factory BossStatisticsModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsModel(
      title: json['title'] ?? '',
      amount: json['amount'] ?? '0,00 TL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
    };
  }
}

class BossStatisticsResponse {
  final bool error;
  final bool success;
  final List<BossStatisticsModel> data;

  BossStatisticsResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => BossStatisticsModel.fromJson(item))
              .toList() ??
          [],
    );
  }
} 