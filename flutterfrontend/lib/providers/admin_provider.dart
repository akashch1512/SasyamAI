import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/api_constants.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  AdminStatsModel? _stats;
  AdminInsightsModel? _insights;
  List<SearchLogModel> _recentQueries = [];
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  AdminStatsModel? get stats => _stats;
  AdminInsightsModel? get insights => _insights;
  List<SearchLogModel> get recentQueries => _recentQueries;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllAdminData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchStats(),
        fetchInsights(),
        fetchRecentQueries(),
        fetchUsers(),
      ]);
    } catch (e) {
      _errorMessage = 'Error loading admin data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats() async {
    try {
      final response = await ApiService().get(ApiConstants.adminStatsEndpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _stats = AdminStatsModel.fromJson(data);
      }
    } catch (_) {}
  }

  Future<void> fetchInsights() async {
    try {
      final response = await ApiService().get(ApiConstants.adminInsightsEndpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _insights = AdminInsightsModel.fromJson(data);
      }
    } catch (_) {}
  }

  Future<void> fetchRecentQueries() async {
    try {
      final response = await ApiService().get(ApiConstants.adminQueriesEndpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _recentQueries = data.map((q) => SearchLogModel.fromJson(q as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }

  Future<void> fetchUsers() async {
    try {
      final response = await ApiService().get(ApiConstants.adminUsersEndpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> userList = data['users'] ?? [];
        _users = userList.map((u) => UserModel.fromJson(u as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
  }
}
