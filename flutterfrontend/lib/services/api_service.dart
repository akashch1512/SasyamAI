import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = ApiConstants.defaultBaseUrl;
  String? _token;

  String get baseUrl => _baseUrl;
  String? get token => _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(ApiConstants.baseUrlKey) ?? ApiConstants.defaultBaseUrl;
    _token = prefs.getString(ApiConstants.tokenKey);
  }

  Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.baseUrlKey, newUrl);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(ApiConstants.tokenKey, token);
    } else {
      await prefs.remove(ApiConstants.tokenKey);
    }
  }

  Map<String, String> _headers({bool isJson = true}) {
    final map = <String, String>{};
    if (isJson) {
      map['Content-Type'] = 'application/json';
    }
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  Uri _uri(String endpoint) {
    var base = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    var path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$path');
  }

  Future<http.Response> get(String endpoint) async {
    final response = await http.get(_uri(endpoint), headers: _headers());
    return response;
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      _uri(endpoint),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return response;
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.put(
      _uri(endpoint),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(_uri(endpoint), headers: _headers());
    return response;
  }

  Future<http.Response> uploadMultipart(
    String endpoint, {
    required List<int> fileBytes,
    required String filename,
    String fieldName = 'file',
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', _uri(endpoint));
    request.headers.addAll(_headers(isJson: false));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}
