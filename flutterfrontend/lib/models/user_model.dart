import 'dart:convert';

class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String role;
  final String? state;
  final String? district;
  final double? latitude;
  final double? longitude;
  final String? soilType;
  final double? landSizeAcres;
  final String? irrigationSource;
  final String? primaryCrops;
  final String preferredLanguage;
  final bool isOnboarded;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    this.role = 'user',
    this.state,
    this.district,
    this.latitude,
    this.longitude,
    this.soilType,
    this.landSizeAcres,
    this.irrigationSource,
    this.primaryCrops,
    this.preferredLanguage = 'en',
    this.isOnboarded = false,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      role: json['role'] as String? ?? 'user',
      state: json['state'] as String?,
      district: json['district'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      soilType: json['soil_type'] as String?,
      landSizeAcres: (json['land_size_acres'] as num?)?.toDouble(),
      irrigationSource: json['irrigation_source'] as String?,
      primaryCrops: json['primary_crops'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      isOnboarded: json['is_onboarded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'role': role,
      'state': state,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'soil_type': soilType,
      'land_size_acres': landSizeAcres,
      'irrigation_source': irrigationSource,
      'primary_crops': primaryCrops,
      'preferred_language': preferredLanguage,
      'is_onboarded': isOnboarded,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  UserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    String? state,
    String? district,
    double? latitude,
    double? longitude,
    String? soilType,
    double? landSizeAcres,
    String? irrigationSource,
    String? primaryCrops,
    String? preferredLanguage,
    bool? isOnboarded,
    String? role,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      state: state ?? this.state,
      district: district ?? this.district,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      soilType: soilType ?? this.soilType,
      landSizeAcres: landSizeAcres ?? this.landSizeAcres,
      irrigationSource: irrigationSource ?? this.irrigationSource,
      primaryCrops: primaryCrops ?? this.primaryCrops,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }
}
