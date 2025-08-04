class BossStatisticsModel {
  final String statisticsKey;
  final String statisticsTitle;
  final String statisticsAmount;

  BossStatisticsModel({
    required this.statisticsKey,
    required this.statisticsTitle,
    required this.statisticsAmount,
  });

  factory BossStatisticsModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsModel(
      statisticsKey: json['statisticsKey'] ?? '',
      statisticsTitle: json['statisticsTitle'] ?? '',
      statisticsAmount: json['statisticsAmount'] ?? '0,00 TL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statisticsKey': statisticsKey,
      'statisticsTitle': statisticsTitle,
      'statisticsAmount': statisticsAmount,
    };
  }

  // Geriye uyumluluk için getter'lar
  String get title => statisticsTitle;
  String get amount => statisticsAmount;
}

class BossStatisticsResponse {
  final bool error;
  final bool success;
  final BossStatisticsData data;

  BossStatisticsResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: BossStatisticsData.fromJson(json['data'] ?? {}),
    );
  }
}

class BossStatisticsData {
  final List<BossStatisticsModel> statistics;

  BossStatisticsData({
    required this.statistics,
  });

  factory BossStatisticsData.fromJson(Map<String, dynamic> json) {
    return BossStatisticsData(
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class BossStatisticsDetailModel {
  final String title;
  final int count;
  final String amount;

  BossStatisticsDetailModel({
    required this.title,
    required this.count,
    required this.amount,
  });

  factory BossStatisticsDetailModel.fromJson(Map<String, dynamic> json) {
    return BossStatisticsDetailModel(
      title: json['title'] ?? '',
      count: json['count'] ?? 0,
      amount: json['amount'] ?? '0,00 TL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'count': count,
      'amount': amount,
    };
  }
}

class BossStatisticsDetailResponse {
  final bool error;
  final bool success;
  final BossStatisticsDetailData data;

  BossStatisticsDetailResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory BossStatisticsDetailResponse.fromJson(Map<String, dynamic> json) {
    return BossStatisticsDetailResponse(
      error: json['error'] ?? false,
      success: json['success'] ?? false,
      data: BossStatisticsDetailData.fromJson(json['data'] ?? {}),
    );
  }
}

class BossStatisticsDetailData {
  final List<BossStatisticsDetailModel> statistics;
  final int totalCount;
  final String totalAmount;

  BossStatisticsDetailData({
    required this.statistics,
    required this.totalCount,
    required this.totalAmount,
  });

  factory BossStatisticsDetailData.fromJson(Map<String, dynamic> json) {
    return BossStatisticsDetailData(
      statistics: (json['statistics'] as List<dynamic>?)
              ?.map((item) => BossStatisticsDetailModel.fromJson(item))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      totalAmount: json['totalAmount'] ?? '0,00 TL',
    );
  }
} 