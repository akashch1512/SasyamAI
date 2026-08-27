import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isOnboarded => _currentUser?.isOnboarded ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(ApiConstants.userKey);
      if (userJsonStr != null) {
        _currentUser = UserModel.fromJsonString(userJsonStr);
      }

      // Fetch fresh profile from backend if token exists
      if (ApiService().token != null) {
        await refreshProfile();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post(
        ApiConstants.loginEndpoint,
        body: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final userObj = UserModel.fromJson(data['user'] as Map<String, dynamic>);

        await ApiService().setToken(token);
        _currentUser = userObj;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.userKey, userObj.toJsonString());

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail']?.toString() ?? 'Login failed';
      }
    } catch (e) {
      _errorMessage = 'Unable to connect to SasyamAI server';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService().post(
        ApiConstants.registerEndpoint,
        body: {
          'email': email.trim(),
          'password': password,
          'full_name': fullName.trim(),
          'phone_number': phoneNumber?.trim(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final userObj = UserModel.fromJson(data['user'] as Map<String, dynamic>);

        await ApiService().setToken(token);
        _currentUser = userObj;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.userKey, userObj.toJsonString());

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail']?.toString() ?? 'Registration failed';
      }
    } catch (e) {
      _errorMessage = 'Unable to connect to SasyamAI server';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Prompt Google authentication or simulated token payload
      final googlePayload = {
        'email': 'farmer.demo@gmail.com',
        'full_name': 'Kisan Mitra',
        'profile_image_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      };

      final response = await ApiService().post(
        ApiConstants.googleAuthEndpoint,
        body: googlePayload,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['access_token'] as String;
        final userObj = UserModel.fromJson(data['user'] as Map<String, dynamic>);

        await ApiService().setToken(token);
        _currentUser = userObj;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.userKey, userObj.toJsonString());

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Google authentication failed';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> completeOnboarding({
    String? phoneNumber,
    String? state,
    String? district,
    double? latitude,
    double? longitude,
    String? soilType,
    double? landSizeAcres,
    String? irrigationSource,
    String? primaryCrops,
    String preferredLanguage = 'en',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payload = {
        'phone_number': phoneNumber,
        'state': state,
        'district': district,
        'latitude': latitude,
        'longitude': longitude,
        'soil_type': soilType,
        'land_size_acres': landSizeAcres,
        'irrigation_source': irrigationSource,
        'primary_crops': primaryCrops,
        'preferred_language': preferredLanguage,
      };

      final response = await ApiService().post(
        ApiConstants.onboardingEndpoint,
        body: payload,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.userKey, _currentUser!.toJsonString());

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error saving onboarding information';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService().put(
        ApiConstants.profileEndpoint,
        body: updates,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.userKey, _currentUser!.toJsonString());

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error updating profile';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> refreshProfile() async {
    try {
      final response = await ApiService().get(ApiConstants.meEndpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.userKey, _currentUser!.toJsonString());
        notifyListeners();
      } else if (response.statusCode == 401) {
        await logout();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    _currentUser = null;
    await ApiService().setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.userKey);
    notifyListeners();
  }
}
