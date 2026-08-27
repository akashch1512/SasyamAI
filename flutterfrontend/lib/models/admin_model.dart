class CategoryStatModel {
  final String category;
  final int count;
  final double percentage;

  CategoryStatModel({
    required this.category,
    required this.count,
    required this.percentage,
  });

  factory CategoryStatModel.fromJson(Map<String, dynamic> json) {
    return CategoryStatModel(
      category: json['category'] as String? ?? 'General',
      count: json['count'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CropTrendModel {
  final String cropName;
  final int inquiryCount;

  CropTrendModel({required this.cropName, required this.inquiryCount});

  factory CropTrendModel.fromJson(Map<String, dynamic> json) {
    return CropTrendModel(
      cropName: json['crop_name'] as String? ?? '',
      inquiryCount: json['inquiry_count'] as int? ?? 0,
    );
  }
}

class StateTrendModel {
  final String state;
  final int queryCount;

  StateTrendModel({required this.state, required this.queryCount});

  factory StateTrendModel.fromJson(Map<String, dynamic> json) {
    return StateTrendModel(
      state: json['state'] as String? ?? '',
      queryCount: json['query_count'] as int? ?? 0,
    );
  }
}

class AdminStatsModel {
  final int totalUsers;
  final int totalQueries;
  final int totalDiseaseScans;
  final int totalCropRecommendations;
  final List<CategoryStatModel> categoryBreakdown;
  final List<CropTrendModel> topCrops;
  final List<StateTrendModel> stateDistribution;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalQueries,
    required this.totalDiseaseScans,
    required this.totalCropRecommendations,
    required this.categoryBreakdown,
    required this.topCrops,
    required this.stateDistribution,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    var rawCats = json['category_breakdown'] as List<dynamic>? ?? [];
    var rawCrops = json['top_crops_searched'] as List<dynamic>? ?? [];
    var rawStates = json['state_distribution'] as List<dynamic>? ?? [];

    return AdminStatsModel(
      totalUsers: json['total_users'] as int? ?? 0,
      totalQueries: json['total_queries'] as int? ?? 0,
      totalDiseaseScans: json['total_disease_scans'] as int? ?? 0,
      totalCropRecommendations: json['total_crop_recommendations'] as int? ?? 0,
      categoryBreakdown: rawCats.map((c) => CategoryStatModel.fromJson(c as Map<String, dynamic>)).toList(),
      topCrops: rawCrops.map((c) => CropTrendModel.fromJson(c as Map<String, dynamic>)).toList(),
      stateDistribution: rawStates.map((s) => StateTrendModel.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class AdminInsightsModel {
  final DateTime generatedAt;
  final String summaryHeadline;
  final List<String> keyFindings;
  final List<String> emergingCropDemands;
  final List<String> prevalentCropDiseases;
  final List<String> farmerAdvisorySuggestions;

  AdminInsightsModel({
    required this.generatedAt,
    required this.summaryHeadline,
    required this.keyFindings,
    required this.emergingCropDemands,
    required this.prevalentCropDiseases,
    required this.farmerAdvisorySuggestions,
  });

  factory AdminInsightsModel.fromJson(Map<String, dynamic> json) {
    return AdminInsightsModel(
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      summaryHeadline: json['summary_headline'] as String? ?? 'Agricultural Trends Summary',
      keyFindings: (json['key_findings'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      emergingCropDemands: (json['emerging_crop_demands'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      prevalentCropDiseases: (json['prevalent_crop_diseases'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      farmerAdvisorySuggestions: (json['farmer_advisory_suggestions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class SearchLogModel {
  final int id;
  final int? userId;
  final String userName;
  final String queryText;
  final String category;
  final String? detectedCrop;
  final String? detectedDisease;
  final String? state;
  final DateTime createdAt;

  SearchLogModel({
    required this.id,
    this.userId,
    required this.userName,
    required this.queryText,
    required this.category,
    this.detectedCrop,
    this.detectedDisease,
    this.state,
    required this.createdAt,
  });

  factory SearchLogModel.fromJson(Map<String, dynamic> json) {
    return SearchLogModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String? ?? 'Farmer',
      queryText: json['query_text'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      detectedCrop: json['detected_crop'] as String?,
      detectedDisease: json['detected_disease'] as String?,
      state: json['state'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
