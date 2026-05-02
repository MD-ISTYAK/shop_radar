import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';

/// Service for Google Places API searches (medical, metro, etc.)
class MapSearchService {
  static final MapSearchService _instance = MapSearchService._internal();
  factory MapSearchService() => _instance;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  MapSearchService._internal();

  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _apiKey = AppConstants.googleMapsApiKey;

  /// Search nearby places using Google Places Text Search API
  /// Used for: Hospital, Blood Bank, Labs, Metro
  Future<List<PlaceResult>> searchNearby({
    required String query,
    required double lat,
    required double lng,
    int radius = 5000,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/textsearch/json',
        queryParameters: {
          'query': query,
          'location': '$lat,$lng',
          'radius': radius,
          'key': _apiKey,
        },
      );

      if (response.data['status'] == 'OK') {
        final results = response.data['results'] as List;
        return results.map((r) => PlaceResult.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Find the nearest metro station
  Future<PlaceResult?> findNearestMetro(double lat, double lng) async {
    final results = await searchNearby(
      query: 'metro station',
      lat: lat,
      lng: lng,
      radius: 10000,
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Search hospitals nearby
  Future<List<PlaceResult>> findNearbyHospitals(double lat, double lng) =>
      searchNearby(query: 'hospital', lat: lat, lng: lng, radius: 5000);

  /// Search blood banks nearby
  Future<List<PlaceResult>> findNearbyBloodBanks(double lat, double lng) =>
      searchNearby(query: 'blood bank', lat: lat, lng: lng, radius: 10000);

  /// Search labs nearby
  Future<List<PlaceResult>> findNearbyLabs(double lat, double lng) =>
      searchNearby(query: 'pathology lab diagnostic center', lat: lat, lng: lng, radius: 5000);
}

/// Structured result from Google Places API
class PlaceResult {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double? rating;
  final bool isOpen;
  final String placeId;

  PlaceResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.isOpen = false,
    required this.placeId,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final geo = json['geometry']?['location'];
    return PlaceResult(
      name: json['name'] ?? '',
      address: json['formatted_address'] ?? json['vicinity'] ?? '',
      lat: (geo?['lat'] ?? 0).toDouble(),
      lng: (geo?['lng'] ?? 0).toDouble(),
      rating: json['rating']?.toDouble(),
      isOpen: json['opening_hours']?['open_now'] ?? false,
      placeId: json['place_id'] ?? '',
    );
  }
}
