import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:easy_ride/core/utils/logs.dart';
import 'package:easy_ride/core/values/constants.dart';
import 'package:easy_ride/core/services/preferences_service.dart';

class ApiService extends GetxService {
  final PreferencesService _prefsService = Get.find<PreferencesService>();

  // Base URLs
  final String _googleMapsBaseUrl = 'https://maps.googleapis.com/maps/api';

  // Headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Auth headers (for APIs that require authentication)
  Map<String, String> get _authHeaders => {
    ..._headers,
    'Authorization': 'Bearer ${Constants.googleMapsApiKey}',
  };

  Future<ApiService> init() async {
    DevLogs.info('ApiService initialized');
    return this;
  }

  // Generic GET request
  Future<dynamic> get(String url, {Map<String, String>? headers, bool requiresAuth = false}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: requiresAuth ? _authHeaders : headers ?? _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      DevLogs.error('GET request failed', exception: e);
      throw Exception('Network error: $e');
    }
  }

  // Generic POST request
  Future<dynamic> post(String url, {Map<String, dynamic>? body, Map<String, String>? headers, bool requiresAuth = false}) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: requiresAuth ? _authHeaders : headers ?? _headers,
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      DevLogs.error('POST request failed', exception: e);
      throw Exception('Network error: $e');
    }
  }

  // Generic PUT request
  Future<dynamic> put(String url, {Map<String, dynamic>? body, Map<String, String>? headers, bool requiresAuth = false}) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: requiresAuth ? _authHeaders : headers ?? _headers,
        body: body != null ? json.encode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      DevLogs.error('PUT request failed', exception: e);
      throw Exception('Network error: $e');
    }
  }

  // Generic DELETE request
  Future<dynamic> delete(String url, {Map<String, String>? headers, bool requiresAuth = false}) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: requiresAuth ? _authHeaders : headers ?? _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      DevLogs.error('DELETE request failed', exception: e);
      throw Exception('Network error: $e');
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    DevLogs.debug('API Response [${response.statusCode}]: ${response.request?.url}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Handle unauthorized (token expired, etc.)
      DevLogs.warning('Unauthorized API request: ${response.request?.url}');
      throw Exception('Unauthorized');
    } else {
      DevLogs.error(
        'API error [${response.statusCode}]: ${response.request?.url}',
        exception: response.body,
      );
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }

  // Google Places API - Place Search
  Future<List<dynamic>> searchPlaces(String query, {double? lat, double? lng, int radius = 50000}) async {
    final String url = '$_googleMapsBaseUrl/place/textsearch/json?query=$query&key=${Constants.googleMapsApiKey}';

    // Add location bias if provided
    final String locationParam = (lat != null && lng != null)
        ? '&location=$lat,$lng&radius=$radius'
        : '';

    final response = await get(url + locationParam);

    if (response['status'] == 'OK') {
      return response['results'];
    } else {
      DevLogs.error('Places API error: ${response['status']}');
      throw Exception('Places API error: ${response['status']}');
    }
  }

  // Google Places API - Place Details
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final String url = '$_googleMapsBaseUrl/place/details/json?place_id=$placeId&fields=name,formatted_address,geometry,place_id&key=${Constants.googleMapsApiKey}';

    final response = await get(url);

    if (response['status'] == 'OK') {
      return response['result'];
    } else {
      DevLogs.error('Place Details API error: ${response['status']}');
      throw Exception('Place Details API error: ${response['status']}');
    }
  }

  // Google Directions API
  Future<Map<String, dynamic>> getDirections(double originLat, double originLng, double destLat, double destLng) async {
    final String url = '$_googleMapsBaseUrl/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&mode=driving&key=${Constants.googleMapsApiKey}';

    final response = await get(url);

    if (response['status'] == 'OK') {
      return response['routes'][0];
    } else {
      DevLogs.error('Directions API error: ${response['status']}');
      throw Exception('Directions API error: ${response['status']}');
    }
  }

  // Google Geocoding API - Reverse Geocoding
  Future<Map<String, dynamic>> reverseGeocode(double lat, double lng) async {
    final String url = '$_googleMapsBaseUrl/geocode/json?latlng=$lat,$lng&key=${Constants.googleMapsApiKey}';

    final response = await get(url);

    if (response['status'] == 'OK') {
      return response['results'][0];
    } else {
      DevLogs.error('Geocoding API error: ${response['status']}');
      throw Exception('Geocoding API error: ${response['status']}');
    }
  }
}
